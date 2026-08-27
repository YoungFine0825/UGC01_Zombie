# UGC01_Zombie — 丧尸生存 UGC 项目

和平精英「绿洲启元」(OasisEra / ShadowTrackerExtra) UGC 平台上的丧尸生存 PVE 项目。
玩家击杀丧尸获取积分，用积分购买武器/汽水、解锁关卡障碍物，触发团队 Buff 与波次事件，在
多张子关卡（大厅/城镇/健身房/单人房）中存活推进。

## 环境与平台约束

| 项目 | 说明 |
|------|------|
| 引擎 | UE 4.18 深度魔改（ShadowTrackerExtra 4.18.1），C++ 层完全封闭 |
| 脚本 | 仅 Lua 5.3（`Script/Blueprint/` 走 KismetLibrary.New，`Script/Gameplay/` 走 UGCRequire） |
| 蓝图 | 仅可建 `Actor` / `ActorComponent` 蓝图类；逻辑图、动画蓝图、材质蓝图均被屏蔽 |
| 单例框架 | `UGCGameMode` / `UGCGameState` / `UGCPlayerController` / `UGCPlayerPawn` / `UGCPlayerState` 各仅一个 |
| Lua OOP | 必须用 `LuaClass(className, ...supers)`（`Script/Gameplay/Core/Class.lua`），蓝图 Lua 自定义继承用 `BPExtend.lua`（顶部捕获式 `local X = BPExtent({}, "完整模块路径")`） |
| FVector | userdata，禁止 `+`/`-` 运算符，用 `UGCMathUtility` |
| 版本 | ugcproj Version 1.37.10.16430；单局 1~4 人，18 个子模式（ModeID 1001=大厅 / 1002=单人房等），初始积分 2000 |

## 快速开始

1. 用绿洲启元编辑器打开 `UGC01_Zombie.ugcproj`（主地图 `UGCmap.umap`）
2. 启动本地 MCP 服务（ugcaskq，`http://127.0.0.1:33444/sse`，见 `.mcp.json`），供编辑器工具链使用
3. Lua 热更直接改 `Script/` 下文件；蓝图资产在 `Asset/Blueprint/`
4. 拉取模拟器/真机日志：`scripts/` 或项目根 `fetch_mumu_logs.py`

## 目录结构

```
Script/
  Blueprint/        扩展 UE 蓝图类的 Lua（KismetLibrary.New，不可 require）
    GameModeActor/    关卡玩法 Actor：Lobby / Town / Gym / SingleMode
    InteractEntity/   可交互实体基类/组件 + Behaviours/
    MonsterSpawner/   丧尸生成器、波次管理器
    TeamBuffs/        团队 Buff 实体 + 掉落管理器 + Behaviours/
    PortalDoor/       传送门
  Gameplay/         纯 Lua 模块（UGCRequire）
    Core/            Class.lua(LuaClass) / EventSystem / GameplayEnum / RoundFlowInfo
    Weapon/          WeaponSystem / WeaponConfigMgr
    InteractEntity/  InteractEntitySystem / InteractEntityConfigMgr / InteractEntityDefine
    Monster/         MonsterAISystem / ZombieSpawnSystem / ZombieWaveManagerHandler
    Backpack/        BackpackSystem
    Player/          PlayerSystem / PlayerRPC / SodaConfigMgr
    Navigation/      NavigationSystem
    GameplaySystem.lua   系统注册入口（InstantiateModules）
    GameplayBooter.lua   生命周期与 Tick 分发（Server/Client 三列表）
Asset/
  Blueprint/        .uasset 蓝图资源
  Data/Table/       DataTable 配置：Weapon / InteractEntity / PlayerSoda / TeamBuffs / Hero / Shop / TalentTree
  Maps/             主图 UGCmap + Lobby / Town / Gym 等子关卡
Navmesh/            烘焙的 .navmesh 数据
.projdesign/        设计文档与 Rule 规范（源）
.projdoc/           深度技术分析与问题记录、api/ 知识图谱
wiki/               平台 wiki 离线抓取（枪械/物品/属性/脚本问题等）
```

## 核心系统

1. **武器系统**：配置数据驱动（`DT_WeaponConfigs` + `Struct_WeaponConfig`）。自定义武器/弹药、
   每把武器独立备弹（独立 AmmoItemId）、`ShootWeaponEntity.BulletType` 运行时切换弹药类型。
2. **背包系统**：`BackpackSystem` + `UBackpackComponentV2` 的 Can/On 拦截链
   （CanUse/CanAdd/CanRemove/CanDrop…），自定义物品使用/取消使用生命周期回调（CanUseV2/OnUseV2/HandleTryDisuse…）。
3. **可交互实体系统**：服务端权威 + 配置驱动。实体按 GameplayTag 分发 Behaviour
   （Grant / PurchaseWeapon / PurchaseSoda / DeductPropertyValue / DestroyEntity / LinkUnlockObstacle /
   ActivateZombieSpawner / ActivateZombieEntries / PlayDoTween / PlayInterpMovement），
   客户端触发 → 服务端校验 → 执行 → 回调表现。设计文档见 `.projdesign/可交互实体Spec.md`。
