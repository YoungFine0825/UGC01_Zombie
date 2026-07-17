---
name: ugc-get-object-name
description: 获取 Actor 或 Component 在编辑器中的名称。Use when user needs to get the display name of an Actor/Component for logging, debugging, or identification purposes.
---

## 用法

```lua
-- 获取 Actor 在编辑器中的名称
local name = UGCObjectUtility.GetObjectName(someActor)

-- 获取 Component 在编辑器中的名称
local compName = UGCObjectUtility.GetObjectName(someComponent)

-- 日志中使用
GameplayUtils.Exception(string.format(
    "[MySystem] Actor=%s 执行了某操作", UGCObjectUtility.GetObjectName(actor)
))
```

## 关键点

- `UGCObjectUtility.GetObjectName(UObject InObject)` 返回 `string`，即对象在编辑器内显示的名称。
- 适用于所有 `UObject` 子类：Actor、ActorComponent、Widget 等。
- **不要使用 `self:GetName()` 或 `actor:GetName()`** — 引擎 Lua 绑定未暴露此方法，调用会抛异常。
- ~~`GameplayUtils.GetUEObjClassName(obj)`~~ 获取的是**类名**不是实例名，用于日志中识别对象名称时应改用 `GetObjectName`。

## API 来源

`.projdoc/api/markdown/UGCObjectUtility.md:156-159`：
```
string GetObjectName(UObject InObject)
```
