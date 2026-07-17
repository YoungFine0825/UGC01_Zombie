---
name: ugcaskq-mcp
description: "UGCAskQ MCP 使用指南：连接绿洲启元编辑器 AI 协作接口，支持场景管理、蓝图操作、技能/物品/行为树/UI 配置、Python 脚本执行。含 PRV 安全流程。"
---

## 概述

UGCAskQ MCP（Model Context Protocol）连接 AI 助手（Claude / Cursor / Hermes）到绿洲启元 UGCEditor，通过自然语言完成编辑器操作。

**状态：早期实验阶段** — 操作前务必备份工程，每次只执行一小步，结果需人工校验。

## 连接架构

```
AI Client (Hermes/Claude/Cursor)
  ↓ SSE transport
http://127.0.0.1:33444/sse
  ↓
UGCEditor MCP Server (编辑器内置)
```

## 快速接入（3 步）

### 步骤 1：启动编辑器 MCP Server

编辑器菜单：**窗口 → 开发者工具 → MCP Server**

面板显示 **Running（Port: 33444）** 即可。未启动则点击 **Start Server**。

面板配置项：

| 配置项 | 说明 | 推荐 |
|--------|------|------|
| Port | 监听端口，默认 33444 | 默认即可，冲突时修改 |
| Enforce Level | PRV 安全策略 | Observe（警告不阻断） |
| Enable MCP Call Logging | 调用日志 | 开启 |
| Idle Boundary (sec) | 空闲超时阈值 | 90 秒（0=关闭） |

日志位置：`Saved/log/MCP_YYYYMMDD.log`

### 步骤 2：配置 AI 客户端

**Claude Desktop / Cursor** — 项目根目录创建 `.mcp.json`：

```json
{
  "mcpServers": {
    "ugcaskq": {
      "type": "sse",
      "url": "http://127.0.0.1:33444/sse"
    }
  }
}
```

**Hermes Agent** — 在 `~/.hermes/config.yaml` 添加：

```yaml
mcp_servers:
  ugcaskq:
    url: http://127.0.0.1:33444/sse
    transport: sse
```

> ⚠️ `transport: sse` 必须显式设置。Hermes 默认用 StreamableHTTP，对 SSE 服务器会报 405。

### 步骤 3：验证连接

向 AI 发送测试问题：
- "当前场景里有哪些 Actor？"
- "你现在能在编辑器里做哪些操作？"

Hermes CLI 验证：
```bash
hermes mcp test ugcaskq
# ✓ Connected (406ms)
# ✓ Tools discovered: 3
```

## 三个核心工具

| 工具 | 用途 | 说明 |
|------|------|------|
| `ue_read` | 查询编辑器状态 | 纯读操作，无需 PRV plan |
| `ue_plan_submit` | 提交 PRV 计划 | 写操作前必须先提交 plan |
| `ue_py` | 执行 Python 代码 | 可读可写，写操作需 plan 或 plan_id |

工具自动注册为 `mcp_ugcaskq_<tool>`，新配置后需 `/reset` 或新会话。

## PRV（Plan-Resolve-Verify）工作流

**所有写操作**（setattr、save_package、actor_spawn 等）必须走 PRV 流程：

```
1. RESOLVE — ue_read 查询 API（py:workflow <domain>）
2. PLAN    — ue_plan_submit 提交 YAML plan → 获得 plan_id
3. EXECUTE — ue_py 代码 + plan_id 执行
```

纯查询（ue_read、py:index 等）跳过 PRV。

### Plan YAML 示例（CDO 属性修改）

```yaml
intent: "修改武器伤害和弹夹容量"
asset_path: /TestNavmesh/Asset/Weapons/Custom_AWM_Sniper
pre_write_snapshot: true
apis_to_call:
  - py:load_object
  - py:get_cdo
  - py:get_uproperty
  - py:has_metadata
  - py:save_package
mutations:
  - property: BaseImpactDamage
    value: "300"
    gate: bIsAttributeOverride
  - property: MaxBulletNumInOneClip
    value: "20"
    gate: bIsAttributeOverride
```

### Plan YAML 示例（场景 Actor 操作）

```yaml
intent: "Phase1 空气墙 + NavMesh"
asset_path: /TestMap/UGCmap
scene_ops:
  - op: actor_spawn
    klass: StaticMeshActor
    label: AirWall_North
    folder: Map/AirWalls
  - op: actor_modify
    label: AirWall_North
    fields: "bHidden=true; SetCastShadow(false)"
  - op: actor_destroy
    label: BP_STPlayerStart_2
```

### plan_id 复用

