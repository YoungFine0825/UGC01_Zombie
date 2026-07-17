# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指导。

## 项目背景

本项目是基于 **UE 4.18.1** 的和平精英绿洲启元（OasisEra）UGC 项目。引擎运行时代号为 ShadowTrackerExtra，官方未开源引擎源码。可以谨慎参考 `F:\Games\UE_4.18` 目录下的 Epic 官方 UE 4.18 源码辅助理解引擎机制，但需注意官方源码与绿洲启元定制版之间存在差异。

## 行为准则（来自 andrej-karpathy）

减少大模型常见编码错误的行为准则，与项目特定说明配合使用。**权衡：** 这些准则偏向谨慎而非速度。对于简单任务，自行判断。

### 0. 永远读取最新代码

**引用、分析、修改任何代码文件之前，必须先重新 Read 该文件，验证内容为最新。** 禁止依赖对话历史中缓存的读取记录——项目代码随时可能被用户修改，缓存内容不可信。这条规则优先级最高，违反它会导致基于过期代码做出错误判断。

### 1. 编码前先思考 — 不要假设，不要隐藏困惑，暴露权衡取舍

实现之前：
- 明确陈述你的假设。如果不确定，开口问。
- 如果存在多种解读，全部列出 — 不要默默选择其中一种。
- 如果存在更简单的方案，说出来。有据理反驳的时候要反驳。
- 如果有不清楚的地方，停下来。说出困惑点。开口问。

### 2. 简洁优先 — 解决问题的代码越少越好，不写推测性代码

- 不添加需求之外的功能。
- 不对只使用一次的代码做抽象。
- 不做未被请求的"灵活性"或"可配置性"。
- 不为不可能的异常场景做错误处理。
- 如果你写了 200 行但 50 行就能搞定，重写它。

问自己："一个资深工程师会说这过度复杂吗？"如果是，简化它。

### 3. 手术级修改 — 只碰必须改的，只清理自己造成的遗留

修改已有代码时：
- 不要"改进"相邻的代码、注释或格式。
- 不要重构没坏的东西。
- 匹配现有风格，即使你觉得应该换种写法。
- 如果你注意到无关的死代码，提出来 — 但不要删。

当你的改动制造了孤立代码：
- 移除**因你的改动**而不再使用的导入/变量/函数。
- 不要删除原有的死代码，除非被要求。

检验标准：每一行改动都应该能追溯到用户的需求。

### 4. 目标驱动执行 — 定义成功标准，循环直到验证通过

把任务转化为可验证的目标：
- "加验证" → "为无效输入写测试，然后让测试通过"
- "修 bug" → "写一个复现它的测试，然后让测试通过"
- "重构 X" → "确保重构前后测试都通过"

对于多步骤任务，先陈述简要计划。强有力的成功标准让你能独立循环迭代。模糊的标准（"让它跑起来"）需要频繁澄清。

**准则生效的标志：** diff 中不必要的改动减少，因过度复杂导致的返工减少，澄清性问题在实现前提出而非在犯错后。

---

## 项目概述

PUBG Mobile / 和平精英 UGC 僵尸生存模式（`UGC01_Zombie`）。Lua 脚本（5.3）运行在 ShadowTrackerExtra/OasisEra C++/Blueprint 引擎之上。所有游戏逻辑均以 Lua 编写 —— 此 UGC 环境中**禁用**蓝图可视化编程。

**主要参考：** `AGENTS.md` 包含权威的架构文档、生命周期细节和子系统注册表。处理玩法系统时请先阅读该文件。

## 身份切换机制

AI 助手配备三种专家身份（详见 `.agent/person/`），根据任务自动切换。**每次回答前必须声明当前身份**：

| 身份 | 触发领域 |
|---|---|
| 🎮 **游戏逻辑开发**（默认） | Lua 脚本、玩法系统、UI 逻辑、网络、DataTable、子系统 |
| 🎨 **美术技术** | 材质/材质实例、粒子特效、贴图、模型、音效、UI 视觉 |
| ⚡ **性能优化** | 帧率、Draw Call、内存、LOD、网络带宽、加载时间、移动端适配 |

切换规则：默认游戏逻辑身份；任务明显属于美术/优化领域时自动切换；跨领域任务可分阶段使用不同身份。回答格式示例：`🎮 **当前身份：游戏逻辑开发**`

## 编码规则

**编写 Lua 代码前务必查阅 `.agent/rules/` 目录下的规则文件。** 这些规则基于实际踩坑经验，违反会导致运行时异常（如 `GetName()` 在 Lua 侧无效等问题）。

## 项目能力资源

AI 助手在项目中拥有以下能力资源目录，在执行任务前应查阅：

| 目录 | 用途 | 何时查阅 |
|---|---|---|
| `.agent/person/` | 专家身份设定 | 每次回答前切换身份 |
| `.agent/rules/` | 编码规则与避坑指南 | 编写 Lua 代码前必读 |
| `.agent/skills/` | 项目专用技能 | 遇到匹配的任务类型时主动调用 |

## API 行为判断

**.projdoc/api/ 是 API 行为的权威来源。** 任何 API 的返回值类型、参数列表、调用方式，必须优先参照 `.projdoc/api/` 目录下的官方文档，而非猜测或基于其他引擎版本的记忆。当 API 文档与 `Content/LuaHelper` 类型存根冲突时，以 API 文档为准。

## 平台硬约束

