# Overlap检测前后端不一致问题分析

> 项目: UGC01_Zombie  
> 引擎: UE 4.18 (ShadowTrackerExtra)  
> 日期: 2026-07-25  
> 相关蓝图: BP_PlayerInteractEntityComponent, BP_InteractEntityComponent, BP_Interact_TeamBuff

---

## 1. 问题描述

### 1.1 现象

`BP_Interact_TeamBuff` 是一个**无需玩家确认**（`bNeedPlayerConfirm=false`）的可交互实体。当玩家进入其触发区域时：

- **客户端**：正确检测到 overlap，触发 `OnComponentBeginOverlap`，发送 `RPC_Server_RequestInteract`
- **服务端**：收到 RPC 后，`triggerComp:IsOverlappingActor(playerPawn)` 返回 **false**，交互失败（`FailNotOverlapped`）

### 1.2 复现路径

```
客户端检测overlap → 立即发送RPC → 服务端收到RPC
→ m_enteredInteractEntities中无该实体 → 调用IsOverlappingActor
→ 返回false → 交互失败(FailNotOverlapped)
```

### 1.3 影响范围

目前仅 `BP_Interact_TeamBuff` 受影响（`bNeedPlayerConfirm=false` 的交互实体）。需要玩家确认的交互实体（`bNeedPlayerConfirm=true`）不受影响。

---

## 2. 关键代码链路

### 2.1 客户端 overlap 触发

```
BP_InteractEntityComponent::OnComponentBeginOverlap (line 171-225)
  → 检查: OtherActor是玩家? 玩家存活? 实体可交互?
  → OnPlayerEnter (line 228-240)
    → 广播 GameplayEvents.Global.OnPlayerEnterInteractEntity 事件
```

### 2.2 客户端处理自动交互

```lua
-- BP_PlayerInteractEntityComponent:OnPlayerEnterInteractEntity (line 60-90)
if isServer then
    -- 服务端: 直接加入列表
    self.m_enteredInteractEntities[interactEntityInstanceID] = interactEntityComp
else
    if not interactEntityComp.bNeedPlayerConfirm then
        -- ★ 关键: bNeedPlayerConfirm=false 时，不加入客户端列表，直接发RPC
        self:ClientSendInteractMessage(interactEntityInstanceID)
    else
        -- bNeedPlayerConfirm=true: 加入客户端列表，显示UI等玩家确认
        self.m_enteredInteractEntities[interactEntityInstanceID] = interactEntityComp
    end
end
```

### 2.3 服务端校验

```lua
-- BP_PlayerInteractEntityComponent:RPC_Server_RequestInteract (line 138-176)
if not self.m_enteredInteractEntities[entityInstanceID] then
    -- 不在列表 → 尝试重校验
    if not self:_ServerVerifyPlayerOverlapWithEntity(playerKey, entityInstanceID) then
        -- ★ 返回FailNotOverlapped
        return
    end
end

-- _ServerVerifyPlayerOverlapWithEntity (line 182-205)
local triggerComp = entityComp:GetInteractTriggerComponent()
local bOverlapping = triggerComp:IsOverlappingActor(playerPawn)  -- ★ 返回false
return bOverlapping
```

---

## 3. 根因分析：IsOverlappingActor 的本质

### 3.1 IsOverlappingActor 查询的是缓存数组

```cpp
// PrimitiveComponent.cpp line 2217-2232
bool UPrimitiveComponent::IsOverlappingActor(const AActor* Other) const
{
    if (Other)
    {
        for (int32 OverlapIdx=0; OverlapIdx<OverlappingComponents.Num(); ++OverlapIdx)
        {
            UPrimitiveComponent const* const PrimComp = 
                OverlappingComponents[OverlapIdx].OverlapInfo.Component.Get();
            if ( PrimComp && (PrimComp->GetOwner() == Other) )
            {
                return true;
            }
        }
    }
    return false;
}
```

**结论：IsOverlappingActor 遍历 `OverlappingComponents` 数组，这是一个缓存列表，不是实时物理查询。**

### 3.2 OverlappingComponents 如何填充

