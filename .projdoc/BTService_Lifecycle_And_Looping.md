# 行为树 Service 节点生命周期与循环重启机制

> 本文总结了一个实际遭遇的问题：`BTService_Zombie_GetTarget` 在玩家死亡/濒死后停止 Tick，导致丧尸在玩家复活后无法重新找到目标。通过 UE 4.18 源码分析，完整还原了 Service 节点的激活/反激活机制以及根节点的特殊保护逻辑。

---

## 一、问题回顾

### 现象

1. 玩家死亡/濒死 → 黑板 `Target` 被清空
2. `BTService_Zombie_GetTarget` 的 `ReceiveTickAI` **每只丧尸只输出了一次日志**（"未找到目标玩家"），之后彻底停止
3. 即便玩家 10 秒后自救复活，Service 也不再执行，丧尸永久丢失目标

### 涉及的代码

- `BTService_Zombie_GetTarget:ReceiveTickAI` — 挂载在 `BT_Zombie_Melee_MainTree` 右分支的外层 Sequence 上
- `BTCondition_Zombie_ShouldFindEntry` — 左分支装饰器，检查 `bIsSpawnedOutside`
- `BTCondition_Zombie_ShouldTrackingPlayer` — 右分支装饰器，检查 `not bIsSpawnedOutside`

### 行为树结构

```
? Root Selector [根]
│
├─? Selector [左]
│   │ ◆ BTCondition_Zombie_ShouldFindEntry  (bIsSpawnedOutside)
│   └─→ Sequence
│       └─⚡ 寻找入口 (BTTask_RunBehaviorDynamic)
│
└─→ Sequence [右-外层]                          ← BTService_Zombie_GetTarget 原本挂载位置
    │ ◆ BTCondition_Zombie_ShouldTrackingPlayer (not bIsSpawnedOutside)
    ├─⟳ BTService_Zombie_GetTarget
    └─→ Sequence [右-内层]
        ├─⚡ [Generic]指定速度移动到 (BTTask_Generic_MoveToEx)
        └─→ Sequence
            └─⚡ 攻击流程 (BTTask_RunBehaviorDynamic)
```

### 修复方案

将 `BTService_Zombie_GetTarget` 从右分支外层 Sequence 移到**根 Selector** 上，问题解决。

---

## 二、为什么 Service 会停止 Tick

### 2.1 根因链

```
玩家死亡 → Target = nil
  → BTService_Zombie_GetTarget 清空黑板 Target
  → 右-内层 Sequence 的装饰器/任务因 Target 为空被阻止执行
  → 整棵树找不到可执行的 Task（NextTask == NULL）
  → OnTreeFinished() 被调用
  → UnregisterAuxNodesUpTo(0, 0) 清理所有非根 ActiveAuxNodes
  → 右分支 Sequence 上的 BTService_Zombie_GetTarget 被移除
  → 下一帧搜索同样结果 → Service 不再被激活
  → 玩家复活后，树继续在"无任务可执行"状态下循环，Service 永不恢复
```

### 2.2 关键误解纠正

| 直觉理解 | 源码实际行为 |
|---|---|
| "Service 挂在哪个节点上，行为走到就会 Tick" | 不精确：Service 是**当执行流进入所在 Composite 时激活**，**离开时移除** |
| "分支所有子节点被阻止 = 分支失败 = Selector 换分支" | 被阻止的子节点返回 `LastResult = Failed`，但整条搜索往下走到无 Task 可执行为止 |
| "树无任务可执行 = 树失败 = 下次重试" | `OnTreeFinished()` 触发，**非根 Service 被清空**，然后请求重启 |

---

## 三、UE 4.18 源码分析

### 3.1 Service 的激活：`OnNodeActivation`

`BTCompositeNode.cpp:149-166`

```cpp
void UBTCompositeNode::OnNodeActivation(FBehaviorTreeSearchData& SearchData) const
{
    OnNodeRestart(SearchData);

    for (int32 ServiceIndex = 0; ServiceIndex < Services.Num(); ServiceIndex++)
    {
        // add services when execution flow enters this composite
        SearchData.AddUniqueUpdate(
            FBehaviorTreeSearchUpdate(
                Services[ServiceIndex],
                SearchData.OwnerComp.GetActiveInstanceIdx(),
                EBTNodeUpdateMode::Add
            )
        );
        Services[ServiceIndex]->NotifyParentActivation(SearchData);
    }
}
```

