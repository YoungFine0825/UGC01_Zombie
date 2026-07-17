# 伤害系统陷阱

本文件记录 UGC 伤害系统中容易踩的坑，基于实际 Bug 排查经验。

## 陷阱一：碰撞通道绕过 `PreOverrideDamage`

### 场景

一个 Actor 需要**只接受特定类型攻击者的伤害**（如 Entry 只接受丧尸伤害）。在 `PreOverrideDamage` 中判断 `DamageCauser` 并返回 0 来阻止：

```lua
function BP_Entry:PreOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
    if not DamageCauser:ActorHasTag("Zombie") then
        return 0  -- 意图：非丧尸无法造成伤害
    end
    ...
end
```

**但这不够。** 伤害事件能否到达 `PreOverrideDamage` 本身取决于碰撞通道设置。

### 问题

碰撞通道是分层级的：
- **Bullet** 通道 — 子弹/远程武器专用
- **PlayerApplyDamage** 通道 — 近战/玩家直接伤害专用

UE 的伤害系统需要碰撞通道来"命中"目标。如果 HitBox/Collision 组件：
- ✅ 忽略了 Bullet → 子弹打不到 ✅ 符合预期
- ❌ 但**没有忽略 PlayerApplyDamage** → 玩家近战可以命中 → 伤害事件到达 `PreOverrideDamage`

即使 `PreOverrideDamage` 返回了 0，伤害事件已经进入了管线，后续的 `GlobalDamageCalculation` 仍可能修改伤害值。

### 避坑原则

**防御式设计：碰撞通道 + 代码逻辑都要设防。**

1. **碰撞层面**：在 Blueprint 中确保 HitBox/Collision 组件忽略**所有**不应接收的伤害通道（不仅是 Bullet，还有 PlayerApplyDamage）
2. **代码层面**：`PreOverrideDamage` 做二次校验（已做但不够）
3. **代码层面**：`GlobalDamageCalculation` 中也要校验 SourceMagnitude 是否为 0（见陷阱二）

### 排查方法

怀疑碰撞通道问题时，在 `PreTakeDamageEvent` 加日志——如果这个函数被调用了，说明碰撞通道没有阻挡住伤害。

---

## 陷阱二：`GlobalDamageCalculation` 无条件覆盖 `SourceMagnitude`

### 场景

`PreOverrideDamage` 正确返回了 0，但 Actor 仍然被击杀。

### 问题

`UGCGlobalDamageCalculation:GetCalculationResult` 的调用顺序在 `PreOverrideDamage` **之后**。但 `GetCalculationResult` 中的某些分支会**无条件覆盖** `SourceMagnitude`，不检查输入值是否为 0：

```lua
-- UGCGlobalDamageCalculation:GetCalculationResult
local SourceMagnitude = UGCAttributeSystem.GetSourceMagnitudeFromContext(Context)

if RestrictedDamageType == ERestrictedDamageType.ShootDamage then
    -- 枪械伤害：基于原始 SourceMagnitude 计算倍率
    BoneDamageBoost = ...
elseif RestrictedDamageType == ERestrictedDamageType.MeleeDamage then
    SourceMagnitude = 150  -- ❌ BUG：无条件设为 150，覆盖了 PreOverrideDamage 返回的 0！
end

local FinalDamage = SourceMagnitude * BoneDamageBoost * ...
```

**伤害管线顺序**：
```
碰撞检测 → PreTakeDamageEvent → PreOverrideDamage(返回0) → GlobalDamageCalculation(覆盖为150) → 应用伤害 → 目标死亡
                                              ↑                                           ↑
                                         保护失效                                   这里覆盖了保护
```

`PreOverrideDamage` 返回 0 的意图是"不受伤害"，但 `GlobalDamageCalculation` 在之后把 0 改成了 150，前功尽弃。

### 避坑原则

**在 `GlobalDamageCalculation` 的任何分支中，先检查 `SourceMagnitude` 是否已被 `PreOverrideDamage` 设为 0。**

```lua
-- ✅ 正确做法
if SourceMagnitude <= 0 then
    return 0  -- PreOverrideDamage 已经阻止了伤害，不再计算
end

if RestrictedDamageType == ERestrictedDamageType.MeleeDamage then
    SourceMagnitude = 150
end
```

### 泛化教训

这是一个**多层防御失效**的典型案例：
- 第一层（碰撞通道）：PlayerApplyDamage 没挡 → 失效
- 第二层（PreOverrideDamage）：返回 0 → 正确
- 第三层（GlobalDamageCalculation）：**覆盖了第二层的保护** → 全线崩溃

设计伤害过滤逻辑时，必须理解整个管线的执行顺序，确保后面的环节不会覆盖前面的保护性修改。

---

## 伤害管线参考

```
1. 碰撞通道检测 (Collision Channel)
   → 不通过则伤害事件不产生
2. PreTakeDamageEvent(Damage, Instigator, Causer, Context)
   → 观察性钩子，不能修改伤害
3. PreOverrideDamage(Damage, Instigator, Causer, Context) → return modifiedDamage
   → 唯一能修改伤害值的入口
4. GlobalDamageCalculation:GetCalculationResult(Context)
   → 全局伤害公式，可能覆盖第3步的修改 ⚠️
5. PostOverrideDamage (如果有)
6. 属性系统扣血
7. PostTakeDamageEvent(Damage, Instigator, Causer, Context)
8. 如果 Health <= 0 → BPDie → ReceiveEndPlay
```
