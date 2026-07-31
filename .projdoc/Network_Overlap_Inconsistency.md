# 前后端 Overlap 判定不一致问题分析

> 本文汇总了在 PIE/DedicatedServer 环境下，客户端检测到交互实体重叠并发送 RPC，但服务端 `IsOverlappingActor` 返回 false 这一问题所涉及的完整技术链路。

---

## 一、问题现象

1. 客户端 `BP_PlayerInteractEntityComponent` 检测到玩家进入交互实体触发区域 → 发送 `RPC_Server_RequestInteract`
2. 服务端收到 RPC 后：
   - 查表 `m_enteredInteractEntities[entityInstanceID]` 未命中
   - `_ServerVerifyPlayerOverlapWithEntity` 中 `triggerComp:IsOverlappingActor(playerPawn)` 返回 false
3. 焦点实体：`BP_Interact_TeamBuff_Money`

## 二、涉及的系统

### 2.1 交互系统的原始 Overlap 登记流程

```
客户端和服务端各自独立检测：
  TriggerComponent.OnComponentBeginOverlap
    → BP_InteractEntityComponent:OnComponentBeginOverlap
      → BP_InteractEntityComponent:OnPlayerEnter(playerKey)
        → EventSystem:BroadcastGlobal(OnPlayerEnterInteractEntity)
          → BP_PlayerInteractEntityComponent:OnPlayerEnterInteractEntity
            → m_enteredInteractEntities[instanceID] = comp  （双方各自维护）
```

服务端和客户端各自通过 `OnComponentBeginOverlap` 事件独立登记 `m_enteredInteractEntities`，**不是通过 RPC 同步**。

### 2.2 服务端 OnComponentBeginOverlap 可能被静默丢弃

`BP_InteractEntityComponent.lua:169-172`：

```lua
function BP_InteractEntityComponent:OnComponentBeginOverlap(...)
    if self.m_instanceID <= 0 then
        return  -- 未分配唯一ID，直接返回，不处理事件
    end
```

如果实体因 SCS/ICH 陈旧 archetype 问题（详见 `.projdoc/SCS_ICH_BlueprintInheritance.md`）导致 `OnBeginPlayOnServer` 未正确执行、`m_instanceID` 未分配，所有服务端重叠事件都会被丢弃。

---

## 三、`IsOverlappingActor` 的本质缺陷

### 3.1 实现

`UPrimitiveComponent::IsOverlappingActor`（`PrimitiveComponent.cpp:2217-2232`）：

```cpp
bool UPrimitiveComponent::IsOverlappingActor(const AActor* Other) const
{
    for (int32 OverlapIdx=0; OverlapIdx<OverlappingComponents.Num(); ++OverlapIdx)
    {
        UPrimitiveComponent const* const PrimComp =
            OverlappingComponents[OverlapIdx].OverlapInfo.Component.Get();
        if (PrimComp && (PrimComp->GetOwner() == Other))
            return true;
    }
    return false;
}
```

它**不查询物理引擎**。它遍历 `OverlappingComponents` 缓存列表，这个列表由 `BeginOverlap` / `EndOverlap` 事件维护。

### 3.2 可能漏判的场景

| 场景 | 原因 |
|---|---|
| `m_instanceID <= 0` | `OnComponentBeginOverlap` 被静默丢弃，列表为空 |
| DS 帧率过低 | 两次物理 Tick 之间玩家快速通过 Trigger 边缘，`BeginOverlap` 未触发 |
| 客户端位置预测领先 | 客户端预测位置让重叠先发生，服务端权威位置尚未进入 |
| ICH 陈旧 archetype | Trigger 碰撞属性在子蓝图中过期 |

---

## 四、UE4.18 物理系统架构

### 4.1 双场景模型