```cpp
// PrimitiveComponent.cpp line 2696-2773
void UPrimitiveComponent::UpdateOverlaps(...)
{
    if (bGenerateOverlapEvents && IsQueryCollisionEnabled())
    {
        // ★ 执行 PhysX 场景查询获取当前重叠
        TArray<FOverlapResult> Overlaps;
        ComponentOverlapMulti(Overlaps, MyWorld, GetComponentLocation(), 
                              GetComponentQuat(), GetCollisionObjectType(), Params);
        
        // 将查询结果加入 NewOverlappingComponents
        for (int32 ResultIdx=0; ResultIdx<Overlaps.Num(); ResultIdx++)
        {
            NewOverlappingComponents.Add(FOverlapInfo(HitComp, Result.ItemIndex));
        }
    }
    // 比较新旧列表，触发 Begin/End Overlap 事件
}
```

### 3.3 UpdateOverlaps 的调用时机

```cpp
// SceneComponent.cpp line 740-753
// 只在组件位置变化时调用
if (bTransformChanged || CurrentScopedUpdate->bHasMoved)
{
    UpdateOverlaps(&CurrentScopedUpdate->GetPendingOverlaps(), true, EndOverlapsPtr);
}
```

**结论：Overlap 列表只在组件位置变化时更新。如果服务端的物理 Tick 还没执行（角色位置还没更新到触发器区域内），OverlappingComponents 就是空的。**

---

## 4. UE 4.18 物理场景架构

### 4.1 三种物理场景

| 场景类型 | 用途 | 包含的Actor |
|----------|------|-------------|
| PST_Sync | 同步场景 | 所有Static/Kinematic + 部分Dynamic |
| PST_Async | 异步场景 | 所有Static/Kinematic + 部分Dynamic |
| PST_Cloth | 布料场景 | 布料模拟 |

```cpp
// PhysScene.cpp line 76-84
EPhysicsSceneType FPhysScene::SceneType_AssumesLocked(const FBodyInstance* BodyInstance) const
{
    // ★ 注释: static actors are in both scenes
    return HasAsyncScene() && BodyInstance->bUseAsyncScene ? PST_Async : PST_Sync;
}
```

### 4.2 Actor 分配规则

```
Actor类型                    │ Sync场景 │ Async场景 │ 说明
─────────────────────────────┼─────────┼──────────┼──────────────
Static (墙壁/地面/触发器)     │    ✓    │    ✓     │ 两个场景都有
Kinematic                    │    ✓    │    ✓     │ 两个场景都有
Dynamic (bUseAsync=false)    │    ✓    │    ✗     │ 只在Sync
Dynamic (bUseAsync=true)     │    ✗    │    ✓     │ 只在Async
```

**BP_Interact_TeamBuff 的 InteractTrigger 是 Static/Kinematic 组件，在两个场景中都存在。**

### 4.3 Sync vs Async 的区别

**两个场景都执行真正的 PhysX 模拟**：

```cpp
// PhysScene.cpp line 1088-1090
PScene->lockWrite();
PScene->simulate(AveragedFrameTime[SceneType], Task, ...);  // 两个场景都调用
PScene->unlockWrite();
```

区分在于：
- **Sync 场景**：TG_StartPhysics 启动，同一帧 EndFrame 内 fetch 结果
- **Async 场景**：TG_EndPhysics 启动，结果延迟一帧 fetch（FrameLagAsync=true 时）

### 4.4 Overlap 查询同时查两个场景

```cpp
// PhysXCollision.cpp line 1300-1357
// 1. 先查 Sync 场景
SceneLocks.LockRead(World, SyncScene, PST_Sync);
SyncScene->overlap(PGeom, PGeomPose, POverlapBuffer, PQueryFilterData, &PQueryCallback);

// 2. 如果要求查 Async 场景，再查 Async
if (Params.bTraceAsyncScene && PhysScene->HasAsyncScene())
{
    PxScene* AsyncScene = PhysScene->GetPhysXScene(PST_Async);
    SceneLocks.LockRead(World, AsyncScene, PST_Async);
    AsyncScene->overlap(PGeom, PGeomPose, POverlapBuffer, PQueryFilterData, &PQueryCallback);
}
```

---

## 5. 物理 Tick 时序与帧组

### 5.1 Tick 函数注册与依赖

```cpp
// PhysLevel.cpp line 85-110

StartPhysicsTickFunction.TickGroup = TG_StartPhysics;     // ①

EndPhysicsTickFunction.TickGroup = TG_EndPhysics;         // ②
EndPhysicsTickFunction.AddPrerequisite(StartPhysicsTickFunction);  // ② 依赖 ①

StartAsyncTickFunction.TickGroup = TG_EndPhysics;         // ③
StartAsyncTickFunction.AddPrerequisite(EndPhysicsTickFunction);    // ③ 依赖 ②
```

