# BP_Interact_LevelObstacle 动态导航网格实现指南

> 本文档说明如何为关卡障碍物（门、箱子、路障等）实现"障碍存在时阻断寻路、障碍消除后恢复寻路"的动态导航网格功能。

---

## 一、原理概述

UE 4.18 的导航网格（NavMesh）默认在编辑器中静态烘焙。绿洲启元魔改版提供了 `UGCNavigationSystem` 接口，支持在运行时增量更新 NavMesh 数据。

核心流程：

```
障碍物存在（阻断寻路）
  → 玩家交互/消灭怪物 → 障碍物消除
    → 标记该区域为"需要更新"（AddDynamicNavAffect）
      → 异步增量重建该区域 NavMesh（AsyncIncrementalBuild）
        → 导航网格恢复通行，怪物可寻路通过
```

---

## 二、编辑器前置配置

### 2.1 添加 Nav Mesh Bounds Volume

场景中必须有 Nav Mesh Bounds Volume，且覆盖范围包含所有需要动态更新的障碍物区域。

### 2.2 配置动态更新参数

1. 在世界大纲中找到 `UAERecastNavMesh-Mannequin` 对象
2. 勾选 `UGCDyn Nav Data`（允许动态更新导航数据）
3. 展开 Generation → 显示高级项：
   - `Allowed Dynamic Nav Affectors`：**勾选**（必选，否则后续属性不生效）
   - `Dynamic Affector Update Mode`：选 `Manual Trigger`（手动触发，更可控）
   - `Dynamic Affector Update Interval`：手动模式下不生效，可忽略
4. `Region Partitioning`：建议选 `Monotone`（单音调），运行时增量更新更快

> 注意：编辑器静态烘焙时建议用 `Watershed`（转折/分水岭）保证精度，动态更新时切 `Monotone` 加速。

---

## 三、蓝图组件配置

### 3.1 BP_InteractableBase 组件结构

```
BP_InteractableBase (AActor)
  ├── DefaultSceneRoot    (USceneComponent)
  ├── Mesh0               (UStaticMeshComponent)     ← 障碍物模型
  ├── MainCollision       (UBoxComponent)            ← 物理碰撞
  ├── InteractTrigger     (UCustomBoxCollisionComponent) ← 交互检测区域
  └── InteractEntityComponent (BP_InteractEntityComponent_C) ← 交互实体组件
```

### 3.2 添加 UNavModifierComponent

在蓝图编辑器中给 BP_Interact_LevelObstacle 添加 `NavModifierComponent`：

1. 打开 BP_Interact_LevelObstacle 蓝图
2. 组件面板 → Add Component → 搜索 `NavModifierComponent` → 添加
3. 设置默认属性：
   - `Area Class` = `NavArea_Null`（默认不可通行，即障碍物存在时阻断寻路）
   - 碰撞体的范围将自动作为 NavMesh 影响区域

### 3.3 UNavArea 类型说明

| 类名 | 含义 | 适用场景 |
|------|------|---------|
| `NavArea_Null` | **完全不可通行** | 障碍物存在时（默认值） |
| `NavArea_Default` | 正常可通行 | 障碍物消除后 |
| `NavArea_Obstacle` | 高代价通行（尽量绕行） | 可通行但不推荐的区域 |

---

## 四、Lua 代码实现

### 4.1 当前实现分析

当前 `BP_Interact_LevelObstacle.lua` 的 `OnInteractionCompleted` 已经包含动态更新逻辑：

```lua
-- Script/Blueprint/Prefabs/LevelEntities/Interactable/BP_Interact_LevelObstacle.lua

function BP_Interact_LevelObstacle:OnInteractionCompleted(playkey, instanceID, errCode)
    if not UGCGameSystem.IsServer() then return end
    if instanceID ~= self.InteractEntityComponent:GetInstanceID()
       or errCode ~= EInteractEntityErrCode.None then
        return
    end
    -- 标记障碍物周围 1000x1000x1000 区域为"需要更新"
    local loc = self:K2_GetActorLocation()
    local min = UGCMathUtility.MakeVector(loc.X - 500, loc.Y - 500, loc.Z - 500)
    local max = UGCMathUtility.MakeVector(loc.X + 500, loc.Y + 500, loc.Z + 500)
    local Fbox = UGCMathUtility.MakeBox(min, max)
    UGCNavigationSystem.AddDynamicNavAffect(self, "Mannequin", Fbox)
    UGCNavigationSystem.AsyncIncrementalBuild(self, "Mannequin")
end
```

这段代码在交互完成时触发增量更新，但**缺少 NavModifierComponent 的切换**——需要配合蓝图中的 NavModifierComponent 使用才能生效。

### 4.2 完整实现方案

#### 方案 A：NavModifierComponent + 动态增量更新（推荐）

**原理**：障碍物存在时 NavModifierComponent 设为 NavArea_Null（不可通行），消除时切换为 NavArea_Default（可通行），同时触发 NavMesh 增量重建。