**执行流 ENTER 某个 Composite → 该 Composite 上的所有 Service 被加入 PendingUpdates (Add) → Apply 后进入 ActiveAuxNodes → 开始 Tick。**

### 3.2 Service 的反激活：`OnNodeDeactivation`

`BTCompositeNode.cpp:168-178`

```cpp
void UBTCompositeNode::OnNodeDeactivation(
    FBehaviorTreeSearchData& SearchData, EBTNodeResult::Type& NodeResult) const
{
    // remove all services if execution flow leaves this composite
    for (int32 ServiceIndex = 0; ServiceIndex < Services.Num(); ServiceIndex++)
    {
        SearchData.AddUniqueUpdate(
            FBehaviorTreeSearchUpdate(
                Services[ServiceIndex],
                SearchData.OwnerComp.GetActiveInstanceIdx(),
                EBTNodeUpdateMode::Remove
            )
        );
    }
}
```

**执行流 LEAVE 某个 Composite → 该 Composite 上的所有 Service 被加入 PendingUpdates (Remove) → Apply 后从 ActiveAuxNodes 移除 → 停止 Tick。**

### 3.3 搜索流程：`ProcessExecutionRequest`

`BehaviorTreeComponent.cpp:1200-1255`

```cpp
// start looking for next task
while (TestNode && NextTask == NULL)
{
    const int32 ChildBranchIdx = TestNode->FindChildToExecute(SearchData, NodeResult);

    if (ChildBranchIdx == BTSpecialChild::ReturnToParent)
    {
        // 装饰器阻止 → 返回父节点
        TestNode = TestNode->GetParentNode();
        if (TestNode == NULL)
        {
            // 到达实例根 → deactivate root
            ChildNode->OnNodeDeactivation(SearchData, NodeResult);
        }
    }
    else if (TestNode->Children.IsValidIndex(ChildBranchIdx))
    {
        // 找到可执行子节点
        NextTask = TestNode->Children[ChildBranchIdx].ChildTask;
        TestNode = TestNode->Children[ChildBranchIdx].ChildComposite;
    }
}
```

搜索沿树向下：每进入一个子 Composite → `OnNodeActivation` → Services 激活；被装饰器阻止返回父节点 → `OnNodeDeactivation` → Services 移除。

### 3.4 装饰器阻止子节点时的行为

`BTCompositeNode.cpp:26-59` — `FindChildToExecute`

```cpp
while (Children.IsValidIndex(ChildIdx) && !SearchData.bPostponeSearch)
{
    if (DoDecoratorsAllowExecution(...))
    {
        // 通过 → 激活此子节点
        OnChildActivation(SearchData, ChildIdx);
        RetIdx = ChildIdx;
        break;
    }
    else
    {
        LastResult = EBTNodeResult::Failed;  // ← 阻断 = Failed
        NotifyDecoratorsOnFailedActivation(...);
    }
    ChildIdx = GetNextChild(SearchData, ChildIdx, LastResult);
}
```

装饰器阻止 → `LastResult = Failed` → 调用 `GetNextChild`。

- **Sequence** 收到 Failed → `ReturnToParent`（不再继续下一个子节点）
- **Selector** 收到 Failed → 切换到下一个子节点

### 3.5 树完成时的处理：`OnTreeFinished`

`BehaviorTreeComponent.cpp:435-458`

```cpp
void UBehaviorTreeComponent::OnTreeFinished()
{
    UE_VLOG(GetOwner(), LogBehaviorTree, Verbose, TEXT("Ran out of nodes to check, %s tree."),
        bLoopExecution ? TEXT("looping") : TEXT("stopping"));

    ActiveInstanceIdx = 0;

    if (bLoopExecution && InstanceStack.Num())
    {
        FBehaviorTreeInstance& TopInstance = InstanceStack[0];
        TopInstance.ActiveNode = NULL;
        TopInstance.ActiveNodeType = EBTActiveNode::Composite;

        // 移除所有 active aux nodes
        // root level services are being handled on applying search data
        UnregisterAuxNodesUpTo(FBTNodeIndex(0, 0));

        RequestExecution(TopInstance.RootNode, 0, TopInstance.RootNode, 0,
                         EBTNodeResult::InProgress);
    }
    else
    {
        // 非循环模式：停止树
        StopTree(...);
    }
}
```