**依赖链：① → ② → ③**

### 5.2 单帧执行顺序

```
┌─────────────────────────────────────────────────────────────┐
│ Frame N                                                      │
├─────────────────────────────────────────────────────────────┤
│ TG_PrePhysics                                                │
│   (Actor tick等预物理逻辑)                                    │
├─────────────────────────────────────────────────────────────┤
│ TG_StartPhysics                                              │
│   ① StartPhysicsSim()                                        │
│      → PhysScene::StartFrame()                               │
│        → TickPhysScene(PST_Sync)  ← 启动同步PhysX模拟        │
│          (非阻塞，PhysX工作线程异步执行)                       │
├─────────────────────────────────────────────────────────────┤
│ TG_DuringPhysics                                             │
│   (Actor tick，游戏逻辑)                                      │
├─────────────────────────────────────────────────────────────┤
│ TG_EndPhysics                                                │
│   ② EndPhysicsTickFunction → FinishPhysicsSim()              │
│      → PhysScene::EndFrame()                                 │
│        → WaitPhysScenes()  ← 等待同步模拟完成                 │
│        → SyncComponentsToBodies(PST_Sync)  ← 同步结果写回组件 │
│        → DispatchPhysNotifications()  ← 分发碰撞通知         │
│                                                             │
│   ③ StartAsyncTickFunction → StartAsyncSim()                 │
│      → PhysScene::StartAsync()                               │
│        → TickPhysScene(PST_Async) ← 启动异步PhysX模拟        │
├─────────────────────────────────────────────────────────────┤
│ TG_PostPhysics                                               │
│   (后物理逻辑)                                                │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 物理模拟时间步长限制

```cpp
// PhysicsSettings.h line 212-213
float MaxPhysicsDeltaTime;  // 默认 1/30 = 0.0333s

// PhysScene.cpp line 1026
float UseDelta = FMath::Min(
    UseSyncTime(SceneType) ? SyncDeltaSeconds : DeltaSeconds, 
    MaxPhysicsDeltaTime
);
```

**物理模拟最大时间步长为 1/30 秒（30Hz）。**

### 5.4 服务端 Tick 频率限制

```ini
# BaseEngine.ini
NetServerMaxTickRate=30    # 服务端最大Tick频率30Hz
```

```cpp
// GameEngine.cpp line 1074-1077
if (NetDriver && (NetDriver->GetNetMode() == NM_DedicatedServer || ...))
{
    MaxTickRate = FMath::Clamp(NetDriver->NetServerMaxTickRate, 1, 1000);
}
```

---

## 6. FrameLagAsync 机制

### 6.1 行为差异

```cpp
// PhysScene.cpp line 93-100
FORCEINLINE static bool FrameLagAsync()
{
    if (IsRunningDedicatedServer())
    {
        return false;  // DS: 异步场景不延迟
    }
    return true;       // 客户端: 异步场景延迟一帧
}
```

### 6.2 跨帧流程

**客户端 (FrameLagAsync=true)：**

```
Frame N:
  ① 启动 Sync 模拟
  ② EndFrame: 等待Sync完成, fetch Sync结果, 分发通知
  ③ StartAsync: 启动 Async 模拟, 结果存入 FrameLaggedCompletion[N]

Frame N+1:
  ① StartFrame: Sync模拟的完成任务依赖 FrameLaggedCompletion[N]
  ② EndFrame: fetch Frame N的 Async 结果
  ③ StartAsync: 启动新的 Async 模拟
```

**DS (FrameLagAsync=false)：**

```
Frame N:
  ① StartFrame: 同时启动 Sync 和 Async 模拟
  ② EndFrame: fetch 两个场景的结果
```

### 6.3 延迟一帧的目的

```cpp
// PhysScene.cpp line 1551
// If the async scene is lagged we start it here to make sure any cloth 
// in the async scene is using the results of the previous simulation.
```

- 保证异步场景中的布料等模拟使用上一帧的正确结果
- 避免同步/异步场景操作同一对象时的数据竞争
- 保证物理模拟的因果稳定性

---

## 7. 时序竞争图解

### 7.1 bNeedPlayerConfirm=true（正常）

```
客户端:
  T=0ms:   检测overlap → 加入客户端列表 → 显示UI
  T=1~Tn:  玩家站在触发区域内...
  Tm:      玩家按下交互键 → 发送RPC