```
┌── Sync Scene ──────────────────────────┐
│  模拟：Player/AI/必需物理体              │
│  查询：IsOverlappingActor 事件的来源      │
│        OverlapMulti/Sweep 的查询对象     │
│  时序：游戏线程同步等待完成               │
└────────────────────────────────────────┘

┌── Async Scene ─────────────────────────┐
│  模拟：布料/碎片/装饰性物理               │
│  时序：客户端延迟一帧，DS 不延迟          │
│  对 Overlap 事件无影响                   │
└────────────────────────────────────────┘
```

**Static Actor（含 Trigger 组件）同时在两个场景中存在**（`PhysScene.cpp:79-80`）。Async Scene 的帧延迟不影响 Trigger 的重叠检测。

### 4.2 DS 帧率硬上限

`GameEngine.cpp:1072-1077`：

```cpp
if (NetDriver && (NetDriver->GetNetMode() == NM_DedicatedServer || ...))
{
    MaxTickRate = FMath::Clamp(NetDriver->NetServerMaxTickRate, 1, 1000);
}
```

| 端 | 典型帧率 | 物理 Tick 频率 |
|---|---|---|
| 客户端 | 60+ FPS | 60+ Hz |
| DS | 30 FPS（`NetServerMaxTickRate` 默认值） | 30 Hz |

**DS 的物理 Tick 频率只有客户端的一半。** 玩家快速移动经过 Trigger 边缘时，客户端 60Hz 的采样可能捕获了重叠，而服务端 30Hz 的两个采样点之间刚好错过了重叠窗口。

```
客户端 60 Hz:  ████████░░████████░░████████░░████████
              ↑ overlap 检测到 → 发送 RPC

服务端 30 Hz:  ████████████████░░████████████████
              ↑ 采样点：未重叠        ↑ 采样点：已离开
```

### 4.3 帧延迟（Frame Lag）差异

`PhysScene.cpp:93-100`：

```cpp
FORCEINLINE static bool FrameLagAsync()
{
    if (IsRunningDedicatedServer())
        return false;   // DS：不延迟
    return true;        // 客户端：Async Scene 延迟一帧
}
```

客户端 Async Scene 落后 Sync Scene 一帧（为并行性能），但不影响 Overlap 检测（Overlap 走 Sync Scene）。

### 4.4 Tick 时序

`LevelTick.cpp:1408-1420`：

```
RunTickGroup(TG_PrePhysics)       ← Actor/Component BeginPlay、Tick 在这里
RunTickGroup(TG_StartPhysics)     
RunTickGroup(TG_DuringPhysics, false)  ← 物理模拟（不等待完成！）
TickGroup = TG_EndPhysics
RunTickGroup(TG_EndPhysics)       ← Overlap 事件在这里生成
RunTickGroup(TG_PostPhysics)
```

Overlap 事件在 `TG_EndPhysics` 阶段才生成。如果在 `TG_PrePhysics` 中访问 `OverlappingComponents`，拿到的是**上一帧**的缓存。

---

## 五、碰撞通道与查询类型的映射

### 5.1 ECollisionChannel vs EObjectTypeQuery

`EObjectTypeQuery` 是 `ECollisionChannel` 的一个**语义子集**，纯粹为蓝图编辑器 UX 服务：

```
ECollisionChannel (全部 30+ 通道)
├── ObjectType 子集 → EObjectTypeQuery    "物体类型"
│   ├── ObjectTypeQuery1  = ECC_WorldStatic
│   ├── ObjectTypeQuery2  = ECC_WorldDynamic  ← Trigger 的 ObjectType
│   ├── ObjectTypeQuery3  = ECC_Pawn
│   ├── ObjectTypeQuery4  = ECC_PhysicsBody
│   ├── ObjectTypeQuery5  = ECC_Vehicle
│   └── ObjectTypeQuery6  = ECC_Destructible
├── TraceType 子集    → ETraceTypeQuery   "射线检测类型"
└── 内部通道（不进 Query 枚举）
```

`BaseEngine.ini:1429` 定义 Trigger 预设：

