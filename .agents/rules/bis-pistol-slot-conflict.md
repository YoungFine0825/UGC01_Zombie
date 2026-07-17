# bIsPistol 武器槽位冲突陷阱

## 问题

`bIsPistol=True` 的武器（手枪类）在装备到非主槽位时，会被引擎 C++ 层的 `SpawnAndBackpackWeaponOnServer` 强制重定向到**当前手持武器所在槽位**，忽略背包 V2 层正确分配的目标槽位。

**表现**：槽位1已有 P92，将 P1911 拖到槽位2 → P1911 挤占槽位1，替换掉 P92。

## 根因

引擎 `SpawnAndBackpackWeaponOnServer`（C++ 封闭代码）内部存在 `bIsPistol` 判断分支：

- `bIsPistol=True` → LogicSocket 取当前武器所在槽位（PUBG 原版逻辑：手枪是固定副武器槽位）
- `bIsPistol=False` → LogicSocket 取 TargetSocket（UGC 自由分配逻辑）

背包 V2 层（EquipItemV2）正确分配了目标槽位，但武器系统层（SpawnAndBackpackWeaponOnServer）用 `bIsPistol` 覆盖了结果。

## 证据链（DS日志 17:13:34）

```
P92(bIsPistol=True) → EquipItemV2 MainSlot1 → TargetSocket=MainSlot1 → LogicSocket[MainSlot1] ✓
P1911(bIsPistol=True) → EquipItemV2 MainSlot2 → TargetSocket=MainSlot2 → LogicSocket[MainSlot1] ✗
```

断裂点：`LocalHandleUse` 收到 `TargetSocket=MainSlot2`，但 `SpawnAndBackpackWeaponOnServer` 内部用 `bIsPistol` 覆盖为 `MainSlot1`。

## 影响范围

仅影响 **bIsPistol=True** 的武器。MP5K 等非手枪武器（bIsPistol=False）不受影响。

## 验证过的手枪

| 武器 | bIsPistol | 槽位冲突 |
|---|---|---|
| BP_Inventory_Pistol_P92 | True | 有 |
| BP_Inventory_Pistol_P1911 | True | 有 |
| BP_Inventory_SMG_Mp5K | False | 无 |

## 避坑原则

**UGC 项目中所有需要自由分配到主武器槽位的武器，必须将 `bIsPistol` 设为 `False`。**

设置位置：武器 Inventory 蓝图的 Class Defaults → 搜索 `bIsPistol` → 取消勾选。

或在 `BP_WeaponSystemComponent` 的 Lua 中强制覆盖：
```lua
-- 在 BP_WeaponSystemComponent:ReceiveBeginPlay 中
self:GetOwner().bIsPistol = false
```

## 注意

修改 `bIsPistol` 可能影响：
- 手枪动画选择（Pistol vs Rifle 动画混合空间）
- 手枪挂载骨骼/Socket 位置
- 手枪音效切换逻辑
- 手枪在背包 UI 中的分类显示

修改后需全面回归测试手枪的视觉/音频表现。
