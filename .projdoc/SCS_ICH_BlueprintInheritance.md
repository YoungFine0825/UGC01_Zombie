# SCS / ICH 与蓝图组件继承机制

> 本文总结了一个实际遭遇的蓝图继承 bug —— 修改父蓝图后子蓝图的组件网络复制失效 —— 并深入分析了 SCS（Simple Construction Script）和 ICH（InheritableComponentHandler）在此问题中扮演的角色。

---

## 一、问题回顾

### 现象

修改了 `BP_Interact_LevelObstacle` 和 `BP_InteractableBase` 两个父蓝图中几个 PrimitiveComponent 的**碰撞设置**和**导航设置**后：

| 子蓝图 | `OnRep_m_instanceID` 是否触发 | 原因 |
|---|---|---|
| `BP_Interact_DoubleDoor` | ✅ 正常 | 最近被手动修改过（新增 Door01/Door02 等组件），触发过完整重编译 |
| `BP_Interact_SingleDoor` | ❌ 所有实例都不触发 | 父类修改后未被打开过，仅经历了自动的字节码级编译 |

### 直接影响

`BP_InteractEntityComponent::OnRep_m_instanceID()` 是客户端向 `InteractEntitySystem` 注册交互实体的唯一入口。此回调不执行 → 客户端无法识别 SingleDoor 为可交互实体 → 交互功能完全失效。

### 修复

任意修改 `BP_Interact_SingleDoor` 中某个参数后重新编译，问题立即解决。

---

## 二、关键概念

### 2.1 SCS — Simple Construction Script（简单构造脚本）

**SCS 是蓝图中定义组件层级树的机制。** 你在蓝图编辑器的「组件」面板中看到的每一个组件，都对应 SCS 树中的一个节点。

```
┌──────────────────────────────────────────────────┐
│              BP_InteractableBase                  │
│                                                   │
│  SCS Root: DefaultSceneRoot                       │
│    ├── Mesh0                    (StaticMesh)       │
│    ├── MainCollision            (Box)              │
│    ├── InteractTrigger          (CustomBox)        │
│    └── InteractEntityComponent  (关键组件)   │
└──────────────────────────────────────────────────┘
```

#### SCS 的核心职责

| 职责 | 说明 |
|---|---|
| **组件创建顺序** | 定义运行时组件实例化的先后次序 |
| **父子挂载关系** | 哪个组件挂在哪个组件下面（Attachment Hierarchy） |
| **组件类型与默认值** | 组件的类和初始属性（材质、碰撞预设、网络复制标志等） |
| **网络复制注册** | 编译时，`bReplicates=True` 的组件被注册到 `AActor::ReplicatedComponents` 列表 |
| **GUID 分配** | 每个 SCS 节点有一个 `VariableGuid`，由变量名的 SHA1 哈希**确定性**生成 |

#### SCS 节点 GUID 的生成（UE 4.18 / 5.7 一致）

```cpp
// SCS_Node.cpp - ValidateGuid()
void USCS_Node::ValidateGuid()
{
    // Guid 用变量名的 SHA1 哈希确定性生成
    if (!VariableGuid.IsValid() && (InternalVariableName != NAME_None))
    {
        const FString HashString = InternalVariableName.ToString();
        uint32 HashBuffer[5];
        FSHA1::HashBuffer(*HashString, BufferLength, reinterpret_cast<uint8*>(HashBuffer));
        VariableGuid = FGuid(HashBuffer[1], HashBuffer[2], HashBuffer[3], HashBuffer[4]);
    }
}
```

**只要变量名不变，Guid 就永远是同一个**。`"InteractEntityComponent"` → `SHA1` → 固定的 Guid。

#### SCS 的运行时执行