```
+Profiles=(Name="Trigger", CollisionEnabled=QueryOnly,
           ObjectTypeName="WorldDynamic", ...)
```

Trigger 的 ObjectType = `WorldDynamic` → 对应 `EObjectTypeQuery.ObjectTypeQuery2`。

### 5.2 UGC Lua 中的枚举值

**`EObjectTypeQuery` 只有 `ObjectTypeQuery1`~`ObjectTypeQuery32`**，没有 `WorldDynamic` 等显示名。必须使用数字索引格式。

---

## 六、解决方案

### 6.1 实时物理查询替代事件缓存

将 `_ServerVerifyPlayerOverlapWithEntity` 从：

```lua
-- 旧：查事件缓存
triggerComp:IsOverlappingActor(playerPawn)
```

替换为：

```lua
-- 新：实时物理查询
local playerCapsule = playerPawn:GetRootComponent()
local OutActors = {}
local bOverlapped = UKismetSystemLibrary.ComponentOverlapActors(
    playerCapsule,
    playerCapsule:K2_GetComponentTransform(),
    { EObjectTypeQuery.ObjectTypeQuery2 },  -- WorldDynamic
    nil, {}, OutActors
)
-- 检查 entityComp:GetOwnerActor() 是否在 OutActors 中
```

### 6.2 可用的重叠查询 API

| API | 来源 | 查询方式 |
|---|---|---|
| `IsOverlappingActor` | `UPrimitiveComponent` | 事件缓存（不可靠） |
| `ComponentOverlapActors` | `UKismetSystemLibrary` | 实时组件物理查询 |
| `QueryOverlapActorsBySphereWithFinder` | `UGCSceneQueryUtility` | 实时球体物理查询 |
| `SphereOverlapActors` | `KismetSystemLibrary` | 实时球体物理查询 |

### 6.3 防御性措施

1. 增大 Trigger 组件体积（减少边缘错过概率）
2. 服务端 `OnPlayerEnterInteractEntity` 中也直接发起交互（针对不需要玩家确认的实体）
3. RPC 二次校验时使用实时物理查询而非事件缓存
4. 修改父蓝图后，手动编译所有子蓝图（`File → Compile All Blueprints`）

---

## 七、相关文档

| 文档 | 内容 |
|---|---|
| `.projdoc/SCS_ICH_BlueprintInheritance.md` | SCS/ICH 陈旧 archetype 问题 |
| `.projdoc/BTService_Lifecycle_And_Looping.md` | 行为树 Service 生命周期与根节点保护 |
| `.agent/rules/ugc-lua-coding.md` | UGC Lua 编码规则 |

## 八、相关源码

| 文件 | 关键内容 |
|---|---|
| `Engine/Source/Runtime/Engine/Private/Components/PrimitiveComponent.cpp:2217` | `IsOverlappingActor` 实现 |
| `Engine/Source/Runtime/Engine/Private/GameEngine.cpp:1072` | DS `NetServerMaxTickRate` 帧率上限 |
| `Engine/Source/Runtime/Engine/Private/LevelTick.cpp:1408` | Tick Group 时序 |
| `Engine/Source/Runtime/Engine/Private/PhysicsEngine/PhysScene.cpp:79` | `SceneType_AssumesLocked`（Sync/Async 分配） |
| `Engine/Source/Runtime/Engine/Private/PhysicsEngine/PhysScene.cpp:93` | `FrameLagAsync`（DS vs Client 差异） |
| `Engine/Source/Runtime/Engine/Private/PhysicsEngine/PhysLevel.cpp:64` | `SetupPhysicsTickFunctions` |
| `Engine/Config/BaseEngine.ini:1429` | `Trigger` 碰撞预设定义 |
| `Engine/Source/Runtime/Engine/Classes/Engine/EngineTypes.h:678` | `EObjectTypeQuery` 枚举定义 |
| `Engine/Source/Runtime/Engine/Private/Collision/CollisionProfile.cpp:466` | `ObjectTypeMapping` 运行时映射 |