```lua
---@class BP_Interact_LevelObstacle_C:BP_InteractableBase_C
---@field DynamicObstacleAvoidance UDynamicObstacleAvoidanceComponent
---@field InteractBehaviour_SetVisible InteractBehaviour_SetVisible_C
---@field InteractBehaviour_DeductPropertyValue InteractBehaviour_DeductPropertyValue_C
---@field NavModifierComp UNavModifierComponent  -- 需要在蓝图中添加此组件
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_LevelObstacle_C
local BP_Interact_LevelObstacle = BPExtent({}, "Script.Blueprint.InteractEntity.BP_InteractableBase")

-- 预加载 NavArea UClass（BeginPlay 时一次性加载）
local NavArea_Null = nil
local NavArea_Default = nil

--[[--]]
function BP_Interact_LevelObstacle:ReceiveBeginPlay()
    BP_Interact_LevelObstacle.SuperClass.ReceiveBeginPlay(self)
    GameplaySystem.EventSystem:Listen(
        GameplayEvents.Global.OnPlayerInteractCompleted, self, self.OnInteractionCompleted)

    -- 同步加载 NavArea UClass
    NavArea_Null = UGCObjectUtility.LoadClass("/Script/Engine.NavArea_Null")
    NavArea_Default = UGCObjectUtility.LoadClass("/Script/Engine.NavArea_Default")

    -- 获取 NavModifierComponent（蓝图中需添加）
    self.NavModifierComp = self:FindComponentByClass("NavModifierComponent")

    -- 初始化：障碍物存在 → 不可通行
    if self.NavModifierComp and NavArea_Null then
        self.NavModifierComp:SetAreaClass(NavArea_Null)
    end
end

--[[--]]
function BP_Interact_LevelObstacle:ReceiveEndPlay()
    BP_Interact_LevelObstacle.SuperClass.ReceiveEndPlay(self)
    GameplaySystem.EventSystem:UnlistenAll(self)
end

---@private  服务端：交互完成后更新导航网格
function BP_Interact_LevelObstacle:OnInteractionCompleted(playkey, instanceID, errCode)
    if not UGCGameSystem.IsServer() then return end
    if instanceID ~= self.InteractEntityComponent:GetInstanceID()
       or errCode ~= EInteractEntityErrCode.None then
        return
    end

    -- 1. 切换 NavModifierComponent 为可通行
    if self.NavModifierComp and NavArea_Default then
        self.NavModifierComp:SetAreaClass(NavArea_Default)
    end

    -- 2. 标记该区域为"需要增量更新"
    local loc = self:K2_GetActorLocation()
    local min = UGCMathUtility.MakeVector(loc.X - 500, loc.Y - 500, loc.Z - 500)
    local max = UGCMathUtility.MakeVector(loc.X + 500, loc.Y + 500, loc.Z + 500)
    local Fbox = UGCMathUtility.MakeBox(min, max)
    UGCNavigationSystem.AddDynamicNavAffect(self, "Mannequin", Fbox)

    -- 3. 触发异步增量重建
    UGCNavigationSystem.AsyncIncrementalBuild(self, "Mannequin")

    GameplayUtils.Print("[NavObstacle] 障碍物已消除，NavMesh 增量更新已触发",
        self.InteractEntityComponent:GetInstanceID())
end

return BP_Interact_LevelObstacle
```

#### 方案 B：仅 SetActorEnableCollision + 全局重建（简单但开销大）

如果不使用 NavModifierComponent，只依赖碰撞体的启用/禁用来影响 NavMesh：

```lua
function BP_Interact_LevelObstacle:OnInteractionCompleted(playkey, instanceID, errCode)
    if not UGCGameSystem.IsServer() then return end
    if instanceID ~= self.InteractEntityComponent:GetInstanceID()
       or errCode ~= EInteractEntityErrCode.None then
        return
    end

    -- 禁用碰撞（InteractBehaviour_SetVisible 已经做了这一步）
    -- 但需要全局重建才能让 NavMesh 感知碰撞变化
    UGCNavigationSystem.AsyncBuildNavmesh(self, "Mannequin")
end
```

> ⚠️ 全局重建（AsyncBuildNavmesh）会重建整个地图的 NavMesh，性能开销大，不推荐。

---

## 五、SetAreaClass 函数说明

### 签名

```cpp
void UNavModifierComponent::SetAreaClass(TSubclassOf<UNavArea> NewAreaClass);
```

### 源码逻辑

```cpp
void UNavModifierComponent::SetAreaClass(TSubclassOf<UNavArea> NewAreaClass)
{
    if (AreaClass != NewAreaClass)
    {
        AreaClass = NewAreaClass;
        RefreshNavigationModifiers();  // 通知导航系统重新计算该组件的影响区域
    }
}
```

### 关键点