- **仅一个 `.umap`**：`UGCmap.umap` 是唯一的顶层地图。所有场景（Lobby、Town、SingleMode_X）均通过 `UGCLevelFlowSystem` 作为子关卡加载。切勿在根目录创建新的 `.umap` 文件。
- **每类仅一个**：`UGCGameMode`、`UGCGameState`、`UGCPlayerController`、`UGCPlayerPawn`、`UGCPlayerState` 各仅允许一个实例。
- **切换模式 = 完整 DS 重启**：更改 ModeID 会销毁整个 Lua VM 及全部状态（参见 `.projdoc/MultiMode.md`）。
- **不支持蓝图可视化编程** —— 仅开放 Lua 脚本。
- **不能创建材质蓝图** —— 只能创建材质实例。
- **不支持 Slate 编辑器扩展**。
- **18 种游戏模式**：ModeID 1001–1018，在 `UGC01_Zombie.ugcproj` 的 `[MultiModeSetting_0]` 至 `[MultiModeSetting_17]` 中配置。ModeID 1001 为大厅（默认），1002+ 为玩法模式。

## 目录结构

| 目录 | 用途 |
|---|---|
| `Script/Blueprint/` | 扩展 UE Blueprint 类的 Lua 脚本。使用 `KismetLibrary.New()` 而非 `require()`。 |
| `Script/Gameplay/` | 核心玩法系统，纯 Lua 模块（使用 `UGCRequire()` / `require()`）。 |
| `Script/Gameplay/Core/` | 基础设施：`Class.lua`（LuaClass 面向对象）、`EventSystem.lua`（发布订阅）、`GameplayEnum.lua`。 |
| `Script/Gameplay/Config/` | GameplayEvents 定义、ActorTags 配置。 |
| `Script/Common/` | 自定义 UE 结构体/枚举定义（`ue_struct_custom.lua`、`ue_enum_custom.lua`）。 |
| `Script/GameAttribute/` | 全部原生及自定义属性类型（`game_attribute_type.lua`）。 |
| `Script/gamemode/` | 各模式独立的玩法逻辑（每个 ModeID 一个目录）。 |
| `Script/utils/` | 开发者工具、GM 命令（`gm.lua` 通过 `ugc_gmui` 注册）。 |
| `Asset/Data/Table/` | DataTable：怪物、刷怪方案、武器、词条、商城物品。 |
| `Asset/Blueprint/` | Blueprint 资源（.uasset），用于 UI、游戏 Actor、组件。 |
| `Asset/Maps/` | 通过 UGCLevelFlowSystem 加载的子关卡 .umap 文件。 |
| `ExtendResource/` | ShopV2 和 HeroSelect 参考实现。 |
| `.projdesign/` | 架构设计文档。 |
| `.projdoc/` | 项目文档：Actor 创建顺序、模式切换、关卡规范、待办清单。 |

## 新增子系统

1. 在 `Script/Gameplay/<领域>/` 下创建模块
2. 在 `Script/Gameplay/GameplaySystem.lua` 的 `GameplaySystem` 表中注册
3. 在 `Script/Gameplay/GameplayBooter.lua` 中添加生命周期钩子（BeginPlayOnServer/Client、EndPlayOnServer/Client）

## 通信模式

- **服务端 → 客户端 RPC**：通过 `Script/Gameplay/Player/PlayerRPC.lua`，使用 `UnrealNetwork.CallUnrealRPC_Unreliable()`
- **客户端 → 服务端**：从 `Script/Blueprint/UGCPlayerController.lua` 发起请求
- **本地发布订阅**：`Script/Gameplay/Core/EventSystem.lua` —— `EventSystem:Listen()`、`EventSystem:Broadcast()`、`EventSystem:BroadcastGlobal()`（后者桥接至 `UGCGenericMessageSystem`）
- **跨系统全局事件**：`UGCGenericMessageSystem.BroadcastUserDefinedGlobalMessage()`

## Lua 面向对象系统

使用 `Script/Gameplay/Core/Class.lua` 中的 `LuaClass(className, ...superClasses)`。支持多继承，使用 Ctor 构造函数和 `cls.New(...)` 实例化。切勿使用原生 metatable 面向对象模式。

## 调试

- **EmmyLua 调试器**：端口 9966，配置于 `.vscode/launch.json`。启动配置 "PIE0"，host `0.0.0.0`。
- **Lint**：`.emmyyrc.json` 禁用了若干诊断类别（need-check-nil、undefined-global 等）。
- **引擎类型存根**：工作区包含 `..\..\Content\LuaHelper`，提供引擎 API 类型信息。
- **GM 命令**：`Script/utils/gm.lua`，通过 `ugc_gmui` 系统注册。

## 关键配置文件

- `UGC01_Zombie.ugcproj` — 项目清单：StartMapName、GameModePath、ModeID、匹配设置、目标平台。
- `UGCGameplayTags.ini` — Gameplay 标签，用于伤害类型、装备槽位、Pawn 状态。
- `WhiteList.ini` — 调试白名单用户 ID（2 条）。
- `DeleteFiles.txt` — 待删除文件（地图 `SingleMode_1` 至 `SingleMode_6`）。
- `ReferenceAssetList.txt` — 构建时必须包含的外部资源引用。

## 近期重要变更

- `dc9d07e`：武器系统 —— 派发武器给玩家的同时派发相应的弹药。
- 当前工作树：大量 UI、装备、仓库、突破系统的 `.uasset` 修改。
"" 