`UnregisterAuxNodesUpTo(FBTNodeIndex(0, 0))` 遍历所有 `ActiveAuxNodes`，将 ExecutionIndex > 0 的全部加入 PendingUpdates (Remove)。**根层 Service（ExecutionIndex = 0）逻辑上也会被加入 Remove 列表。**

### 3.6 核心保护：Apply 阶段根 Service 跳过 Remove

`BehaviorTreeComponent.cpp:950-960`

```cpp
// special case: service node at root of top most subtree
// - don't remove/re-add them when tree is in looping mode
if (bLoopExecution
    && UpdateInfo.AuxNode->GetParentNode() == InstanceStack[0].RootNode
    && UpdateInfo.AuxNode->IsA(UBTService::StaticClass()))
{
    if (UpdateInfo.Mode == EBTNodeUpdateMode::Remove
        || InstanceStack[0].ActiveAuxNodes.Contains(UpdateInfo.AuxNode))
    {
        UE_VLOG(GetOwner(), LogBehaviorTree, Verbose,
                TEXT("> skip [looped execution]"));
        continue;  // ← 跳过 Remove，也跳过重复 Add
    }
}
```

**根节点上的 Service 在循环重启时，Remove 和重复 Add 都被跳过。** 它一旦进入 `ActiveAuxNodes`，就永久留在里面直到树真正停止。

### 3.7 Tick 循环

`BehaviorTreeComponent.cpp:1069-1078`

```cpp
// tick active auxiliary nodes
for (int32 AuxIndex = 0; AuxIndex < InstanceInfo.ActiveAuxNodes.Num(); AuxIndex++)
{
    const UBTAuxiliaryNode* AuxNode = InstanceInfo.ActiveAuxNodes[AuxIndex];
    uint8* NodeMemory = AuxNode->GetNodeMemory<uint8>(InstanceInfo);
    AuxNode->WrappedTickNode(*this, NodeMemory, DeltaTime);
}
```

**每帧遍历 `ActiveAuxNodes`，在列表中的就 Tick。** 根节点 Service 因上述保护机制始终在列表里；非根 Service 随执行流进出而增减。

### 3.8 搜索完成 → 执行 Task：`ExecuteTask`

当搜索循环找到 `NextTask` 后，通过 `ProcessPendingExecution` → `ExecuteTask` 执行。

`BehaviorTreeComponent.cpp:1478-1519`

```cpp
void UBehaviorTreeComponent::ExecuteTask(UBTTaskNode* TaskNode)
{
    FBehaviorTreeInstance& ActiveInstance = InstanceStack[ActiveInstanceIdx];

    // ═══ 激活挂在 Task 节点上的 Service ═══
    //
    // 关键注释（line 1484）：
    // task service activation is not part of search update
    // (although deactivation is, through DeactivateUpTo),
    // start them before execution
    //
    // 翻译：Task 上的 Service 激活不在搜索更新流程中
    //      （但反激活在，通过 DeactivateUpTo 统一处理）
    //      所以在执行 Task 之前手动激活
    for (int32 ServiceIndex = 0; ServiceIndex < TaskNode->Services.Num(); ServiceIndex++)
    {
        UBTService* ServiceNode = TaskNode->Services[ServiceIndex];
        uint8* NodeMemory = ServiceNode->GetNodeMemory<uint8>(ActiveInstance);

        // 直接加入 ActiveAuxNodes，不走 PendingUpdates 队列
        ActiveInstance.ActiveAuxNodes.Add(ServiceNode);

        // 立即触发 BecomeRelevant 回调
        ServiceNode->WrappedOnBecomeRelevant(*this, NodeMemory);
    }

    // 设置为当前活动节点
    ActiveInstance.ActiveNode = TaskNode;
    ActiveInstance.ActiveNodeType = EBTActiveNode::ActiveTask;

    // ═══ 实际执行 Task ═══
    uint8* NodeMemory = TaskNode->GetNodeMemory<uint8>(ActiveInstance);
    EBTNodeResult::Type TaskResult = TaskNode->WrappedExecuteTask(*this, NodeMemory);

    // 如果不是 Latent Task（异步任务），立即调用 OnTaskFinished
    if (GetActiveNode() == TaskNode)
    {
        OnTaskFinished(TaskNode, TaskResult);
    }
}
```