4. **丧尸 AI 与波次**：`MonsterAISystem`（服务端）+ `BP_ZombieWaveManager` 波次管理 + 行为树
   （注意 BT Service 的 Tick 条件：分支可执行才 Tick）。动态 NavMesh 更新
   （`UGCNavigationSystem.AddDynamicNavAffect` + `AsyncIncrementalBuild`，`UNavModifierComponent.SetAreaClass`
   切换 NavArea 类型——仅改类不触发重建，需配套增量构建）。
5. **团队 Buff**：击杀掉落 + 加权随机（DoublePoints / InstaKill / MaxAmmo / Money），
   触碰即触发（bNeedPlayerConfirm=false 自动触发，注意 overlap 时序竞争）。
6. **关卡与传送门**：Lobby / Town / Gym / SingleMode 子关卡 + `PortalDoor`/`PortalManager` 传送。
7. **网络**：服务端权威复制模型；Lua 复制属性走 `OnRep_<暴露名>`（不是 `OnRep_<m_内部名>`）；
   组件 RPC 需经 Owner Actor 转发；GameState 广播用于全客户端通知。

## 开发约定

- **新增子系统**：`Script/Gameplay/<domain>/` 建模块 → `GameplaySystem.lua` 注册 →
  `GameplayBooter.lua` 挂生命周期钩子；配置类子系统按 ConfigMgr 模式
  （`PathToConfigTable` + `GetDataTableData()` 懒加载 + `ConfigDataCaches` 缓存）。
- **日志**：真机/模拟器分析 `ShadowTrackerExtra.log` 必须用 Lua 原生 `print`
  （`ugcprint` / `GameplayUtils.Print` 不写日志文件）。规范见 `.projdesign/Rule_UGC日志输出规范.md`。
- **调试**：`UGCDebugSystem`（DrawDebug 系列，仅客户端生效），Duration=0 表示每帧绘制。
- **API 权威**：先查 `.projdoc/api/` 与 wiki 离线副本，再查 LuaHelper 存根，禁止凭空假设 API
  存在（已知不存在：KillPlayer、RemoveBuffByObject、AddDynamicState 等）。
- **编码规范**：`Vector.New()` + `.X/.Y/.Z` 大写字段；同步加载用 `UGCObjectUtility.LoadClass`；
  DataTable 操作是实例方法 `dt.data_table_as_json()` 等；事件统一走 `GameplaySystem.EventSystem`
  （Listen/Unlisten/BroadcastGlobal），不用 UGCGenericMessageSystem。

## MCP 工具链

- 配置：`.mcp.json` → ugcaskq SSE（127.0.0.1:33444）
- 工具：`mcp_ugcaskq_ue_py`（执行）/ `mcp_ugcaskq_ue_read`（查询）/ `mcp_ugcaskq_ue_plan_submit`（方案提交）
- 辅助脚本：`.hermes/mcp_call.py`、`.hermes/recompile_all.py`（编译蓝图需谨慎：循环编译可能触发
  EngineBaseTypes.h:485 断言导致编辑器崩溃，优先用编辑器内置保存/Recompile）
- 日志一键脚本：`fetch_mumu_logs.py`（adb + 拉取 UE4 日志）

## 已知平台陷阱（速查）

| 陷阱 | 结论 |
|------|------|
| 玩家击杀 | UGC 无 KillPlayer API → `UGCPawnAttrSystem.SetHealth(pawn, 0)`（可能进濒死），或项目自定义 `ServerChangeState(Dead)` |
| OnRep 回调名 | 是 `OnRep_<暴露名>`，搜索别用内部字段名 |
| 手枪槽位互换 | `bIsPistol=True` 武器被 `SpawnAndBackpackWeaponOnServer` 放到当前武器槽（PUBG 遗留逻辑） |
| bNetLoadOnClient Actor | 组件可能延迟/不初始化（魔改引擎异步复制生成），规避或走 InitComponent 模式 |
| 蓝图组件继承 | 父蓝图改动后子蓝图未重编 → archetype 链断裂、OnRep 不执行 → 重新编译保存 |
| 移动端光照 | 设备档 CVar 关闭动态点光/IBL，动态光上限 4 个；Static 光需 Lightmass 烘焙 |
| 交互 Trigger 被攻击检测 | Trigger ObjectType 用 WorldDynamic/Trigger，避免被技能 Picker 命中（HitBox 是受击框） |
| 复制组件客户端延迟初始化 | OnRep 触发但 Lua ReceiveBeginPlay 不执行 = 复制到达时宿主未初始化（源码级机制） |

## 文档索引

- `.projdesign/` — 设计文档与可执行 Rule（可交互实体Spec、TeamBuff 设计方案/反馈、日志输出规范）
- `.projdoc/` — 深度技术分析：网络复制/Overlap 前后端不一致、蓝图组件继承(SCS/ICH)、BT Service 机制、
  动态 NavMesh、移动端光照、Actor 创建顺序等（含源码行号证据链）
- `wiki/` — 平台 wiki 抓取：枪械蓝图创建/参考表、倒地濒死配置、关卡规范参数、子模式匹配等
- `api/` — 武器系统知识图谱、API 抓取脚本（scrape_api.ps1 / scrape_wiki.ps1）

外部参考技能：`oasis-era-ugc-development`（平台约束/API/陷阱全集）、`unreal-engine-code-analysis`
（UE4.18 复制与生命周期源码级参考）。
