# 子模式匹配与 GameModeActorMgr 加载流程

## 1. 结论

调用 `UGCMultiMode.RequestMatch(ModeID, ...)` 时，`RequestMatch` 只提交子模式 ID 和匹配参数，不直接查找或加载 `GameModeActorMgr` 蓝图。

真正的蓝图映射发生在匹配成功、对应子模式服务器启动后：服务器读取当前 `ModeID`，查询 `UGCGameModeConfig` 数据表中的同名行，再从该行的 `GameModeActorMgr` 字段取得蓝图路径，最后交给 `UGCLevelFlowSystem.EnableLevelFlow`。

```text
大厅选择 ModeID
    │
    ▼
UGCMultiMode.RequestMatch(ModeID, ...)
    │
    ▼
匹配系统按 ModeID 启动对应子模式服务器
    │
    ▼
UGCGameMode:ReceiveBeginPlay()
    │
    ├─ UGCMultiMode.GetModeID()
    │
    ├─ 查询 UGCGameModeConfig.uasset
    │      ModeID → GameModeActorMgr
    │
    └─ UGCLevelFlowSystem.EnableLevelFlow(GameModeActorMgr完整路径)
```

## 2. 配置职责

同一个 `ModeID` 会在两套配置中出现，但职责不同：

| 配置位置 | 作用 |
| --- | --- |
| `UGC01_Zombie.ugcproj` 的 `MultiModeSetting_X` | 匹配设置，例如队伍数量、队伍人数、是否默认模式等 |
| `Asset/Data/Table/UGCGameModeConfig.uasset` | 战斗内容配置，包括副本、刷新方案、结算规则以及 `GameModeActorMgr` 路径 |
| `Asset/Data/Table/UGCGameModeDetail.uasset` | 大厅显示配置，例如名称、图片、描述，以及一个展示项对应的多个难度 `ModeID` |

工程设置中的 MultiMode `ModeID` 必须与 `UGCGameModeConfig.uasset` 中的 `ModeID` 对应。匹配配置本身不会替代 `UGCGameModeConfig` 的蓝图映射。

## 3. 项目代码调用链

### 3.1 大厅发起匹配

大厅模型保存当前选中的 `CurrentSelectedModeID`，开始匹配时将其传给 `UGCMultiMode.RequestMatch`：

```lua
UGCMultiMode.RequestMatch(self:GetCurrentSelectedModeID(), nil, nil, bFillTeammate)
```

代码位置：

- `Script/Blueprint/Arts_UI/Lobby/LobbyModel.lua:296`

### 3.2 子模式服务器读取 ModeID

匹配成功后，新的子模式服务器启动。服务端 `UGCGameMode:ReceiveBeginPlay` 调用 `UGCMultiMode.GetModeID()` 获取本次服务器实际运行的模式 ID：

```lua
local ModeID = UGCMultiMode.GetModeID()
self:InitMode(ModeID)
```

代码位置：

- `Script/Blueprint/UGCGameMode.lua:13`

### 3.3 ModeID 查询 GameModeActorMgr

`UGCGameData.GetGameModeActorMgrConfig(ModeID)` 读取
`Asset/Data/Table/UGCGameModeConfig.UGCGameModeConfig`，遍历表格并匹配 `ModeID`，返回对应行的 `GameModeActorMgr` 字段：

```lua
if GameModeConfig.ModeID == ModeID then
    return GameModeConfig.GameModeActorMgr
end
```

代码位置：

- `Script/Blueprint/UGCGameData.lua:103`

### 3.4 启用模式管理器

得到路径后，项目将其转换为 UGC 资源完整路径，并注册给关卡流程系统：

```lua
UGCLevelFlowSystem.EnableLevelFlow(
    UGCGameSystem.GetUGCResourcesFullPath(
        UGCGameData.GetGameModeActorMgrConfig(ModeID)))
```

代码位置：

- `Script/Blueprint/UGCGameMode.lua:39`
- API：`.projdoc/api/markdown/UGCLevelFlowSystem.md`

`EnableLevelFlow` 的参数是 `GameModeActorMgr` 资源路径，生效范围为服务器。

## 4. GameModeActorMgr 与关卡 Actor 的关系

`GameModeActorMgr` 不是由 `RequestMatch` 直接生成的普通场景 Actor，而是该模式的关卡流程/模式管理配置入口。它负责管理或驱动：

- 当前模式包含哪些副本；
- 副本加载顺序和切换；
- 每个副本使用的关卡资源；
- 刷新方案及刷新数量；
- 副本和整局的分数、时长、结算规则。

因此，`ModeID` 首先映射到 `GameModeActorMgr`，随后由模式管理器继续决定当前阶段需要加载哪个子关卡和 `UGCLevelActor`。实际的副本 Actor 并不是 `RequestMatch` 的直接选择结果。

## 5. 子模式切换时序

项目的 MultiMode 切换属于完整的服务器重启流程，而不是在同一 DS 中简单切换变量：

```text
大厅选择新的 ModeID
    ↓
RequestMatch
    ↓
重新匹配并分配新的 DS
    ↓
新 DS 初始化 GameMode / GameState / Lua VM
    ↓
UGCGameMode.ReceiveBeginPlay
    ↓
GetModeID → 查询 GameModeActorMgr → EnableLevelFlow
    ↓
加载该模式的关卡流程
```

旧 DS 的 GameMode、GameState、PlayerController、PlayerState、Actor 和 Lua 状态都会销毁；新 DS 重新执行完整初始化。

## 6. 常见问题定位

### 6.1 能匹配，但没有加载模式关卡

优先检查：

1. `UGCMultiMode.GetModeID()` 实际返回值；
2. `UGCGameModeConfig.uasset` 是否存在该 `ModeID` 行；
3. 该行的 `GameModeActorMgr` 是否为空；
4. 路径是否是正确的 UGC 资源路径；
5. `UGCLevelFlowSystem.EnableLevelFlow` 是否在服务端调用。

### 6.2 大厅显示模式与实际战斗模式不一致

检查以下 ID 是否一致：

```text
大厅选择结果
    = UGCGameModeDetail.ModeIDs 中的值
    = UGCGameModeConfig.ModeID
    = .ugcproj 的 MultiModeSetting_X.ModeID
```

其中 `UGCGameModeDetail` 主要负责显示和难度选择，真正决定战斗管理器的是 `UGCGameModeConfig.ModeID → GameModeActorMgr`。

### 6.3 新增模式后忘记配置管理器

仅在 `.ugcproj` 中新增 `MultiModeSetting_X` 不足以完成一个可运行子模式。还必须在 `UGCGameModeConfig` 中新增同一 `ModeID` 的数据行，并填写有效的 `GameModeActorMgr` 路径。

## 7. 相关文件

- `Script/Blueprint/Arts_UI/Lobby/LobbyModel.lua`
- `Script/Blueprint/UGCGameMode.lua`
- `Script/Blueprint/UGCGameData.lua`
- `Asset/Data/Table/UGCGameModeConfig.uasset`
- `Asset/Data/Table/UGCGameModeDetail.uasset`
- `UGC01_Zombie.ugcproj`
- `.projdoc/api/markdown/UGCLevelFlowSystem.md`
- `.projdoc/wiki/articles_md/20192_模式配置（多人PVE模式）.md`

