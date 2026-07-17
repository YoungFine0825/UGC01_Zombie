# UGC Lua 编码规则

本文件记录在 ShadowTrackerExtra/OasisEra UGC 环境中编写 Lua 代码时必须遵守的规则。这些规则基于实际踩坑经验积累。

## 禁止使用的 API

### `GetName()` — 所有 Actor 的 `GetName()` 在 Lua 侧均无效

- **现象**：调用任何 UGC Actor 的 `:GetName()` 会抛出 `attempt to call a nil value (method 'GetName')`
- **原因**：引擎的 Lua 绑定层未暴露此方法
- **替代方案**：
  - 需要**实例名**（编辑器内名称）：`UGCObjectUtility.GetObjectName(obj)` → 返回字符串
  - 需要**类名**（Blueprint 类名）：`GameplayUtils.GetUEObjClassName(obj)` → 返回字符串
- **受影响的类**：所有 Actor 及其子类（PlayerPawn、ZombiePawn、Entry、Spawner 等）

```lua
-- ❌ 错误
local name = zombiePawn:GetName()

-- ✅ 正确：获取编辑器内的实例名
local name = UGCObjectUtility.GetObjectName(zombiePawn)

-- ✅ 正确：获取 Blueprint 类名
local className = GameplayUtils.GetUEObjClassName(zombiePawn)
```

详见 `.agent/skills/ugc-get-object-name/SKILL.md`。

## 日志输出规范

### 调试日志使用 `GameplayUtils.Exception` 或 `GameplayUtils.Print`

- `GameplayUtils.Exception(msg, ...)` — 重要信息，输出为 `[TagLog] [Gameplay Exception]`，在日志中高亮
- `GameplayUtils.Print(msg, ...)` — 普通信息，输出为 `[TagLog] [Gameplay]`

### 格式化字符串

使用 `string.format()` 构建结构化日志：

```lua
GameplayUtils.Exception(string.format(
    "[标签] 描述 | key1=%s | key2=%d | key3=%s",
    value1, value2, value3
))
```

## 常见问题

### `UE.IsValid()` 检查 Blueprint 对象有效性

在调用 Blueprint 对象的方法前，始终检查 `UE.IsValid(obj)`：

```lua
if UE.IsValid(entry) and entry:HaveFreePositionSlots() then
    -- safe to use
end
```

### Lua 类系统：避免类级别共享可变表

使用 `LuaClass()` 定义类时，可变表（如 `{}`）如果写在类表上会成为所有实例共享的表：

```lua
-- ❌ 类级别：所有实例共享同一张表
BP_MyClass.m_sharedList = {}

-- ✅ 实例级别：在 ReceiveBeginPlay 或 Ctor 中初始化
function BP_MyClass:ReceiveBeginPlay()
    self.m_instanceList = {}
end
```
