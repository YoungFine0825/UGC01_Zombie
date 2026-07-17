---
name: ugc-get-component-by-class
description: 通过类路径字符串获取 UClass，再按类型查找 Actor 上的 Component。Use when user needs to find components by type on an Actor in UGC Lua, or mentions GetComponentsByClass / LoadClass / FindClass.
---

## 用法

```lua
-- 1. 通过类路径获取 UClass
local compClass = UGCObjectUtility.LoadClass("/Script/Engine.PrimitiveComponent")

-- 2. 按 UClass 查找 Actor 上所有匹配的 Component
local owner = UGCActorComponentUtility.GetOwner(self)
local comps = UGCActorComponentUtility.GetComponentsByClass(owner, compClass)

-- 3. 返回值是 UActorComponent[]（Lua 数组），用 ipairs 遍历
for i, comp in ipairs(comps) do
    print("Found:", comp)
end
```

## 关键点

- `UGCObjectUtility.LoadClass` 用于获取 UClass 对象，**不是** `FindClass`（该项目生态中无实际用例）。
- UE 引擎内置类的路径格式：`/Script/ModuleName.ClassName`。模块名对应 `.Build.cs` 所在的目录层级（如 `Engine/Source/Runtime/Engine` → 模块名 `Engine` → `/Script/Engine.PrimitiveComponent`）。
- `UGCActorComponentUtility.GetComponentsByClass` 返回 `UActorComponent[]` 即 **Lua 数组**，直接用 `ipairs` 遍历，不是 `ULuaArrayHelper`。
- `UGCActorComponentUtility.GetOwner(self)` 返回组件挂载的 Actor。

## 判断依据

**.projdoc/api/ 是 API 行为的权威来源。**

- 任何 API 的返回值类型、参数列表、调用方式的判断，**必须优先参照 `.projdoc/api/` 目录下的官方文档**，而非猜测或基于其他引擎版本的记忆。
- API 文档与项目 LuaHelper 类型存根（`Content/LuaHelper`）冲突时，以 API 文档为准。
- 在 Skill 和规则文件中引用任何 API 行为时，必须能在 API 文档中找到对应来源。

## 常用引擎类路径

| 类 | 路径 |
|---|---|
| `UPrimitiveComponent` | `/Script/Engine.PrimitiveComponent` |
| `UShapeComponent` | `/Script/Engine.ShapeComponent` |
| `UBoxComponent` | `/Script/Engine.BoxComponent` |
| `USphereComponent` | `/Script/Engine.SphereComponent` |
| `UCapsuleComponent` | `/Script/Engine.CapsuleComponent` |

## 验证来源

- `UGCObjectUtility.LoadClass` 有大量实际用例（`/Script/UGCGame.UGCMobCharacter` 等）。
- 类路径由 UE4.18 源码 `Engine/Source/Runtime/Engine/Classes/Components/PrimitiveComponent.h` 中的 `UCLASS` 宏确认。
- `UGCObjectUtility.FindClass` 全项目生态零用例，不推荐使用。