服务端:
  T=0ms:   物理Tick → 检测overlap → OnComponentBeginOverlap
           → 加入 m_enteredInteractEntities
  Tm:      收到RPC → 实体已在列表中 → 通过 ✓
```

### 7.2 bNeedPlayerConfirm=false（异常）

```
客户端:
  T=0ms:   检测overlap → 立即发送RPC (不等待)

服务端:
  T=0ms:   收到RPC → 不在列表中
  T=0ms:   调用 IsOverlappingActor → OverlappingComponents 为空 → false
  T=33ms:  物理Tick → 角色移动重放 → 触发overlap (但RPC已处理完毕)
```

### 7.3 核心问题

**IsOverlappingActor 查询的是缓存数组，而该数组只在物理 Tick 中通过 UpdateOverlaps 更新。**

服务端的 RPC 处理发生在游戏 Tick 中，可能在物理 Tick 之前执行。此时：
- `m_enteredInteractEntities` 无记录（服务端 OnComponentBeginOverlap 还没触发）
- `OverlappingComponents` 为空（服务端物理还没检测到 overlap）

---

## 8. 网络延迟参考

### 8.1 Loopback 延迟

```
localhost (127.0.0.1) 通信延迟:
  - TCP loopback:  10-50 μs (微秒)
  - UDP loopback:  5-30 μs
  - 内核态拷贝:    数据不经过网卡，直接在内核内存中拷贝
```

### 8.2 UE4 实际延迟

即使 loopback 延迟只有 30μs，UE4 的帧驱动架构仍导致：

| 阶段 | 耗时 |
|------|------|
| 数据包在 loopback 传输 | ~30 μs |
| 等待下一帧 TickDispatch | 0-16 ms (取决于帧率) |
| RPC 反序列化+执行 | ~0.1 ms |
| **总计** | **0.5-16 ms** |

---

## 9. 实时碰撞查询替代方案

### 9.1 缓存查询 vs 实时查询

| 函数 | 类型 | 说明 |
|------|------|------|
| `IsOverlappingActor()` | 缓存 | 查 OverlappingComponents 数组 |
| `IsOverlappingComponent()` | 缓存 | 查 OverlappingComponents 数组 |
| `GetOverlappingActors()` | 缓存 | 返回缓存列表 |
| `ComponentOverlapMulti()` | **实时** | 执行 PhysX 场景查询 |
| `ComponentOverlapComponent()` | **实时** | 测试两个组件是否重叠 |
| `World::OverlapMultiByChannel()` | **实时** | 用碰撞形状按通道查询 |
| `World::OverlapAnyTestByChannel()` | **实时** | 快速 bool 测试 |

### 9.2 ComponentOverlapMulti 签名

```cpp
// PrimitiveComponent.h line 791 (UE 4.18 & UE 5.7 通用)
bool ComponentOverlapMulti(
    TArray<FOverlapResult>& OutOverlaps,
    const UWorld* InWorld,
    const FVector& Pos,          // 查询位置
    const FQuat& Rot,            // 查询旋转
    ECollisionChannel TestChannel,
    const FComponentQueryParams& Params = ...,
    const FCollisionObjectQueryParams& ObjectQueryParams = ...
) const;
```

### 9.3 Lua 中使用实时查询

```lua
-- 替换 IsOverlappingActor 的实时查询
local overlaps = {}
triggerComp:ComponentOverlapMulti(
    overlaps,
    self.m_owner:GetWorld(),
    triggerComp:GetComponentLocation(),
    triggerComp:GetComponentQuat(),
    triggerComp:GetCollisionObjectType()
)

-- 检查overlaps中是否有playerPawn的组件
for _, overlap in ipairs(overlaps) do
    if overlap.Component and overlap.Component:GetOwner() == playerPawn then
        return true
    end