1. **SetAreaClass 本身不触发 NavMesh 重建** — 它只修改了组件的 AreaClass 并通知导航系统"这个组件变了"。实际的 NavMesh 数据重建需要额外调用：
   - `AddDynamicNavAffect` + `AsyncIncrementalBuild`（增量更新，推荐）
   - `AsyncBuildNavmesh`（全局重建，开销大）

2. **影响区域由 Owner Actor 的碰撞体决定** — NavModifierComponent 自动使用 Actor 上所有 PrimitiveComponent 的碰撞形状作为影响范围。如果 Actor 没有碰撞体，则使用 `FailsafeExtent`（默认 100x100x100）。

3. **仅影响 NavMesh 中对应 Tile 的数据** — 增量更新按 100m x 100m Tile 粒度重建。

---

## 六、增量更新 API 参考

| API | 说明 | 范围 |
|-----|------|------|
| `UGCNavigationSystem.AddDynamicNavAffect(WorldContext, AgentName, FBox)` | 标记某个 Box 区域为"需要更新" | 服务器 |
| `UGCNavigationSystem.AsyncIncrementalBuild(WorldContext, AgentName)` | 异步增量重建标记区域的 NavMesh | 服务器 |
| `UGCNavigationSystem.AsyncBuildNavmesh(WorldContext, AgentName)` | 全局异步重建整个 NavMesh | 服务器 |
| `UGCNavigationSystem.BuildNavmesh(WorldContext, AgentName)` | 同步全量重建（阻塞，慎用） | 服务器 |
| `UGCNavigationSystem.IsNavigationBeingBuilt(WorldContext)` | 查询 NavMesh 是否正在构建 | 服务器 |
| `UGCNavigationSystem.GetNavigationGenerationFinishedDelegate(WorldContext)` | 获取构建完成委托 | 服务器 |

- `AgentName` 一般传 `"Mannequin"`
- 所有 API 仅服务器端生效

---

## 七、完整流程示意

```
游戏启动
  │
  ├─ 编辑器已烘焙 NavMesh（静态数据，障碍物区域已标记为不可通行）
  │
  ├─ BP_Interact_LevelObstacle:ReceiveBeginPlay()
  │    ├─ 加载 NavArea_Null / NavArea_Default UClass
  │    ├─ 获取 NavModifierComponent
  │    └─ SetAreaClass(NavArea_Null)  ← 确保障碍物存在时不可通行
  │
  ├─ 玩家与障碍物交互（如开门、打碎箱子）
  │    └─ InteractEntitySystem 执行 Behaviour 链
  │         └─ InteractBehaviour_SetVisible: Execute()
  │              ├─ SetActorEnableCollision(false)  ← 禁用物理碰撞
  │              └─ SetActorHiddenInGame(true)      ← 隐藏模型
  │
  ├─ OnPlayerInteractCompleted 事件触发
  │    └─ BP_Interact_LevelObstacle:OnInteractionCompleted()
  │         ├─ SetAreaClass(NavArea_Default)  ← 切换为可通行
  │         ├─ AddDynamicNavAffect(FBox)      ← 标记区域
  │         └─ AsyncIncrementalBuild()        ← 触发增量重建
  │
  └─ NavMesh 增量更新完成
       └─ 该区域怪物可正常寻路通过
```

---

## 八、注意事项

1. **NavMesh Bounds Volume 必须覆盖动态更新区域** — 标记的 FBox 范围必须在 NavMesh Bounds Volume 内，否则无法生成数据。

2. **增量更新按 Tile（100m x 100m）粒度** — 标记区域落在哪个 Tile 就更新哪个 Tile，不是精确到 FBox 边界。

3. **标记缓存会被清除** — 成功增量更新后，之前 AddDynamicNavAffect 标记的缓存区域会被移除。如果需要再次更新（如障碍物重新出现），需要重新标记。

4. **SetAreaClass 是幂等的** — 如果新旧 AreaClass 相同，不会调用 RefreshNavigationModifiers。

5. **蓝图继承坑（SCS/ICH）** — 修改 BP_Interact_LevelObstacle 的碰撞/导航设置后，子蓝图（SingleDoor/DoubleDoor）如果未被打开过，可能只经历自动字节码编译，导致 OnRep 回调失效。**修复**：手动打开子蓝图并重新编译。详见 `.projdoc/SCS_ICH_BlueprintInheritance.md`。

6. **InteractBehaviour_LinkUnlockObstacle 联动** — 如果一个交互实体通过 LinkUnlockObstacle 联动解锁多个障碍物，每个障碍物的 OnInteractionCompleted 会独立触发各自的 NavMesh 更新。不需要额外处理。

7. **性能建议**：
   - 使用 Manual Trigger 模式，只在必要时触发更新
   - FBox 范围尽量精确（只覆盖障碍物周围），不要用过大的范围
   - 大量障碍物同时消除时，可合并到同一个 FBox 一次更新
