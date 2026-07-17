# OasisEra 武器系统知识图谱

> **文档版本**: v1.0  
> **生成日期**: 2026-07-13  
> **数据来源**: `Content/LuaHelper/Content/UGC/UGCGame/Weapon/` 目录下全部 Lua 类型存根文件  
> **平台**: OasisEra / ShadowTrackerExtra UGC (UE 4.18 修改版, Lua 5.3, C++ 闭源)

---

## 目录

1. [武器系统完整类继承图谱](#1-武器系统完整类继承图谱)
2. [每个基类的职责说明](#2-每个基类的职责说明)
3. [ShootWeaponEntity 组件属性与运行时可写属性清单](#3-shootweaponentity-组件属性与运行时可写属性清单)
4. [弹药系统](#4-弹药系统)
5. [配件系统](#5-配件系统)
6. [投掷物系统](#6-投掷物系统)
7. [近战武器系统](#7-近战武器系统)
8. [载具武器系统](#8-载具武器系统)
9. [武器装备系统](#9-武器装备系统avatarequipment)
10. [武器HUD模块](#10-武器hud模块)
11. [技能武器系统](#11-技能武器系统)
12. [文件目录索引](#12-文件目录索引)

---

## 1. 武器系统完整类继承图谱

### 1.1 射击武器（Shoot Weapon）继承树

```
AUGCShootWeapon (C++ 引擎基类)
└── BP_UGC_ShootWeaponLogicBase_C  ← 武器逻辑基类
    ├── BP_UGC_ShootWeaponBase_C  ← 旧版射击武器基类
    │   ├── BP_UGC_ShotGunBase_C  ← 霰弹枪基类
    │   │   └── (具体霰弹枪武器)
    │   ├── BP_UGC_ShootPistol_Base_C  ← 手枪基类
    │   │   ├── BP_UGC_Pistol_Flaregun_C  ← 信号枪
    │   │   └── (其他手枪武器)
    │   ├── BP_UGC_Other_MG3_C  ← MG3 通用机枪
    │   ├── BP_UGC_Other_DP28_C  ← DP28 轻机枪
    │   ├── BP_UGC_Sniper_M1Garand_C  ← M1 加兰德狙击步枪
    │   ├── BP_UGC_Other_M134_C  ← M134 加特林（含预热状态）
    │   ├── BP_UGC_Other_CrossBow_C  ← 十字弩
    │   └── (其他继承 ShootWeaponBase 的武器)
    ├── BP_UGC_ShootWeaponNewBase_C  ← 新版射击武器基类
    │   └── (新版武器，使用 C++ 组件版本)
    ├── BP_UGC_ShootWeaponProjectileBase_C  ← 投射物武器基类
    │   ├── BP_UGC_Other_RPG7_C  ← RPG-7 火箭筒
    │   ├── BP_UGC_Other_SawedOffM79_C  ← M79 榴弹发射器
    │   └── (其他投射物类武器)
    ├── BP_UGC_ShootWeaponBowBase_C  ← 弓箭武器基类
    │   └── (弓箭类武器)
    └── BP_UGC_Other_M3E1_Base_C  ← M3E1（直接继承 LogicBase）
```

### 1.2 盾牌武器继承树

```
AUGCWeaponShield (C++ 引擎基类)
└── BP_UGC_ShieldWeaponBase_C  ← 盾牌武器基类
    └── (具体盾牌武器)
```

### 1.3 近战武器继承树

```
AUGCSTExtraWeapon_Throw (C++ 引擎基类)
├── BP_UGC_Melee_WEP_Base_C  ← 近战武器基类
│   ├── BP_UGC_MeleeWeap_Crowbar_C  ← 撬棍
│   ├── BP_UGC_MeleeWeap_Machete_C  ← 砍刀
│   └── BP_UGC_MeleeWeap_Sickle_C  ← 镰刀
└── BP_UGC_DragonBoySpear_C  ← 龙 boy 长矛（直接继承引擎基类）
```

### 1.4 载具武器继承树

```
AUGCVehicleShootWeapon (C++ 引擎基类)
└── BP_UGC_VehicleShootWeapon_C  ← 载具射击武器基类
    └── (具体载具射击武器)

BP_UGC_VehGatlin_C (C++ 中间基类)
├── BP_UGC_VehGatlin_Dacia_C  ← 达契亚车载机枪
├── BP_UGC_VehGatlin_Pickup_C  ← 皮卡车载机枪
├── BP_UGC_VehGatlin_UAZ_C  ← UAZ 载机枪
└── BP_UGC_VehGatlin_Buggy_C  ← 越野车载机枪

BP_UGC_VehicleFireLauncherR_C (C++ 中间基类)
└── BP_UGC_VehicleFireLauncherL_C  ← 载具火箭发射器（左）
```

### 1.5 武器 ItemHandle 继承树

```
UGCBackpackShootWeaponHandle_BP_C (C++ 基类)
├── Template_Handle_C  ← 通用武器 ItemHandle 模板
├── Template_Sniper_Garand_C  ← M1 Garand 武器 Handle
├── Template_Other_MG36_C  ← MG36 武器 Handle
├── Template_Other_M202_C  ← M202 武器 Handle
├── Template_Rifle_ARX200_C  ← ARX200 武器 Handle
└── Template_Other_SIG_M338_C  ← SIG M338 武器 Handle

BP_UGC_BattleItemHandle_MeleeWeapon_C (C++ 近战武器 Handle 基类)
├── Template_Melee_TangDao_Handle_C  ← 唐刀 Handle
└── Template_Melee_BoxingGloves_C  ← 拳击手套 Handle
```

---

## 2. 每个基类的职责说明

### 2.1 BP_UGC_ShootWeaponLogicBase_C — 武器逻辑核心基类

**父类**: `AUGCShootWeapon`（C++ 引擎类）

**职责**: 所有射击武器的最底层 Lua 逻辑封装，提供弹匣管理、属性修改器、骨骼显隐、载具交互、弹药查询等核心功能。

**核心属性**:

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `AttrModifyConfig` | `ULuaArrayHelper` | 属性修改器配置列表 |
| `AttrModifyIDs` | `ULuaArrayHelper` | 属性修改器 ID 列表 |
| `bUseIdleAnim` | `bool` | 是否使用待机动画 |
| `HideBoneList` | `ULuaArrayHelper` | 换弹时需隐藏的骨骼列表 |
| `AlertMag` | `bool` | 弹匣告警 |
| `bReloadMagOutAttach` | `bool` | 换弹弹匣脱离时是否附加到手部 |
| `bReloadMagOutAttachWithAdditionalWeapon` | `bool` | 副武器存在时弹匣脱离附加 |
| `Fov` | `float` | 武器视角 |
| `normalShotVoiceDis` | `float` | 普通射击声音传播距离 |
| `SlienceShotVoiceDis` | `float` | 消音射击声音传播距离 |
| `TotalCount` | `int32` | 总弹药计数 |
| `MagCompAttachSocket` | `FName` | 弹匣组件挂载 Socket |
| `MagSocketName` | `FName` | 弹匣 Socket 名称 |
| `BulletTrackRef` | `UBulletTrackComponent` | 弹道追踪组件引用 |
| `CrossHairRef` | `UCrossHairComponent` | 准星组件引用 |
| `MagComp` | `UMeshComponent` | 弹匣网格组件 |
| `ShootWeaponEffectRef` | `UShootWeaponEffectComponent` | 射击特效组件引用 |
| `ShootWeaponEntityRef` | `UShootWeaponEntity` | 武器实体组件引用 |
| `ShootWeaponStateManagerRef` | `UShootWeaponStateManager` | 武器状态管理器引用 |
| `ReloadEndReverseShowBoneDelayTime` | `float` | 换弹结束延迟显骨时间 |
| `ReloadStartHideBoneDelayTime` | `float` | 换弹开始延迟隐骨时间 |

**核心方法**:

| 方法名 | 返回值 | 说明 |
|--------|--------|------|
| `BP_OnWeaponReloadEnd()` | void | 换弹结束回调 |
| `BP_OnWeaponReloadStart()` | void | 换弹开始回调 |
| `BP_PawnAttachMesh()` | `UMeshComponent` | 获取角色附着的网格 |
| `BeginRegReloadEvent()` | void | 注册换弹事件 |
| `OnWeaponMagOut()` | void | 弹匣弹出事件 |
| `OnWeaponMagIn()` | void | 弹匣装入事件 |
| `BlueprintSetWeaponAttrModifierEnable_Internal(AttrModifierID, bNewEnable)` | void | 设置属性修改器启用状态 |
| `BlueprintClearWeaponAttrModifier_Internal()` | void | 清除所有属性修改器 |
| `OnWeaponMagDropDown()` | bool | 弹匣掉落事件 |
| `OnHideBones()` / `OnShowBones()` | void | 隐藏/显示骨骼 |
| `TryGetMagComp()` | `UMeshComponent` | 尝试获取弹匣组件 |
| `GetReloadMagOutAttach()` | bool | 获取换弹弹匣脱离附加状态 |
| `HandlePlayerEnterOrLeaveVehicle(Vehicle, bEnter)` | void | 玩家进入/离开载具回调 |
| `GetBulletNumFromBackpack()` | int32 | 从背包获取弹药数量 |
| `GetLuaModule()` | FString | 获取 Lua 模块名 |
| `PlayLocalShellDropFX()` | void | 播放本地弹壳掉落特效 |
| `PostGetOwnerActor(OwnerActor)` | void | 获取 Owner 后回调 |
| `ResetCamera()` | void | 重置相机 |

---

### 2.2 BP_UGC_ShootWeaponBase_C — 旧版射击武器基类

**父类**: `BP_UGC_ShootWeaponLogicBase_C`

**职责**: 旧版射击武器的完整实现，包含完整的武器状态机（Fire/Idle/Inactive/NoBullet/Reload/Default）、弹匣掉落动画系统、射击特效、弹道追踪等。使用 Blueprint 版本的组件（`BP_BulletTrackComponent`、`BP_BulletHitInfoUploadComponent`、`BP_ShootWeaponStateManager`）。

**额外属性**:

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `BP_WeaponInspectComponent` | `BP_WeaponInspectComponent_C` | 武器检视组件 |
| `AlwaysReloadMagDropDown` | `bool` | 始终启用弹匣掉落 |
| `MagDropDownEnable` | `bool` | 弹匣掉落功能启用 |
| `Fov_0` | `float` | 武器 FOV（冗余字段） |
| `MagDropDownDelay` | `float` | 弹匣掉落延迟 |
| `MagDropDownDelayWithAdditionalWeapon` | `float` | 有副武器时弹匣掉落延迟 |
| `MagDropDownHideDelay` | `float` | 弹匣掉落隐藏延迟 |
| `MagInShownDelay` | `float` | 弹匣装入显示延迟 |
| `MagInShownDelayTactical` | `float` | 战术换弹弹匣装入延迟 |
| `normalShotVoiceDis_0` | `float` | 射击声音距离（冗余） |
| `SlienceShotVoiceDis_0` | `float` | 消音射击距离（冗余） |
| `BP_BulletTrackComponent` | `BP_BulletTrackComponent_C` | 弹道追踪组件（BP版） |
| `BP_ShootProjectComponent` | `BP_ShootProjectComponent_C` | 射击投射组件 |
| `BP_WeaponDynamicAnimListManager` | `BP_WeaponDynamicAnimListManager_C` | 动态动画列表管理器 |
| `BulletHitInfoUpload` | `BP_BulletHitInfoUploadComponent_C` | 弹道命中信息上传组件 |
| `CrossHair` | `UCrossHairComponent` | 准星组件 |
| `DropDownMag` | `DropDownWeaponMag_C` | 弹匣掉落 Actor |
| `FireWeaponState` | `UFireWeaponState` | 射击状态 |
| `IdleWeaponState` | `UIdleWeaponState` | 待机状态 |
| `InactiveWeaponState` | `UInactiveWeaponState` | 未激活状态 |
| `NoBulletWeaponState` | `UNoBulletWeaponState` | 无弹状态 |
| `ReloadWeaponState` | `UReloadWeaponState` | 换弹状态 |
| `ShootWeaponEffect` | `UShootWeaponEffectComponent` | 射击特效组件 |
| `ShootWeaponEntity` | `UShootWeaponEntity` | 武器实体组件 |
| `ShootWeaponStateManager` | `BP_ShootWeaponStateManager_C` | 武器状态管理器（BP版） |
| `WeaponStateDefault` | `UWeaponStateDefault` | 默认武器状态 |
| `DropDownMagTimerHandle` | `FTimerHandle` | 弹匣掉落计时器 |
| `MagDropDownOffset` | `FVector` | 弹匣掉落偏移 |
| `MagDropDownOffsetWithAdditionalWeapon` | `FVector` | 有副武器时弹匣掉落偏移 |

---

### 2.3 BP_UGC_ShootWeaponNewBase_C — 新版射击武器基类

**父类**: `BP_UGC_ShootWeaponLogicBase_C`

**职责**: 与旧版功能类似，但使用 C++ 原生组件替代 Blueprint 组件版本。关键差异：
- 使用 `UFireWeaponNewState` 替代 `UFireWeaponState`
- 使用 `UBulletHitInfoUploadComponent` 替代 `BP_BulletHitInfoUploadComponent`
- 使用 `UBulletTrackComponent` 替代 `BP_BulletTrackComponent`
- 使用 `UShootWeaponStateManager` 替代 `BP_ShootWeaponStateManager`
- **移除了** `MagDropDownDelayWithAdditionalWeapon` 和 `MagInShownDelayTactical` 字段

---

### 2.4 BP_UGC_ShootWeaponProjectileBase_C — 投射物武器基类

**父类**: `BP_UGC_ShootWeaponLogicBase_C`

**职责**: 发射投射物（火箭弹、榴弹等）的武器基类。持有 `WeaponAvatarComponent`、`AttrModifierCompoment`、`RootComponent` 三个通用组件引用。此类直接继承 LogicBase，不经过 ShootWeaponBase，因为投射物武器不需要弹匣掉落动画等射击武器特有的功能。

---

### 2.5 BP_UGC_ShootWeaponBowBase_C — 弓箭武器基类

**父类**: `BP_UGC_ShootWeaponLogicBase_C`

**职责**: 弓箭类武器专用基类。关键特性：
- 使用 `UBowEnergyBulletTrackComponent` 追踪弓箭能量弹道
- 支持 `NeedAcc` 蓄力瞄准机制
- 支持 `ModifierName` 动态属性修改器名称
- 包含完整的武器状态机

**独有方法**:

| 方法名 | 说明 |
|--------|------|
| `BowHandleWeaponChangeState(LastState, NewState)` | 弓箭状态切换处理 |
| `NeedAccPrepare(bNewEnable)` | 蓄力瞄准准备 |
| `SetCharacterAttrModifier(ModifierName, IsEnable)` | 设置角色属性修改器 |
| `SetCharacterAttrModifiers(ModifierNames, bNewEnable)` | 批量设置角色属性修改器 |

---

### 2.6 BP_UGC_ShieldWeaponBase_C — 盾牌武器基类

**父类**: `AUGCWeaponShield`（C++ 引擎基类）

**职责**: 防御性盾牌武器。持有 `WeaponStateDefault`、`WeaponEntity`、`WeaponStateManager` 三个核心组件。不继承射击武器链，是独立的武器类型。

**独有方法**:

| 方法名 | 说明 |
|--------|------|
| `CheckIsEnableVaultHolding(VaultKey)` | 检查是否允许在攀爬/翻越时保持持盾 |

---

### 2.7 BP_UGC_ShotGunBase_C — 霰弹枪基类

**父类**: `BP_UGC_ShootWeaponBase_C`

**职责**: 霰弹枪专用基类，增加音效系统、第一人称视角偏移、伤害类型配置、武器装饰组件。

**额外属性**:

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `VoiceCheckDis` | `float` | 射击声音检测距离 |
| `SilenceVoiceCheckDis` | `float` | 消音射击声音检测距离 |
| `BulletFlySound` | `UObject` | 弹丸飞行音效 |
| `LoadBulletSound` | `UObject` | 装弹音效 |
| `MagazineINSound` | `UObject` | 弹匣装入音效 |
| `MagazineOUTSound` | `UObject` | 弹匣弹出音效 |
| `PullBoltSound` | `UObject` | 拉栓音效 |
| `OffsetFPPCrouchRotation` | `FRotator` | 蹲伏时第一人称旋转偏移 |
| `OffsetFPPProneRotation` | `FRotator` | 趴下时第一人称旋转偏移 |
| `DamageTypeConfig` | `FRestrictedDamageTypeData` | 伤害类型配置 |
| `FPPWeaponOffset` | `FTransform` | 第一人称武器位置偏移 |
| `FPPWeaponOffsetNonShooting` | `FTransform` | 非射击时武器位置偏移 |
| `FPPWeaponOffsetSprint` | `FTransform` | 冲刺时武器位置偏移 |
| `WeaponAvatarComponent` | `UObject` | 武器外观组件 |
| `AttrModifierCompoment` | `UObject` | 属性修改器组件 |
| `WeaponAttrModifyConfigList` | `ULuaArrayHelper` | 武器属性修改器配置列表 |

---

### 2.8 BP_UGC_ShootPistol_Base_C — 手枪基类

**父类**: `BP_UGC_ShootWeaponBase_C`

**职责**: 手枪专用基类，增加手枪特有的动画层、攀爬翻越支持、弹匣掉落检查等。

**独有方法**:

| 方法名 | 返回值 | 说明 |
|--------|--------|------|
| `GetOverrideWeaponAnimComponent()` | `UUAECharAnimListCompBase` | 获取覆盖的武器动画组件 |
| `IsEnableVaultHolding(VaultKey)` | bool | 检查攀爬/翻越时是否保持持枪 |
| `CheckEnableMagDropDown()` | bool | 检查弹匣掉落是否启用 |
| `GetWeaponAnimLayer()` | `EAnimLayerType` | 获取武器动画层类型 |
| `GetMagInShownDelayTime()` | float | 获取弹匣装入显示延迟 |
| `ReloadStateCheck(bManual)` | bool | 换弹状态检查 |

---

## 3. ShootWeaponEntity 组件属性与运行时可写属性清单

`UShootWeaponEntity` 是武器系统的核心运行时组件，承载武器的全部状态数据。

### 3.1 从各基类中提取的 ShootWeaponEntity 相关引用

| 所属基类 | 引用字段名 | 组件类型 |
|----------|-----------|----------|
| `ShootWeaponLogicBase` | `ShootWeaponEntityRef` | `UShootWeaponEntity` |
| `ShootWeaponBase` | `ShootWeaponEntity` | `UShootWeaponEntity` |
| `ShootWeaponNewBase` | `ShootWeaponEntity` | `UShootWeaponEntity` |
| `ShootWeaponBowBase` | `ShootWeaponEntity` | `UShootWeaponEntity` |

### 3.2 武器状态管理组件

| 组件名 | 类型 | 说明 |
|--------|------|------|
| `ShootWeaponStateManager` / `ShootWeaponStateManagerRef` | `UShootWeaponStateManager` / `BP_ShootWeaponStateManager_C` | 管理武器状态切换 |
| `WeaponStateDefault` | `UWeaponStateDefault` | 默认状态（Idle 入口） |
| `IdleWeaponState` | `UIdleWeaponState` | 待机状态 |
| `FireWeaponState` | `UFireWeaponState` | 射击状态 |
| `ReloadWeaponState` | `UReloadWeaponState` | 换弹状态 |
| `NoBulletWeaponState` | `UNoBulletWeaponState` | 无弹状态 |
| `InactiveWeaponState` | `UInactiveWeaponState` | 未激活状态 |
| `WeaponWarmUpState` | `UWeaponWarmUpState` | 预热状态（M134等） |

### 3.3 武器状态枚举 `EFreshWeaponStateType`

武器状态通过 `HandleWeaponChangeState(LastState, NewState)` 进行切换。HUD 模块监听此事件来刷新 UI。

### 3.4 武器特效与视觉组件

| 组件名 | 类型 | 说明 |
|--------|------|------|
| `ShootWeaponEffect` | `UShootWeaponEffectComponent` | 射击特效（枪口火焰、弹壳等） |
| `CrossHair` | `UCrossHairComponent` | 准星组件 |
| `DropDownMag` | `DropDownWeaponMag_C` | 可掉落弹匣 Actor |
| `BP_WeaponDynamicAnimListManager` | `BP_WeaponDynamicAnimListManager_C` | 动态动画列表管理器 |

### 3.5 弹道与命中组件

| 组件名 | 类型 | 说明 |
|--------|------|------|
| `BulletTrackRef` / `BP_BulletTrackComponent` | `UBulletTrackComponent` / `BP_BulletTrackComponent_C` | 弹道追踪 |
| `BulletHitInfoUpload` | `BP_BulletHitInfoUploadComponent_C` / `UBulletHitInfoUploadComponent` | 弹道命中信息上报 |
| `BowEnergyBulletTrack` | `UBowEnergyBulletTrackComponent` | 弓箭能量弹道追踪 |
| `BP_ShootProjectComponent` | `BP_ShootProjectComponent_C` | 射击投射组件 |

### 3.6 武器装饰组件

| 组件名 | 类型 | 说明 |
|--------|------|------|
| `WeaponAvatarComponent` | `UObject` | 武器外观装饰 |
| `AttrModifierCompoment` | `UObject` | 属性修改器组件 |
| `BP_WeaponInspectComponent` | `BP_WeaponInspectComponent_C` | 武器检视组件 |
| `RootComponent` | `UObject` | 根组件 |

---

## 4. 弹药系统

### 4.1 ItemHandle 基础结构

#### 弹药基类 `Template_BulletBase_ItemHandle_C`

**父类**: `UUGCBattleItemHandleBase`

```lua
---@class Template_BulletBase_ItemHandle_C:UUGCBattleItemHandleBase
---@field UGCWrapperClass UObject
---@field OrderWeight int32
---@field RecommendPickCount int32
---@field CanUse bool
---@field DeadDropItemType EDeadDropItemType
---@field PickUpSound FString
---@field PickUpBank FString
---@field DropSound FString
---@field DropBank FString
```

**方法**:

| 方法名 | 返回值 | 说明 |
|--------|--------|------|
| `UGC_GetItemType()` | int32 | 获取物品类型 |
| `UGC_GetItemSubType()` | int32 | 获取物品子类型 |
| `CreateWrapperOnGround(Count, Reason)` | void | 在地面创建包装物 |
| `HandleDrop(InCount, Reason)` | bool | 处理丢弃逻辑 |
| `HandlePickup(ItemContainer, PickupInfo, Reason)` | bool | 处理拾取逻辑 |

### 4.2 具体弹药类型字段结构

所有具体弹药类型均继承 `Template_BulletBase_ItemHandle_C`，共享以下字段模板：

```lua
---@field ItemID int32              -- 物品 ID（内置 ID）
---@field ItemName FString          -- 弹药显示名称
---@field MaxNumberOfStacks int32   -- 最大堆叠数量（部分弹药无此字段）
---@field IconTexture FSoftObjectPath  -- 图标纹理路径
---@field ItemDetail FString        -- 物品详细描述
---@field PickupDetail FString      -- 拾取提示文本
---@field Tags ULuaArrayHelper      -- 标签列表
---@field PickupWrapperMesh FSoftObjectPath  -- 拾取包装网格
---@field UnitWeightConfig float    -- 单位重量配置
---@field WeightforOrder int32      -- 排序权重
```

部分弹药还包含额外字段：
- `ReloadID int32` — 换弹 ID（用于换弹动画/逻辑关联）
- `PickUpSound / PickUpBank / DropSound / DropBank` — 音效相关

### 4.3 BulletType 赋值链路

```
武器蓝图 → ShootWeaponEntity.BulletType → 弹道系统
                                         ↑
Ammo ItemHandle → ItemID → BulletID (通过 Template_Handle_C.BulletID 关联)
```

武器 ItemHandle（如 `Template_Handle_C`）通过 `BulletID` 字段与弹药 ItemHandle 关联：

```lua
---@class Template_Handle_C:UGCBackpackShootWeaponHandle_BP_C
---@field BulletID int32            -- 关联的弹药 ID
---@field PickupBulletNum int32     -- 拾取时的弹药数量
```

### 4.4 内置弹药 ID 映射表

| 弹药类型 | Lua 类名 | 用途 | 备注 |
|----------|----------|------|------|
| 9mm | `Template_9mm_ItemHandle_C` | 手枪/冲锋枪 | 最常见弹药 |
| 5.56mm | `Template_556mm_ItemHandle_C` | 步枪/机枪 | 标准步枪弹 |
| 7.62mm | `Template_762mm_ItemHandle_C` | 步枪/狙击枪 | 大口径步枪弹 |
| .45 ACP | `Template_45ACP_ItemHandle_C` | 手枪 | .45口径手枪弹 |
| 5.7mm | `Template_57mm_ItemHandle_C` | 冲锋枪 | 5.7×28mm |
| 12 Guage | `Template_12Guage_ItemHandle_C` | 霰弹枪 | 12号霰弹 |
| .300 Magnum | `Template_300Magnum_ItemHandle_C` | 狙击枪 | .300 Win Mag |
| .338 Magnum | `Template_338Magnum_ItemHandle_C` | 狙击枪 | .338 Lapua Mag |
| .408 CT | `Template_408CT_ItemHandle_C` | 狙击枪 | .408 CheyTac |
| .50 BMG | `Template_50BMG_ItemHandle_C` | 反器材狙击枪 | 12.7mm |
| 40mm | `Template_40mm_ItemHandle_C` | 榴弹发射器 | M79/MGL 用 |
| 57mm | `Template_57mm_ItemHandle_C` | 特殊武器 | — |
| 箭矢 | `Template_BoltBulletBig_ItemHandle_C` | 十字弩 | — |
| 火焰箭矢 | `Template_BoltBulletBigFire_ItemHandle_C` | 十字弩（燃烧） | 带燃烧 Buff |
| 毒箭矢 | `Template_BoltBulletBigPoison_ItemHandle_C` | 十字弩（毒） | 带中毒 Buff |
| 信号弹 | `Template_FlareAmmo_ItemHandle_C` | 信号枪 | — |
| 充能步枪弹 | `Template_ChargeRifleBullet_ItemHandle_C` | 充能步枪 | — |
| 电磁弹 | `Template_Eletric_ItemHandle_C` | 电磁枪 | — |
| 激光弹 | `Template_Laser_ItemHandle_C` | 激光枪 | — |
| 火焰发射器弹 | `Template_FireLauncher_ItemHandle_C` | 火焰发射器 | — |
| RPG 弹药箱 | `Template_RPGBox_ItemHandle_C` | RPG-7 | — |
| UGC MGL 弹药 | `Template_UGCMGL_ItemHandle_C` | UGC 榴弹发射器 | — |
| 医疗弹 | `Template_MedicalBullet_ItemHandle_C` | 医疗枪（CG035） | 非致命弹药 |

---

## 5. 配件系统

### 5.1 配件基类

所有武器配件均继承自 `BP_UGC_BattleItemHandle_WeapAttachment_C`。

**通用字段结构**:

```lua
---@field ItemID int32                        -- 物品 ID
---@field ItemName FString                    -- 显示名称
---@field MaxNumberOfStacks int32             -- 最大堆叠数
---@field IconTexture FSoftObjectPath         -- 图标路径
---@field CanUse bool                         -- 是否可用
---@field ItemDetail FString                  -- 物品描述
---@field PickupDetail FString                -- 拾取提示
---@field BackpackSimple FString              -- 背包简述
---@field Tags ULuaArrayHelper                -- 标签
---@field PickupWrapperMesh FSoftObjectPath   -- 拾取包装网格
---@field UnitWeightConfig float              -- 单位重量
---@field WeightforOrder int32               -- 排序权重
---@field PickUpSound / PickUpBank FString    -- 拾取音效
---@field DropSound / DropBank FString        -- 丢弃音效
---@field EquipSound / EquipBank FString      -- 装备音效
---@field UnEquipSound / UnEquipBank FString  -- 卸下音效
---@field ReloadID int32                      -- 换弹 ID
---@field DeadDropItemType EDeadDropItemType   -- 死亡掉落类型
---@field WeaponAttachmentConfig FWeaponAttachmentConfig  -- 配件配置
---@field AttrModifyConfigs_Weapon ULuaArrayHelper        -- 武器属性修改配置
---@field SpecialWeaponAttachmentAttrByGameplayTag ULuaMapHelper  -- 特殊属性映射
---@field DefineID FItemDefineID              -- 物品定义 ID
```

### 5.2 配件类型分类

#### DJ — 弹夹（Magazine）

| 类名 | 说明 | 配件尺寸 |
|------|------|----------|
| `BP_UGC_DJ_Large_E_C` | 大型弹夹 - E 型 | Large |
| `BP_UGC_DJ_Large_EQ_C` | 大型弹夹 - EQ 型 | Large |
| `BP_UGC_DJ_Large_Q_C` | 大型弹夹 - Q 型 | Large |
| `BP_UGC_DJ_Large_Q_New_C` | 大型弹夹 - Q 型（新版） | Large |
| `BP_UGC_DJ_Large_E_New_C` | 大型弹夹 - E 型（新版） | Large |
| `BP_UGC_DJ_Mid_E_C` | 中型弹夹 - E 型 | Mid |
| `BP_UGC_DJ_Mid_Q_C` | 中型弹夹 - Q 型 | Mid |
| `BP_UGC_DJ_Small_E_C` | 小型弹夹 - E 型 | Small |
| `BP_UGC_DJ_Small_EQ_C` | 小型弹夹 - EQ 型 | Small |
| `BP_UGC_DJ_Small_Q_C` | 小型弹夹 - Q 型 | Small |
| `BP_UGC_DJ_Sniper_E_C` | 狙击枪弹夹 - E 型 | Sniper |
| `BP_UGC_DJ_ShotGun_C` | 霰弹枪弹夹 | Shotgun |

#### MZJ — 瞄准镜（Scope / Sight）

| 类名 | 说明 |
|------|------|
| `BP_UGC_MZJ_6X_C` | 6 倍瞄准镜 |
| `BP_UGC_MZJ_8X_C` | 8 倍瞄准镜 |
| `BP_UGC_MZJ_SideRMR_C` | 侧边 RMR 红点瞄准镜 |

#### QK — 枪口（Muzzle）

| 类名 | 说明 |
|------|------|
| `BP_UGC_Muzzle_Template_C` | 枪口配件模板（消音器/补偿器/消焰器通用） |

#### WB — 握把（Grip）

| 类名 | 说明 |
|------|------|
| `BP_UGC_WB_Vertical_C` | 垂直握把 |
| `BP_UGC_WB_Angled_C` | 倾斜握把 |
| `BP_UGC_WB_LightGrip_C` | 轻型握把 |

#### ZDD — 子弹带（Drum Magazine / Extended Magazine）

| 类名 | 说明 |
|------|------|
| `BP_UGC_ZDD_Shotgun_C` | 霰弹枪弹鼓 |

#### QT — 枪托（Stock）

| 类名 | 说明 |
|------|------|
| `BP_UGC_QT_A_C` | A 型枪托 |
| `BP_UGC_QT_Sniper_C` | 狙击枪专用枪托 |

### 5.3 配件模板基类

| 模板类名 | 对应槽位 | 说明 |
|----------|----------|------|
| `BP_UGC_Muzzle_Template_C` | 枪口 (QK) | 消音器/补偿器/消焰器模板 |
| `BP_UGC_Scope_Template_C` | 瞄准镜 (MZJ) | 全息/红点/倍镜模板 |
| `BP_UGC_Stock_Template_C` | 枪托 (QT) | 枪托模板 |
| `BP_UGC_Grip_Template_C` | 握把 (WB) | 握把模板 |
| `BP_UGC_Mag_Template_C` | 弹夹 (DJ) | 弹夹模板，含 `animBPClass_FPP` |
| `BP_UGC_SideRMR_Template_C` | 侧瞄准 (SideRMR) | 侧面红点模板 |

### 5.4 配件挂载槽位说明

| 槽位代号 | 中文名 | 英文名 | 说明 |
|----------|--------|--------|------|
| DJ | 弹夹 | Magazine | 影响弹匣容量和换弹速度 |
| MZJ | 瞄准镜 | Scope/Sight | 影响瞄准倍率和视野 |
| QK | 枪口 | Muzzle | 消音/补偿/消焰 |
| WB | 握把 | Grip | 影响后坐力控制 |
| ZDD | 子弹带 | Drum Magazine | 大容量弹鼓 |
| QT | 枪托 | Stock | 影响稳定性和后坐力 |

---

## 6. 投掷物系统

### 6.1 投射物（Projectile）

#### `BP_UGCGrenade_Projectile_Template_C`

**父类**: `UUniversalProjectileBase`

**职责**: UGC 手雷投射物模板，处理投掷物的飞行、碰撞和爆炸逻辑。

```lua
---@class BP_UGCGrenade_Projectile_Template_C:UUniversalProjectileBase
---@field OldSchoolGameModeIDs ULuaArrayHelper  -- 兼容旧版模式 ID
---@field EffectScale float                      -- 特效缩放
---@field RangeScale float                       -- 范围缩放
---@field Capsule UCapsuleComponent              -- 碰撞胶囊体
---@field ExplosionFindFunction UExplosionFinder -- 爆炸查找函数
---@field ParticleSystem UParticleSystemComponent -- 粒子特效
---@field RotatingMovement URotatingMovementComponent -- 旋转运动
---@field StaticMesh UStaticMeshComponent        -- 静态网格
---@field LocationMarker ActorLocationMarker     -- 位置标记
---@field Noise FProjectileExplosionNoise        -- 爆炸噪音
---@field RadialTargetsFinder ExplosionFinderWrapper -- 径向目标查找
```

**方法**:

| 方法名 | 说明 |
|--------|------|
| `GetLuaModule()` | 获取 Lua 模块名 |
| `ReceiveProjectileExplodedEvent(Impact)` | 投射物爆炸事件回调 |
| `ReceiveProjectileStoppedEvent(HitResult)` | 投射物停止事件回调 |

### 6.2 技能投掷物（SkillThrowables）

投掷物的爆炸效果通过 Buff 系统实现：

#### 燃烧效果 `Buff_ThrowableBurn_C`

```lua
---@class Buff_ThrowableBurn_C:UPersistEffectBuff
---@field BuffInfo FPEBuffInfo    -- Buff 信息
---@field ApplyTime float         -- 持续时间
```

#### 十字弩箭矢 Buff

| 类名 | 说明 |
|------|------|
| `Buff_ArrowBurn_C` | 燃烧箭矢效果 |
| `Buff_ArrowPoison_C` | 毒箭矢效果 |

这些 Buff 均继承自 `UPersistEffectBuff`，通过 `GetLuaModule()` 返回对应的 Lua 模块名。

---

## 7. 近战武器系统

### 7.1 近战武器基类

#### `BP_UGC_Melee_WEP_Base_C`

**父类**: `AUGCSTExtraWeapon_Throw`

**职责**: 所有近战武器的基类，继承自投掷武器引擎基类（说明近战武器在引擎层面被视为一种特殊的投掷武器）。

```lua
---@class BP_UGC_Melee_WEP_Base_C:AUGCSTExtraWeapon_Throw
---@field PredictLine UObject                   -- 预判线组件
---@field WeaponAttachMeshOffset FTransform     -- 武器附着网格偏移
---@field WeaponAvatarComponent UObject         -- 武器外观组件
---@field WeaponEffectComponent UObject         -- 武器特效组件
---@field WeaponReconnectReplicateData FWeaponReconnectReplicateData  -- 重连同步数据
---@field WeaponUIType EExtraWeaponUIType       -- 武器 UI 类型
---@field AttrModifierCompoment UObject         -- 属性修改器组件
---@field RootComponent UObject                 -- 根组件
---@field ActorLabel FString                    -- Actor 标签
```

**方法**:

| 方法名 | 返回值 | 说明 |
|--------|--------|------|
| `GetSkillEntryForMeleeWeapon(IsPressed)` | `EUTSkillEntry` | 获取近战武器技能入口（按下/松开） |
| `GetSkillIndexForMeleeWeapon()` | int32 | 获取近战武器技能索引 |

### 7.2 具体近战武器

所有近战武器均继承 `BP_UGC_Melee_WEP_Base_C`，共享以下额外字段：

```lua
---@field AnimListTag FGameplayTag           -- 动画列表标签
---@field ReloadID int32                     -- 换弹 ID
---@field IconImagePathOverride FString       -- 图标路径覆盖
---@field IconPressedImagePathOverride FString -- 按下图标路径覆盖
---@field WeaponSkillConfigs ULuaArrayHelper  -- 武器技能配置
```

| 类名 | 武器名 | 文件路径 |
|------|--------|----------|
| `BP_UGC_MeleeWeap_Crowbar_C` | 撬棍 | MeleeWeapon/Crowbar/ |
| `BP_UGC_MeleeWeap_Machete_C` | 砍刀 | MeleeWeapon/Machete/ |
| `BP_UGC_MeleeWeap_Sickle_C` | 镰刀 | MeleeWeapon/Sickle/ |

### 7.3 近战武器 ItemHandle

近战武器的拾取/丢弃通过独立的 Handle 类处理：

**基类**: `BP_UGC_BattleItemHandle_MeleeWeapon_C`

| 类名 | 武器名 | 额外字段 |
|------|--------|----------|
| `Template_Melee_TangDao_Handle_C` | 唐刀 | `FPPDefaultMesh`, `FPPToTPPAnim`, `TransformOffset` |
| `Template_Melee_BoxingGloves_C` | 拳击手套 | `UnitWeightConfig`, `ParentIDList`, `GetMeleeDamageSubType()` |

### 7.4 特殊近战武器

`BP_UGC_DragonBoySpear_C`（龙 boy 长矛）直接继承 `AUGCSTExtraWeapon_Throw` 而非 `BP_UGC_Melee_WEP_Base_C`，说明它是一个独立实现的近战武器，拥有 `bHideOnUnEquip`、`WeaponSkillConfigs`、`Tags` 等额外属性。

---

## 8. 载具武器系统

### 8.1 载具射击武器基类

#### `BP_UGC_VehicleShootWeapon_C`

**父类**: `AUGCVehicleShootWeapon`

```lua
---@class BP_UGC_VehicleShootWeapon_C:AUGCVehicleShootWeapon
---@field UseFakeBulletChangeUI bool              -- 使用假弹药变化 UI
---@field FakeBulletChangeUI_MaxBulletNumInClip int32  -- 假弹药 UI 最大弹夹容量
```

**方法**:

| 方法名 | 说明 |
|--------|------|
| `ChangeSequenceStateInner(LastStateType)` | 内部状态序列切换 |
| `GetLuaModule()` | 获取 Lua 模块名 |

### 8.2 载具加特林机枪

**基类**: `BP_UGC_VehGatlin_C`（C++ 中间基类）

| 类名 | 适配载具 | 文件路径 |
|------|----------|----------|
| `BP_UGC_VehGatlin_Dacia_C` | 达契亚轿车 | VehicleWeapon/ |
| `BP_UGC_VehGatlin_Pickup_C` | 皮卡车 | VehicleWeapon/ |
| `BP_UGC_VehGatlin_UAZ_C` | UAZ 吉普车 | VehicleWeapon/ |
| `BP_UGC_VehGatlin_Buggy_C` | 越野蹦蹦 | VehicleWeapon/ |

### 8.3 载具火箭发射器

```lua
---@class BP_UGC_VehicleFireLauncherL_C:BP_UGC_VehicleFireLauncherR_C
---@field CacheSkill UObject                -- 缓存的技能引用
---@field WeaponAvatarComponent UObject     -- 武器外观组件
---@field AttrModifierCompoment UObject     -- 属性修改器组件
---@field RootComponent UObject             -- 根组件
```

继承链：`BP_UGC_VehicleFireLauncherR_C` → `BP_UGC_VehicleFireLauncherL_C`

---

## 9. 武器装备系统（AvatarEquipment）

### 9.1 背包（Bag）

**基类**: `Template_AvatarEquipment_Bag_C`

| 类名 | 等级 | 文件路径 |
|------|------|----------|
| `Template_AvatarEquipment_Bag_LV1_Handle_C` | LV1 | AvatarEquipment/Bag/ |
| `Template_AvatarEquipment_Bag_LV2_Handle_C` | LV2 | AvatarEquipment/Bag/ |
| `Template_AvatarEquipment_Bag_LV3_Handle_C` | LV3 | AvatarEquipment/Bag/ |

**字段结构**:

```lua
---@field ItemID int32                        -- 物品 ID
---@field ItemName FString                    -- 显示名称
---@field BackpackSimple FString              -- 背包简述
---@field IconTexture FSoftObjectPath         -- 图标路径
---@field ItemDetail FString                  -- 物品描述
---@field PickupDetail FString                -- 拾取提示
---@field PickupWrapperMesh FSoftObjectPath   -- 拾取包装网格
---@field WeightforOrder int32               -- 排序权重
---@field PickUpSound / PickUpBank FString    -- 拾取音效
---@field DropSound / DropBank FString        -- 丢弃音效
---@field DeadDropItemType EDeadDropItemType   -- 死亡掉落类型
---@field ReloadID int32                      -- 换弹 ID
---@field BackpackCellAttr float              -- 背包格子属性（容量加成）
---@field ItemLevel int32                     -- 物品等级
---@field meshPack FMeshPackage               -- 网格包
---@field itemCapacity int32                  -- 背包容量
```

### 9.2 护甲（Armor）

**基类**: `Template_AvatarEquipment_Armor_C`

| 类名 | 等级 | 文件路径 |
|------|------|----------|
| `Template_AvatarEquipment_Armor_LV1_Handle_C` | LV1 | AvatarEquipment/Armor/ |
| `Template_AvatarEquipment_Armor_LV2_Handle_C` | LV2 | AvatarEquipment/Armor/ |
| `Template_AvatarEquipment_Armor_LV3_Handle_C` | LV3 | AvatarEquipment/Armor/ |

**字段结构**（在背包字段基础上增加）:

```lua
---@field BodyDamageReduceAttr float           -- 身体伤害减免属性
---@field durability int32                     -- 耐久度
---@field BodyAttachmentConfig FBodyAttachmentConfig  -- 身体装饰配置
---@field bEquippable bool                     -- 是否可装备
---@field bAutoEquipAndDrop bool               -- 是否自动装备和丢弃
```

---

## 10. 武器HUD模块

### 10.1 武器 HUD 基类

#### `BP_WFM_UGC_HUD_C`

**父类**: `AWeaponFunctionModule_UGC_HUD`

**职责**: 武器功能模块的 HUD 子系统，负责武器状态 UI 的显示/隐藏控制、视角切换处理、以及与武器状态机的联动。

```lua
---@class BP_WFM_UGC_HUD_C:AWeaponFunctionModule_UGC_HUD
---@field FatalPawnStateList ULuaArrayHelper  -- 致命角色状态列表
---@field bCacheUIVisible bool               -- UI 可见性缓存
---@field bCurrentEnable bool                -- 当前是否启用
```

**方法**:

| 方法名 | 参数 | 返回值 | 说明 |
|--------|------|--------|------|
| `HandleWeaponChangeState(LastState, NewState)` | `EFreshWeaponStateType, EFreshWeaponStateType` | void | 处理武器状态切换时的 UI 更新 |
| `ToggoleUIVisible(bVisible)` | bool | void | 切换 UI 可见性 |
| `RefreshUIVisible()` | — | void | 刷新 UI 可见性 |
| `HandleViewChange(PC)` | `APlayerController` | void | 处理视角切换 |
| `OwnerPlayerHasAnyState(StateList)` | `ULuaArrayHelper` | bool | 检查所有者是否处于指定状态之一 |
| `SetEnableUI(NewEnable)` | bool | void | 设置 UI 启用状态 |
| `OnDynamicRemove()` | — | void | 动态移除回调 |
| `InitWeaponOwner(InOwnerWeapon, InOwnerActor)` | `USTExtraWeapon, AActor` | void | 初始化武器所有者 |

### 10.2 HUD 工作流程

```
武器状态切换 → HandleWeaponChangeState(LastState, NewState)
                ├── 检查 FatalPawnStateList → OwnerPlayerHasAnyState()
                ├── 刷新 UI 可见性 → RefreshUIVisible()
                └── 视角变更 → HandleViewChange(PC)
```

---

## 11. 技能武器系统

技能武器使用 `PESkillTemplate_Base_C` 作为基类，通过状态机控制技能的施放流程。

### 11.1 火焰发射器

#### `BP_SKill_FireLauncher_C`

```lua
---@class BP_SKill_FireLauncher_C:PESkillTemplate_Base_C
---@field TraceLaserEffectCompList ULuaArrayHelper
---@field TraceLaserImpactEffectCompList ULuaArrayHelper
---@field FireSound UAkAudioEvent
---@field MuzzleEffectTemplate UParticleSystem
---@field MuzzleLaserImpactTemplate UParticleSystem
---@field MuzzleLaserTemplate UParticleSystem
---@field StopFireSound UAkAudioEvent
```

### 11.2 MGL 榴弹发射器

#### `BP_Skill_MGL_C`

```lua
---@class BP_Skill_MGL_C:PESkillTemplate_Base_C
---@field PESkillSlot FGameplayTag
---@field UIInfo FPESkillUIInfo
---@field DummyActorClass UObject
---@field InnerSkillSequence ULuaArrayHelper
---@field SkillEvents ULuaArrayHelper
---@field Transitions ULuaArrayHelper
---@field PESkillEdGraph UObject
---@field StateMachineInfo ULuaArrayHelper
```

### 11.3 电磁枪

#### `BP_Skill_ElectricGun_C`

```lua
---@class BP_Skill_ElectricGun_C:PESkillTemplate_Base_C
---@field TraceLaserEffectCompList ULuaArrayHelper
---@field TraceLaserImpactEffectCompList ULuaArrayHelper
---@field FireSound UAkAudioEvent
---@field MuzzleEffectTemplate UParticleSystem
---@field MuzzleLaserImpactTemplate UParticleSystem
---@field MuzzleLaserTemplate UParticleSystem
---@field StopFireSound UAkAudioEvent
```

### 11.4 充能步枪

#### `BP_UGC_Skill_ChargeRifle_C`

```lua
---@class BP_UGC_Skill_ChargeRifle_C:PESkillTemplate_Base_C
---@field MuzzleEffectTemplate_Stage1 UParticleSystem  -- 第1阶段枪口特效
---@field MuzzleEffectTemplate_Stage2 UParticleSystem  -- 第2阶段枪口特效
---@field MuzzleEffectTemplate_Stage3 UParticleSystem  -- 第3阶段枪口特效
---@field MuzzleEffectTemplate_Stage4 UParticleSystem  -- 第4阶段枪口特效
---@field MuzzleLaserImpactTemplate UParticleSystem
---@field MuzzleLaserTemplate UParticleSystem
---@field StopFireSound / StopFireSound2 / StopFireSound3 UAkAudioEvent
```

充能步枪支持 4 阶段充能，每个阶段有独立的枪口特效和停止音效。

### 11.5 信号枪技能

#### `BP_Skill_Flaregun_C`

```lua
---@class BP_Skill_Flaregun_C:PESkillTemplate_Base_C
---@field ProjectileList ULuaArrayHelper  -- 投射物列表
---@field AirDropID float                 -- 空投 ID
---@field DropSpeed float                 -- 下落速度
```

信号枪技能负责发射信号弹并触发空投系统。

### 11.6 技能武器状态机流程

```
NewSkillState_Entry → Fire_Entry → Fire_Exit → NewSkillState_Exit
```

部分技能还有额外状态（如充能步枪的 `NewSkillState_0` ~ `NewSkillState_3`，MGL 的 `CastSkill_Entry/Exit`）。

---

## 12. 文件目录索引

### 12.1 射击武器（MainWeapon）

```
MainWeapon/
├── BP_UGC_ShootWeaponBase.lua          -- 旧版射击武器基类
├── BP_UGC_ShootWeaponNewBase.lua       -- 新版射击武器基类
├── BP_UGC_ShootWeaponLogicBase.lua     -- 武器逻辑基类
├── BP_UGC_ShootWeaponProjectileBase.lua -- 投射物武器基类
├── BP_UGC_ShootWeaponBowBase.lua       -- 弓箭武器基类
├── BP_UGC_ShieldWeaponBase.lua         -- 盾牌武器基类
├── Template_Handle.lua                 -- 武器 ItemHandle 模板
├── MachineGun/
│   ├── P90/BP_UGC_MachineGun_P90.lua   -- P90 冲锋枪
│   └── M134/BP_UGC_Other_M134.lua      -- M134 加特林
├── Pistol/
│   ├── BP_UGC_ShootPistol_Base.lua     -- 手枪基类
│   └── Flaregun/
│       ├── BP_UGC_Pistol_Flaregun.lua  -- 信号枪
│       ├── BP_Skill_Flaregun.lua       -- 信号枪技能
│       ├── BP_SkillPassive_Flaregun.lua -- 信号枪被动技能
│       └── BP_Skill_Flaregun_Anim.lua  -- 信号枪动画
├── ShotGun/
│   └── BP_UGC_ShotGunBase.lua          -- 霰弹枪基类
├── Sniper/
│   └── M1Garand/
│       ├── BP_UGC_Sniper_M1Garand.lua  -- M1 加兰德
│       └── Template_Sniper_Garand.lua  -- M1 Garand Handle
├── Rifle/
│   └── ARX200/Template_Rifle_ARX200.lua -- ARX200 Handle
├── Other/
│   ├── MG3/BP_UGC_Other_MG3.lua        -- MG3 通用机枪
│   ├── DP28/BP_UGC_Other_DP28.lua      -- DP28 轻机枪
│   ├── CrossBow/BP_UGC_Other_CrossBow.lua -- 十字弩
│   ├── CrossbowBorderland/
│   │   ├── Buff_ArrowBurn.lua          -- 燃烧箭矢 Buff
│   │   └── Buff_ArrowPoison.lua        -- 毒箭矢 Buff
│   ├── RPG7/BP_UGC_Other_RPG7.lua      -- RPG-7
│   ├── M79/BP_UGC_Other_SawedOffM79.lua -- M79 榴弹发射器
│   ├── M3E1/BP_UGC_Other_M3E1_Base.lua -- M3E1 基类
│   ├── MG36/Template_Other_MG36.lua    -- MG36 Handle
│   └── M202/Template_Other_M202.lua    -- M202 Handle
├── CG036/
│   └── SIG_M338/Template_Other_SIG_M338.lua -- SIG M338 Handle
└── SkillShootWeapon/
    ├── FireLauncher/BP_SKill_FireLauncher.lua -- 火焰发射器技能
    ├── ElectircGun/BP_Skill_ElectricGun.lua   -- 电磁枪技能
    ├── MGL/BP_Skill_MGL.lua                  -- MGL 榴弹技能
    └── ChargedRifle/BP_UGC_Skill_ChargeRifle.lua -- 充能步枪技能
```

### 12.2 弹药（Ammo）

```
Ammo/
├── Template_BulletBase_ItemHandle.lua   -- 弹药基类
├── Template_9mm_ItemHandle.lua          -- 9mm
├── Template_556mm_ItemHandle.lua        -- 5.56mm
├── Template_762mm_ItemHandle.lua        -- 7.62mm
├── Template_45ACP_ItemHandle.lua        -- .45 ACP
├── Template_57mm_ItemHandle.lua         -- 5.7mm
├── Template_12Guage_ItemHandle.lua      -- 12 Guage
├── Template_300Magnum_ItemHandle.lua    -- .300 Magnum
├── Template_40mm_ItemHandle.lua         -- 40mm
├── Template_50BMG_ItemHandle.lua        -- .50 BMG
├── Template_408CT_ItemHandle.lua        -- .408 CT
├── Template_BoltBulletBig_ItemHandle.lua      -- 箭矢
├── Template_BoltBulletBigFire_ItemHandle.lua  -- 火焰箭矢
├── Template_BoltBulletBigPoison_ItemHandle.lua -- 毒箭矢
├── Template_ChargeRifleBullet_ItemHandle.lua  -- 充能步枪弹
├── Template_Eletric_ItemHandle.lua      -- 电磁弹
├── Template_Laser_ItemHandle.lua        -- 激光弹
├── Template_FireLauncher_ItemHandle.lua -- 火焰发射器弹
├── Template_RPGBox_ItemHandle.lua       -- RPG 弹药
├── Template_UGCMGL_ItemHandle.lua       -- UGC MGL 弹药
├── CG035/Template_MedicalBullet_ItemHandle.lua -- 医疗弹
├── CG036/Template_338Magnum_ItemHandle.lua     -- .338 Magnum
└── CG037/Template_FlareAmmo_ItemHandle.lua     -- 信号弹
```

### 12.3 配件（Attachments）

```
Attachments/
├── DJ/  (弹夹 Magazine)
│   ├── BP_UGC_DJ_Large_E.lua / _E_New.lua
│   ├── BP_UGC_DJ_Large_EQ_New.lua
│   ├── BP_UGC_DJ_Large_Q.lua / _Q_New.lua
│   ├── BP_UGC_DJ_Mid_E.lua / _Q.lua
│   ├── BP_UGC_DJ_Small_E.lua / _EQ.lua / _Q.lua
│   ├── BP_UGC_DJ_Sniper_E.lua
│   └── BP_UGC_DJ_ShotGun.lua
├── MZJ/ (瞄准镜 Scope)
│   ├── BP_UGC_MZJ_6X.lua
│   ├── BP_UGC_MZJ_8X.lua
│   └── BP_UGC_MZJ_SideRMR.lua
├── WB/  (握把 Grip)
│   ├── BP_UGC_WB_Angled.lua
│   ├── BP_UGC_WB_Vertical.lua
│   └── BP_UGC_WB_LightGrip.lua
├── ZDD/ (子弹带 Drum Magazine)
│   └── BP_UGC_ZDD_Shotgun.lua
├── QT/  (枪托 Stock)
│   ├── BP_UGC_QT_A.lua
│   └── BP_UGC_QT_Sniper.lua
└── TemplateAttachments/ (模板)
    ├── BP_UGC_Muzzle_Template.lua
    ├── BP_UGC_Scope_Template.lua
    ├── BP_UGC_Stock_Template.lua
    ├── BP_UGC_Grip_Template.lua
    ├── BP_UGC_Mag_Template.lua
    └── BP_UGC_SideRMR_Template.lua
```

### 12.4 其他子系统

```
MeleeWeapon/
├── BP_UGC_Melee_WEP_Base.lua           -- 近战武器基类
├── Crowbar/BP_UGC_MeleeWeap_Crowbar.lua
├── Machete/BP_UGC_MeleeWeap_Machete.lua
├── Sickle/BP_UGC_MeleeWeap_Sickle.lua
├── TangDao/Template_Melee_TangDao_Handle.lua
└── CG035/
    ├── BoxingGloves/Template_Melee_BoxingGloves.lua
    └── DragonBoy_Spear/BP_UGC_DragonBoySpear.lua

VehicleWeapon/
├── BP_UGC_VehicleShootWeapon.lua       -- 载具射击武器基类
├── BP_UGC_VehGatlin_Dacia.lua          -- 达契亚机枪
├── BP_UGC_VehGatlin_Pickup.lua         -- 皮卡机枪
├── BP_UGC_VehGatlin_UAZ.lua            -- UAZ 机枪
├── BP_UGC_VehGatlin_Buggy.lua          -- 越野机枪
└── BP_UGC_VehicleFireLauncherL.lua     -- 载具火箭发射器

AvatarEquipment/
├── Bag/
│   ├── Template_AvatarEquipment_Bag_LV1_Handle.lua
│   ├── Template_AvatarEquipment_Bag_LV2_Handle.lua
│   └── Template_AvatarEquipment_Bag_LV3_Handle.lua
└── Armor/
    ├── Template_AvatarEquipment_Armor_LV1_Handle.lua
    ├── Template_AvatarEquipment_Armor_LV2_Handle.lua
    └── Template_AvatarEquipment_Armor_LV3_Handle.lua

WeaponFunctionModule/
└── BP_WFM_UGC_HUD.lua                 -- 武器 HUD 模块

Projectile/
└── UGCGrenade/BP_UGCGrenade_Projectile_Template.lua  -- 手雷投射物

SkillThrowables/
└── Burn/Buff_ThrowableBurn.lua         -- 投掷物燃烧 Buff
```

---

## 附录 A：关键枚举类型

| 枚举名 | 说明 |
|--------|------|
| `EFreshWeaponStateType` | 武器状态类型（Idle/Fire/Reload/Inactive/NoBullet/WarmUp等） |
| `EDeadDropItemType` | 死亡掉落物品类型 |
| `EAnimLayerType` | 动画层类型 |
| `EExtraWeaponUIType` | 武器 UI 类型 |
| `EUTSkillEntry` | 技能入口类型（近战武器按下/松开） |
| `EMeleeDamageSubType` | 近战伤害子类型 |
| `EBattleItemDropReason` | 物品丢弃原因 |
| `EBattleItemPickupReason` | 物品拾取原因 |

## 附录 B：关键结构体类型

| 结构体名 | 说明 |
|----------|------|
| `FWeaponAttachmentConfig` | 武器配件配置 |
| `FRestrictedDamageTypeData` | 伤害类型配置 |
| `FWeaponMeshCfg` / `FMeshPackage` | 武器网格配置 |
| `FWeaponVerifyConfig` | 武器验证配置 |
| `FBodyAttachmentConfig` | 身体装饰配置 |
| `FProjectileExplosionNoise` | 投射物爆炸噪音 |
| `FGameAttributeProperty` | 游戏属性包装器 |
| `FWeaponReconnectReplicateData` | 武器重连同步数据 |
| `FPESkillUIInfo` | 技能 UI 信息 |
| `FPEBuffInfo` | Buff 信息 |
| `FItemDefineID` | 物品定义 ID |
| `FGameplayTagContainer` | Gameplay 标签容器 |

## 附录 C：武器 ItemHandle 与武器蓝图的关联

```
UGCBackpackShootWeaponHandle_BP_C
    ├── BulletID → Template_BulletBase_ItemHandle_C.ItemID (弹药关联)
    ├── MeshPackage → 武器网格资产
    ├── animBPClass → 武器动画蓝图
    ├── DefaultAvatarList → 默认装饰列表
    └── ParentIDList → 父物品 ID 列表（用于升级/变体）
```

武器蓝图通过 ItemHandle 系统与背包系统集成：
1. 拾取时调用 `HandlePickup()` → 通过 `BulletID` 关联对应弹药
2. 装备时通过 `WeaponAttachmentConfig` 挂载配件
3. 丢弃时调用 `HandleDrop()` → 在地面创建包装物
4. 死亡时根据 `DeadDropItemType` 决定掉落行为

---

> **文档结束** — 此文档基于武器系统 Lua 类型存根文件自动分析生成。实际运行时行为可能因 C++ 引擎实现细节而有所不同。