```cpp
// SCS_Node.cpp - ExecuteNodeOnActor()
UActorComponent* USCS_Node::ExecuteNodeOnActor(AActor* Actor, ...)
{
    // 1. 查找正确的组件模板（含 ICH 覆盖）
    UActorComponent* ActualComponentTemplate = GetActualComponentTemplate(ActualBPGC);
    
    // 2. 从模板创建组件实例
    NewActorComp = Actor->CreateComponentFromTemplate(ActualComponentTemplate, ...);
    
    // 3. 标记为 SCS 创建，设置网络可寻址
    NewActorComp->CreationMethod = EComponentCreationMethod::SimpleConstructionScript;
    NewActorComp->SetNetAddressable();
    
    // 4. 如果 bReplicates=True，加入 Actor 的 ReplicatedComponents 列表
    if (NewActorComp->GetIsReplicated())
    {
        NewActorComp->SetIsReplicated(true);  // → UpdateReplicatedComponent → ReplicatedComponents.Add()
    }
}
```

---

### 2.2 ICH — InheritableComponentHandler（可继承组件处理器）

**ICH 是子蓝图记录「我对继承来的组件做了哪些修改」的差异存储机制。** 它属于 `UBlueprintGeneratedClass` 的属性，随蓝图编译而序列化到 .uasset 中。

#### 数据模型

```
UInheritableComponentHandler
  └── TArray<FComponentOverrideRecord> Records
        ├── Record[0]: ComponentClass = InteractBehaviour_SetVisible_C
        │              ComponentKey = { OwnerClass, SCSVariableName, AssociatedGuid }
        │              ComponentTemplate → 子模板副本
        │              CookedComponentInstancingData → 快速实例化数据
        ├── Record[1]: ...
        └── Record[N]: ...
```

#### ICH 记录的生命周期

```
┌─────────────────────────────────────────────────────────────┐
│                    打开子蓝图编辑器                           │
│                                                             │
│  SCS 面板渲染组件树                                          │
│    │                                                        │
│    └→ GetEditableComponentTemplate(bCreateIfNecessary=true) │
│         └→ CreateOverridenComponentTemplate(Key)            │
│               └→ 从父 archetype 复制 → 创建新 ICH Record     │
│                                                             │
│                           ↓                                 │
│                    用户修改组件属性                           │
│                    组件模板 ≠ 父 archetype                    │
│                    记录变为 "necessary"                       │
│                           ↓                                 │
│                    编译蓝图                                   │
│                    ValidateTemplates() 运行                   │
│                      ├── IsRecordValid() → 清除无效记录       │
│                      └── IsRecordNecessary() → 清除无变化记录 │
│                           ↓                                 │
│                    保存 .uasset                              │
│                    仅 "necessary" 的记录被序列化               │
└─────────────────────────────────────────────────────────────┘
```

#### ICH 记录的「必要性」判定

```cpp
bool UInheritableComponentHandler::IsRecordNecessary(const FComponentOverrideRecord& Record) const
{
    auto ChildComponentTemplate = Record.ComponentTemplate;
    auto ParentComponentTemplate = FindBestArchetype(Record.ComponentKey);
    
    // 逐属性对比子模板和父 archetype
    return !FComponentComparisonHelper::AreIdentical(ChildComponentTemplate, ParentComponentTemplate);
}
```

**只有当子组件模板和父 archetype 存在属性差异时，记录才是"必要的"。** 完全相同则编译后清除。

---

## 三、架构全景图

### 3.1 继承链中的 SCS 与 ICH 协作

