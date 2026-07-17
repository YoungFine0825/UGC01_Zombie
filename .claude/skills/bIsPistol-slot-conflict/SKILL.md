---
name: bIsPistol-slot-conflict
description: 武器 bIsPistol 标志导致槽位冲突的排查与修复。When debugging weapon slot replacement bugs, or when user mentions bIsPistol / pistol slot conflict / 手枪槽位顶替。
---

## 触发条件

- 武器装备到非目标槽位（槽位顶替）
- 涉及手枪类武器（bIsPistol=True）
- 用户报告"第二把武器总是跑到第一把武器的槽位"

## 排查步骤

### 1. 确认 bIsPistol 值

```python
# 通过 UGC AskQ 编辑器 Python 读取
import unreal_engine as ue
from unreal_engine.classes import Blueprint

bp = ue.load_object(Blueprint, '/UGC01_Zombie/Asset/Blueprint/Prefabs/Items/<武器蓝图路径>')
cdo = bp.GeneratedClass.get_cdo()
ue.log(f"bIsPistol: {cdo.bIsPistol}")
```

### 2. 对比日志中的槽位流转

在 DS 日志中搜索关键行：
```
grep "EquipItemV2\|LocalHandleUse\|SpawnAndBackpackWeaponOnServer" DS日志文件
```

关注：
- `EquipItemV2` 的 SlotName（背包 V2 层分配的槽位）
- `LocalHandleUse` 的 TargetSocket（武器 Handle 层收到的目标）
- `SpawnAndBackpackWeaponOnServer` 的 LogicSocket（实际生成槽位）

如果 TargetSocket ≠ LogicSocket，且武器 bIsPistol=True，就是此 bug。

### 3. 修复方法

**方法 A：修改武器蓝图 CDO（推荐）**
- 打开武器 Inventory 蓝图 → Class Defaults → 搜索 `bIsPistol` → 取消勾选

**方法 B：Lua 强制覆盖**
在 `BP_WeaponSystemComponent:ReceiveBeginPlay` 中：
```lua
self:GetOwner().bIsPistol = false
```

### 4. 回归测试

修改后需验证：
- 手枪动画是否正常（Pistol vs Rifle 动画混合）
- 手枪挂载骨骼/Socket 位置是否正确
- 手枪音效是否正常
- 背包 UI 中手枪分类显示是否正确

## 受影响的蓝图

所有继承自 `UGCBackpackShootWeaponHandle_BP` 且 `bIsPistol=True` 的武器 Inventory 蓝图。

## 根因

引擎 C++ `SpawnAndBackpackWeaponOnServer` 内部对 `bIsPistol=True` 的武器强制使用当前手持武器的槽位，不尊重背包 V2 层分配的目标槽位。这是 PUBG 原版"手枪只能放固定副武器槽"的遗留逻辑。