关键细节：

- **Task Service 激活不走 `PendingUpdates`**：直接 `ActiveAuxNodes.Add()` + `WrappedOnBecomeRelevant()`，绕过了 Composite Service 的 `AddUniqueUpdate(Add)` → `ApplySearchData` 路径
- **反激活是统一的**：Task Service 的反激活和 Composite Service 一样，通过 `DeactivateUpTo` 在搜索阶段统一处理
- **同步 vs 异步**：`WrappedExecuteTask` 返回 `InProgress` 时 Task 挂起（Latent Task），其他返回值立即调用 `OnTaskFinished`

### 3.9 Composite Service vs Task Service 激活路径对比

| 维度 | Composite Service | Task Service |
|---|---|---|
| **激活时机** | 搜索过程中执行流进入该 Composite | `ExecuteTask` 中，Task 执行前 |
| **激活方式** | `OnNodeActivation` → `AddUniqueUpdate(Add)` → `ApplySearchData` 批量处理 | **直接** `ActiveAuxNodes.Add` + `WrappedOnBecomeRelevant` |
| **反激活方式** | `OnNodeDeactivation` → `AddUniqueUpdate(Remove)` 或 `DeactivateUpTo` | `DeactivateUpTo` 统一处理 |
| **是否走 PendingUpdates** | ✅ 是（与其他 Aux Node 的 Add/Remove 一起排队 Apply） | ❌ 否（Add 直接写入，Remove 走 PendingUpdates） |
| **设计理由** | 搜索阶段还没到 Task，Composite 的激活/反激活自然融入搜索流程 | Task 只有在搜索完成后才确定执行，此时搜索更新已过，所以手动激活 |

**为什么 Task Service 的激活要绕开搜索更新？**

从 `ProcessExecutionRequest` 看完整流程：

```
搜索阶段（Search）:
  1. DeactivateUpTo          → 统一反激活 Composite + Task Services
  2. 搜索循环                  → Composite Services 的 Add/Remove 在这里排队
  3. ApplySearchData          → 批量处理 PendingUpdates

执行阶段（Execution）:
  4. ExecuteTask              → Task Service 在这里手动激活（搜索已结束）
```

搜索阶段只负责「从当前位置走到新 Task」，它不知道最终会选中哪个 Task。等到搜索结束、`NextTask` 确定后，才在 `ExecuteTask` 中激活 Task 上的 Service。注释说的很清楚：激活不在搜索更新里，反激活在。

---

## 四、根节点特殊处理的理由

### 源码注释只说

> "special case: service node at root of top most subtree — don't remove/re-add them when tree is in looping mode"

### 推理

1. **语义**：根 Service 的意图是"整个行为树生命周期内一直运行"，循环重启是树内部的调度行为，不应触发 Service 的重新初始化。

2. **避免无意义开销**：没有保护时，根 Service 每帧走 `BecomeRelevant → Tick → CeaseRelevant` 循环。每次 Cease/Become 可能重置内部状态、清空缓存数据。

3. **保证行为一致性**：如果每帧重新激活，有些 Service 的 `ReceiveActivationAI` 和 `ReceiveDeactivationAI` 会被反复调用，可能导致计时器重置、累积计数器归零等副作用。

---

## 五、架构全景图

### 5.1 搜索流程与 Service 激活/反激活