```
                        ┌─────────────────────────────────────┐
                        │        BP_InteractableBase           │
                        │         (祖父蓝图)                    │
                        │                                     │
                        │  SCS:                               │
                        │   DefaultSceneRoot                   │
                        │   ├─ Mesh0                           │
                        │   ├─ MainCollision                   │
                        │   ├─ InteractTrigger                 │
                        │   └─ InteractEntityComponent ──────┐│
                        │       GUID = SHA1("InteractEntity-  ││
                        │               Component") = G₁      ││
                        └─────────────────────────────────────┘│
                                                │ 继承          │
                        ┌─────────────────────────────────────┐│
                        │     BP_Interact_LevelObstacle       ││
                        │         (父蓝图)                     ││
                        │                                     ││
                        │  SCS (自有):                         ││
                        │   ├─ InteractBehaviour_SetVisible    ││
                        │   ├─ InteractBehaviour_Deduct-       ││
                        │   │  PropertyValue                   ││
                        │   └─ DynamicObstacleAvoidance        ││
                        │                                     ││
                        │  ICH Records (继承覆盖):             ││
                        │   ├─ Mesh0 ................... G₁   ││
                        │   ├─ MainCollision ........... G₁   ││
                        │   ├─ InteractTrigger ......... G₁   ││
                        │   └─ InteractEntityComponent    G₁ ◄┘│
                        │       ComponentTemplate ← 祖父的副本  │
                        └─────────────────────────────────────┘
                                        │ 继承
                        ┌───────────────┼─────────────────────┐
                        │               │                     │
                ┌───────▼──────┐  ┌─────▼────────┐           │
                │ DoubleDoor   │  │ SingleDoor   │           │
                │ (子蓝图)     │  │ (子蓝图)     │           │
                │              │  │              │           │
                │ SCS (自有):  │  │ SCS (自有):  │           │
                │ Door01       │  │ DoTweenDoor  │           │
                │ Door02       │  │ Interact-    │           │
                │ DoTween01    │  │ Behaviour_   │           │
                │ DoTween02    │  │ PlayDoTween  │           │
                │ Interact-    │  │              │           │
                │ Behaviour_   │  │ ICH (8条):   │           │
                │ PlayDoTween  │  │ 同父蓝图的   │           │
                │              │  │ 8条记录      │           │
                │ ICH (8条):   │  │              │           │
                │ 同父蓝图的   │  │              │           │
                │ 8条记录      │  │              │           │
                └──────────────┘  └──────────────┘           │
                        │               │                     │
                        ▼               ▼                     │
                    最近被修改      从未被打开                 │
                    完整重编译过    仅有字节码级编译           │
                    ✅ 正常         ❌ ICH 的               │
                                    ComponentTemplate 引用    │
                                    已失效的父类 archetype     │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 运行时 Actor 构造流程

```
Actor 生成 (BeginPlay 之前)
  │
  ├─ 1. AActor::PostInitProperties()
  │      ReplicatedComponents.Reset()
  │      遍历 OwnedComponents → GetIsReplicated()? → ReplicatedComponents.Add()
  │
  ├─ 2. 对 SCS 树中每个节点调用 ExecuteNodeOnActor()
  │      │
  │      ├─ GetActualComponentTemplate(BPGC)
  │      │   │
  │      │   ├─ 构建 FComponentKey(SCS节点)  → Guid = G₁
  │      │   │
  │      │   └─ 沿继承链向上查找 ICH:
  │      │        BP_Interact_SingleDoor 的 ICH → 找 G₁？
  │      │        BP_Interact_LevelObstacle 的 ICH → 找 G₁？
  │      │        BP_InteractableBase → 无 ICH → 返回原始 ComponentTemplate
  │      │
  │      ├─ 从模板创建组件实例
  │      │    如果模板的 bReplicates 正确 → 进入 ReplicatedComponents ✅
  │      │    如果模板信息残缺 → 组件看似存在但 ReplicatedComponents 里没有 ❌
  │      │
  │      └─ SetNetAddressable() + SetIsReplicated(true)
  │
  └─ 3. 各组件 ReceiveBeginPlay() 被调用
         BP_InteractEntityComponent::OnBeginPlayOnServer()
           → RepLazyProperty(self, "m_instanceID")
           → 如果组件不在 ReplicatedComponents 中 → 复制链路断 ❌
```

### 3.3 父蓝图编译后子蓝图的状态漂移

```
时间线
──────────────────────────────────────────────────────────────►

T₀: 所有蓝图处于一致状态，编译通过

T₁: 修改 BP_Interact_LevelObstacle 的碰撞/导航设置
    │
    ├─ 父蓝图完整编译 → 新 GeneratedClass 创建
    │   SCS 节点重建 → ComponentTemplate 对象被替换
    │   （旧模板被标记为 PendingKill）
    │
    ├─ BP_Interact_DoubleDoor 自动依赖编译（字节码级）
    │   └─ 字节码更新 ✓，类布局不变（ICH 未刷新）
    │
    └─ BP_Interact_SingleDoor 自动依赖编译（字节码级）
        └─ 字节码更新 ✓，类布局不变（ICH 未刷新）