同一个 asset 的多次 ue_py 调用可复用同一个 plan_id（15 分钟 TTL），避免重复提交。

## 支持的编辑器功能

### 场景与 Actor 管理
- 创建/放置 Actor（指定位置、旋转、缩放）
- 查询/修改 Actor 属性（Transform、标签、父子关系）
- 批量操作（一次性放置多个同类 Actor）

示例："在坐标 (0,0,100) 放置 BP_Rock，缩放设为 2"

### 技能编辑器
- 创建新技能（指定类型和基本属性）
- 读取/修改技能配置（冷却、消耗等）

示例："创建近战技能，冷却 3 秒，消耗能量 20"

### 物品编辑器
- 创建/查询物品（类型、名称、图标）
- 修改物品数值属性

示例："创建消耗品'急救包'，恢复 50 点生命值"

### 行为树
- 创建/读取行为树资产
- 添加/配置节点（Selector、Sequence、Task）
- 挂载 Lua 脚本扩展自定义逻辑

示例："给 Boss 行为树加巡逻节点，血量低于 30% 切换逃跑"

### 蓝图编辑器
- 创建新蓝图（指定父类）
- 查询变量/函数列表
- 添加变量（Bool、Int、Float、Vector）
- 向黑板添加键值

示例："在角色蓝图添加 Bool 变量 'IsAttacking'"

### UI 编辑器（UMG）
- 创建 UMG 蓝图资产
- 添加控件（Button、Text、Image、ProgressBar）
- 设置控件位置/大小/锚点
- 配置文本内容和颜色

示例："创建血量条 Widget，含 ProgressBar 和 Text 控件"

### 数据表（配置表）
- 读取数据行
- 添加/修改数据行

示例："物品表添加 ID=1001，类型武器，攻击力 50"

### 实体编辑器
- 查询/修改实体属性（生命值、移速、攻击距离）
- 读取组件信息

示例："精英小怪生命值改 800，移速提高 20%"

### 资产查找与视窗控制
- 按名称/类型搜索资产
- 控制编辑器摄像机位置和朝向

示例："找到所有名称含 'Weapon' 的静态网格资产"

## 推荐使用模式

### 批量内容生成
> "按坐标列表放 10 个 BP_Bush，缩放随机 0.8~1.2"

### 技能原型快速迭代
> "冲刺技能：向前冲 500 单位，无敌 0.3 秒，冷却 8 秒"

### 配置核查与批量修改
> "读取所有近战技能，列出冷却超过 10 秒的"

### UI 布局辅助
> "游戏结算界面：顶部标题、中间分数、底部返回按钮"

### 行为树搭建
> "巡逻小怪：沿路点巡逻→发现玩家追击→超 15 秒或超 800 距离放弃"

## 常见问题

| 问题 | 解决方案 |
|------|----------|
| AI 连接后"找不到服务器" | 确认面板 Running；检查端口号一致；重启 AI 客户端 |
| 操作后编辑器没反应 | 部分操作需手动刷新面板（如蓝图变量添加后需重开蓝图编辑器） |
| AI 不知道场景状态 | 直接问"当前场景里有什么？"，AI 会主动查询 |
| 查看调用记录 | 面板点击 Open Log Folder，查看 `MCP_YYYYMMDD.log` |
| 能否边操作边让 AI 辅助 | 可以，AI 会感知你当前选中的 Actor 或打开的编辑器 |
| Hermes 报 405 | config.yaml 中 `transport: sse` 未设置，Hermes 默认用 StreamableHTTP |
| hermes mcp list 不显示 | 检查 config.yaml 的 `mcp_servers` 格式，确认 `transport: sse` |

## 诊断命令

```bash
# 检查端口是否在监听
netstat -ano | grep 33444

# 测试连接
hermes mcp test ugcaskq

# 列出已注册 MCP 服务器
hermes mcp list
```

## 注意事项

1. **仅本机连接** — MCP Server 不支持远程访问
2. **备份工程** — 操作前先保存，避免误操作
3. **逐步验证** — 复杂操作分阶段执行，每阶段确认效果
4. **结果不一定准确** — AI 生成的配置/节点需人工检查
5. **功能范围有限** — 特效编辑器、音频编辑器等暂无 MCP 接口
6. **资产路径规则** — 用 `/<ProjectName>/Asset/...`，不用 `/Game/`
7. **plan_id 有 TTL** — 默认 15 分钟，超时需重新提交

## 官方文档来源

`.projdoc/wiki/articles_md/20414_UGCAskQ MCP 使用说明.md`
最后更新：2026-06-22