```
┌──────────────────────────────────────────────────────────────────┐
│                      ProcessExecutionRequest                     │
│                                                                  │
│  1. DeactivateUpTo(ExecuteNode)                                 │
│     └→ 从 ActiveNode 向上逐层 OnNodeDeactivation                  │
│        └→ Services 被加入 PendingUpdates (Remove)                │
│                                                                  │
│  2. RootNode.OnNodeActivation (如 ActiveNode == NULL)            │
│     └→ 根 Services 被加入 PendingUpdates (Add)                   │
│                                                                  │
│  3. Search Loop: while (TestNode && NextTask == NULL)            │
│     ┌─────────────────────────────────────────────────┐          │
│     │  FindChildToExecute(TestNode)                   │          │
│     │    GetNextChild → 选下一个子节点                  │          │
│     │    DoDecoratorsAllowExecution?                   │          │
│     │      ✅ YES → OnChildActivation → 进入子树       │          │
│     │      ❌ NO  → LastResult=Failed → 继续/返回      │          │
│     │                                                 │          │
│     │  ChildBranchIdx == ReturnToParent?               │          │
│     │    → OnNodeDeactivation → Services Remove         │          │
│     │    → TestNode = GetParentNode()                  │          │
│     │                                                 │          │
│     │  ChildComposite != NULL?                         │          │
│     │    → OnNodeActivation → Services Add             │          │
│     │    → TestNode = ChildComposite (继续深入)         │          │
│     └─────────────────────────────────────────────────┘          │
│                                                                  │
│  4. NextTask == NULL?  →  OnTreeFinished()                       │
│     ├→ UnregisterAuxNodesUpTo(0,0)  (非根 Services Remove)       │
│     └→ RequestExecution(RootNode, InProgress)  (请求重启)         │
│                                                                  │
│  5. ApplySearchData  ← 搜索阶段结束                               │
│     └→ 处理 PendingUpdates:                                      │
│        ├→ 普通 Service: Remove → 从 ActiveAuxNodes 移除          │
│        │               Add    → 加入 ActiveAuxNodes              │
│        └→ 根节点 Service (bLoopExecution):                       │
│             Remove → continue (跳过)                              │
│             Add (已存在) → continue (跳过)                        │
│                                                                  │
│  ═══════════════════ 搜索/执行 分界线 ═══════════════════         │
│                                                                  │
│  6. NextTask != NULL?  →  ExecuteTask(NextTask)                  │
│     ┌─────────────────────────────────────────────────┐          │
│     │  ⚡ Task Service 激活（不走 PendingUpdates）:     │          │
│     │     ActiveAuxNodes.Add(ServiceNode)               │          │
│     │     ServiceNode.WrappedOnBecomeRelevant(...)      │          │
│     │                                                  │          │
│     │  ⚡ Task 执行:                                    │          │
│     │     TaskNode.WrappedExecuteTask(...)              │          │
│     │     → 同步返回 → OnTaskFinished                   │          │
│     │     → InProgress → Task 挂起（Latent Task）        │          │
│     └─────────────────────────────────────────────────┘          │
└──────────────────────────────────────────────────────────────────┘
```

### 5.2 Tick 循环

```
                    UBehaviorTreeComponent::TickComponent
                              │
                    ┌─────────▼──────────┐
                    │ bRequestedFlowUpdate?│
                    │   YES → ProcessExec │
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │ InstanceStack == 0 │
                    │ or !bIsRunning?    │──→ return
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │ 遍历 InstanceStack  │
                    │  遍历 ActiveAuxNodes│
                    │    WrappedTickNode()│  ← Services 在这里 Tick
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │  Tick Active Task  │
                    └────────────────────┘
```

### 5.3 Service 生命周期状态机