end
return false
```

**注意：ComponentOverlapMulti 查询的是 PhysX 场景的当前状态。如果服务端的物理 Tick 还没执行，实时查询同样会返回空。**

---

## 10. EObjectTypeQuery 枚举映射

### 10.1 枚举定义

```cpp
// EngineTypes.h line 679-715
enum EObjectTypeQuery
{
    ObjectTypeQuery1 UMETA(Hidden),   // 0
    ObjectTypeQuery2 UMETA(Hidden),   // 1
    ObjectTypeQuery3 UMETA(Hidden),   // 2
    // ... 共32个值
    ObjectTypeQuery32 UMETA(Hidden),  // 31
    ObjectTypeQuery_MAX UMETA(Hidden)
};
```

### 10.2 默认映射表

```
EObjectTypeQuery         →  ECollisionChannel
──────────────────────────────────────────────
ObjectTypeQuery1    (0)  →  ECC_WorldStatic      (0)
ObjectTypeQuery2    (1)  →  ECC_WorldDynamic     (1)
ObjectTypeQuery3    (2)  →  ECC_Pawn             (2)
ObjectTypeQuery4    (3)  →  ECC_PhysicsBody      (5)  ← 跳过Visibility(3)和Camera(4)
ObjectTypeQuery5    (4)  →  ECC_Vehicle          (6)
ObjectTypeQuery6    (5)  →  ECC_Destructible     (7)
ObjectTypeQuery7    (6)  →  ECC_GameTraceChannel1 (18)
...依次类推...
ObjectTypeQuery32   (31) →  ECC_GameTraceChannel18 (35)
```

**索引不连续：Visibility(3) 和 Camera(4) 被归入 TraceType，不参与 ObjectType 映射。**

---

## 11. 解决方案建议

### 11.1 方案1: 服务端延迟重试

在 RPC_Server_RequestInteract 中，当 IsOverlappingActor 失败时，延迟一帧再校验：

```lua
function BP_PlayerInteractEntityComponent:RPC_Server_RequestInteract(playerKey, entityInstanceID)
    if not self.m_enteredInteractEntities[entityInstanceID] then
        if not self:_ServerVerifyPlayerOverlapWithEntity(playerKey, entityInstanceID) then
            -- 延迟一帧重试
            UGCGameSystem.SetTimer(function()
                if not self.m_enteredInteractEntities[entityInstanceID] then
                    if not self:_ServerVerifyPlayerOverlapWithEntity(playerKey, entityInstanceID) then
                        self:ResponseToClient(playerKey, entityInstanceID, 
                            EInteractEntityErrCode.FailNotOverlapped, "玩家未发生与交互实体发生碰撞！")
                        return
                    end
                    local entityComp = GameplaySystem.InteractEntitySystem:GetInteractComponentByInstanceID(entityInstanceID)
                    self.m_enteredInteractEntities[entityInstanceID] = entityComp
                end
                -- 继续执行交互逻辑...
            end, 0.1)
            return
        end
        local entityComp = GameplaySystem.InteractEntitySystem:GetInteractComponentByInstanceID(entityInstanceID)
        self.m_enteredInteractEntities[entityInstanceID] = entityComp
    end
    -- 继续正常交互流程...
end
```

### 11.2 方案2: 客户端携带 overlap 时间戳

客户端发送 RPC 时携带检测到 overlap 的时间戳，服务端根据时间戳判断是否在合理窗口内。

### 11.3 方案3: 服务端信任客户端的 overlap 事件

对于 bNeedPlayerConfirm=false 的实体，服务端直接信任客户端的 overlap 检测，跳过 IsOverlappingActor 校验。安全性降低但最简单。

### 11.4 推荐

**方案1（延迟重试）** 或 **方案2（时间戳）** 是最合理的方案。方案1 实现简单且不降低安全性；方案2 最精确但实现稍复杂。

---

## 12. 参考源码路径

| 文件 | 位置 | 内容 |
|------|------|------|
| PrimitiveComponent.cpp | Runtime/Engine/Private/Components/ | IsOverlappingActor, UpdateOverlaps, ComponentOverlapMulti |
| PhysScene.cpp | Runtime/Engine/Private/PhysicsEngine/ | 物理场景管理, TickPhysScene, EndFrame |
| PhysLevel.cpp | Runtime/Engine/Private/PhysicsEngine/ | Tick函数注册, SetupPhysicsTickFunctions |
| PhysicsSettings.h | Runtime/Engine/Classes/PhysicsEngine/ | MaxPhysicsDeltaTime, Substepping配置 |
| PhysXCollision.cpp | Runtime/Engine/Private/Collision/ | GeomOverlapMultiImp_PhysX |
| CollisionProfile.cpp | Runtime/Engine/Private/Collision/ | ObjectTypeQuery映射 |
| EngineTypes.h | Runtime/Engine/Classes/Engine/ | ECollisionChannel, EObjectTypeQuery定义 |
| GameEngine.cpp | Runtime/Engine/Private/ | NetServerMaxTickRate |
| ActorReplication.cpp | Runtime/Engine/Private/ | OnRep_ReplicatedMovement |