T₂: 手动修改 DoubleDoor → 完整编译
    └─ ICH 记录刷新 → ComponentTemplate 指向新的父 archetype ✅

T₃: SingleDoor 从未被打开/编译
    └─ ICH 的 ComponentTemplate 仍指向 T₁ 之前的旧 archetype
       该 archetype 在父类重编时已被标记为 PendingKill
       创建出来的组件属性残缺 → ReplicatedComponents 未收录 ❌

T₄: 手动修改 SingleDoor → 完整编译
    └─ ValidateTemplates 清理旧记录
       CreateOverridenComponentTemplate 用新 archetype 重建
       → 问题修复 ✅
```

---

## 四、根因总结

### 一句话

**父蓝图重编译触发的子蓝图自动编译是字节码级的（UE4.18）/ 最多到 RelinkOnly（UE5.7），两者都不会重建 ICH 中的 ComponentTemplate。** 子蓝图的 ICH 记录里缓存的组件模板在父类重编后指向已失效的 archetype，导致 `ExecuteNodeOnActor` 创建出的组件属性残缺——尤其是网络复制标志丢失，使其未被加入 `ReplicatedComponents`，最终 `OnRep_m_instanceID` 永远不触发。

### 关键要点

| 要点 | 说明 |
|---|---|
| **不是 Guid 漂移** | SCS 节点的 Guid 由变量名的 SHA1 哈希确定性生成，父子永远一致 |
| **是模板引用失效** | ICH Record 的 `ComponentTemplate` 是父类 archetype 的**浅拷贝**。父类重编译 → archetype 对象被替换 → 子类的拷贝指向过期对象 |
| **字节码编译不够** | 只有完整编译（`EKismetCompileType::Full`）才会重建组件模板。自动依赖编译用 `BytecodeOnly`，不碰类布局 |
| **UE5.7 未根治** | UE5.7 引入了 RelinkOnly 和 FastReinstancing，但前者不重建 ICH，后者默认关闭且靠哈希触发 |

---

## 五、实际操作指南

### 修改父蓝图后的正确流程

| 子蓝图数量 | 推荐做法 |
|---|---|
| 1~5 个 | 逐个打开，做一次无影响修改后编译 |
| 5~30 个 | 用 MCP 脚本批量编译特定继承树 |
| 全部 | **File → Compile All Blueprints** |
| CI / 自动化 | `UE4Editor.exe Project -run=CompileAllBlueprints` |

### 预防措施

1. **不要修改"最终父类"的组件默认值后就不管了**——修改前确认有哪些子蓝图，修改后全部编译一遍
2. **组件蓝图的设计原则**：尽量把行为逻辑放在组件 Lua 中而非依赖组件默认值继承
3. **如果能做到**：把关键组件的默认值（如 `bReplicates`）放在最顶层父类中设置并永久固定，减少中途修改的需求

---

## 六、相关源码索引

| 文件 | 关键内容 |
|---|---|
| `Engine/Source/Runtime/Engine/Private/SCS_Node.cpp` | `ExecuteNodeOnActor`、`GetActualComponentTemplate`、`ValidateGuid` |
| `Engine/Source/Runtime/Engine/Private/InheritableComponentHandler.cpp` | `CreateOverridenComponentTemplate`、`ValidateTemplates`、`IsRecordNecessary` |
| `Engine/Source/Runtime/Engine/Private/BlueprintGeneratedClass.cpp` | `GetInheritableComponentHandler`、`FindArchetype` |
| `Engine/Source/Editor/Kismet/Private/SSCSEditor.cpp` | `GetEditableComponentTemplate`、`INTERNAL_GetOverridenComponentTemplate` |
| `Engine/Source/Editor/Kismet/Private/BlueprintCompilationManager.cpp` | `FlushCompilationQueueImpl`（依赖编译、RelinkOnly 等） |
| `Engine/Source/Editor/KismetCompiler/Private/KismetCompiler.cpp` | 编译器调用 `ValidateTemplates` |