```
         ┌─────────────────────────────────────────────────┐
         │              Composite Service                   │
         │                                                 │
         │   OnNodeActivation              OnNodeDeactivation
         │  ┌──────┐    ────────────→    ┌──────┐         │
         │  │Inactive│                    │Active│         │
         │  │      │    ←────────────    │      │         │
         │  └──────┘  OnNodeDeactivation └──┬───┘         │
         │       ↑            or            │              │
         │       │   OnTreeFinished(非根)    │              │
         │       └──────────────────────────┘              │
         │                  每帧 TickComponent             │
         │                  WrappedTickNode()              │
         └─────────────────────────────────────────────────┘

         ┌─────────────────────────────────────────────────┐
         │                Task Service                      │
         │                                                 │
         │   ExecuteTask (直接 Add)    DeactivateUpTo       │
         │  ┌──────┐    ────────────→    ┌──────┐         │
         │  │Inactive│                    │Active│         │
         │  │      │    ←────────────    │      │         │
         │  └──────┘    DeactivateUpTo   └──┬───┘         │
         │       ↑                           │              │
         │       │                           │              │
         │       └───────────────────────────┘              │
         │                  每帧 TickComponent             │
         │                  WrappedTickNode()              │
         └─────────────────────────────────────────────────┘

关键区别：
  Composite Service: Add 走 PendingUpdates → ApplySearchData
  Task Service:      Add 直接写 ActiveAuxNodes（绕过 PendingUpdates）
  两者 Remove 统一:  都通过 DeactivateUpTo → PendingUpdates → ApplySearchData
```

**根节点 Service（Composite 挂根）的特殊路径**：进入 Active 后，`OnTreeFinished` 的 Remove 和下一次 `OnNodeActivation` 的 Add 均被跳过，状态不回到 Inactive，永久保持在 Active。

---

## 六、工程实践建议

### 6.1 Service 挂载位置选择

| 挂载位置 | 激活条件 | 适用场景 |
|---|---|---|
| **根节点** | 行为树运行期间一直激活 | 全程需要的核心逻辑（目标选择、状态监控） |
| **深层 Composite** | 该分支被进入时才激活 | 分支特定辅助逻辑（攻击辅助、巡逻辅助） |

### 6.2 常见陷阱

1. **依赖 Task 失败来重新触发 Service**：如果所有 Task 被装饰器阻止 → `OnTreeFinished` → 非根 Service 被清空 → Service 不再恢复。应当将需要持续运行的 Service 放在根节点。

2. **装饰器阻止 ≠ 分支失败**：被阻止的节点 `LastResult = Failed`，但这不等于能找到替代路径。如果整棵树无 Task 可执行，就进入 `OnTreeFinished` 循环。

3. **`bLoopExecution` 的依赖**：根 Service 的保护仅在 `bLoopExecution == true` 时生效。非循环模式下 `OnTreeFinished` 直接停止整棵树。

---

## 七、相关源码索引

| 文件 | 行号 | 关键内容 |
|---|---|---|
| `BTCompositeNode.cpp` | 26-59 | `FindChildToExecute`：装饰器检查 + 子节点选择 |
| `BTCompositeNode.cpp` | 149-166 | `OnNodeActivation`：Services 激活（Add to PendingUpdates） |
| `BTCompositeNode.cpp` | 168-178 | `OnNodeDeactivation`：Services 移除（Remove from PendingUpdates） |
| `BTComposite_Selector.cpp` | 12-29 | Selector 子节点切换：Failed 则下一个 |
| `BTComposite_Sequence.cpp` | 12-29 | Sequence 子节点切换：Succeeded 则下一个，Failed 则返回 |
| `BehaviorTreeComponent.cpp` | 435-458 | `OnTreeFinished`：循环重启 vs 停止 |
| `BehaviorTreeComponent.cpp` | 950-960 | 根节点 Service 循环保护（skip Remove/Add） |
| `BehaviorTreeComponent.cpp` | 1069-1112 | `TickComponent`：ActiveAuxNodes 遍历 Tick |
| `BehaviorTreeComponent.cpp` | 1200-1255 | `ProcessExecutionRequest`：搜索循环主逻辑 |
| `BehaviorTreeComponent.cpp` | 1312-1333 | `ProcessExecutionRequest`：搜索完成 → PendingExecution.NextTask + ProcessPendingExecution |
| `BehaviorTreeComponent.cpp` | 1369-1428 | `DeactivateUpTo`：沿树向上反激活 |
| `BehaviorTreeComponent.cpp` | 1478-1519 | `ExecuteTask`：Task Service 直接激活 + 执行 Task |
| `BehaviorTreeTypes.cpp` | 173-203 | `DeactivateNodes`：移除 Pending Add、标记 ParallelTasks 和 ActiveAuxNodes 为 Remove |
