-- auto exported UStruct while compiling 

-- sorted by struct name asc 

---@class ShopV2_Time
---@field Hour int32
---@field Min int32
---@field Sec int32

---@class ShopV2_Timespan
---@field Day int32
---@field Hour int32
---@field Min int32
---@field Sec int32

---@class Struct_WeaponSlotConfig
---@field SlotTag FGameplayTag
---@field SlotEnum ESurviveWeaponPropSlot

---@class Struct_WeaponConfig
---@field Id int32
---@field WeaponItemId int32
---@field AmmoItemId int32
---@field DeliverAmmoNumber int32
---@field WeaponName FString
---@field WeaponDesc FString
---@field WeaponLevel int32
---@field WeaponSlots Struct_WeaponSlotConfig[]
---@field WeaponClass UClass

---@class Struct_ItemSpawnerTypeConfig
---@field SpawnerType FName
---@field DropGroupID int32

---@class TableStruct_ItemSpawnScheme
---@field SchemeID int32
---@field SpawnerTypes Struct_ItemSpawnerTypeConfig[]

---@class TableStruct_MonsterDetails
---@field MonsterID int32
---@field MonsterName FString
---@field MonsterClass FSoftClassPath
---@field BodyHitScore int32
---@field BodyKillScore int32
---@field HeadshotKillScore int32

---@class Struct_MonsterGroup
---@field MonsterID int32
---@field Weight int32

---@class Struct_MonsterSpawnerTypeConfig
---@field SpawnerType FName
---@field Monsters Struct_MonsterGroup[]

---@class TableStruct_MonsterSpawnScheme
---@field SchemeID int32
---@field SpawnerTypes Struct_MonsterSpawnerTypeConfig[]
---@field RageStartRatio float
---@field RageRatioStep float
---@field RageMaxRatio float
---@field RageStartRound int32

---@class Struct_RandomModifier
---@field Min float
---@field Max float

---@class TableStruct_AffixDetails
---@field Id int32
---@field MutexExclusion FName
---@field IsPassiveSkill bool
---@field AffixesLevel int32
---@field TargetAttrType FGameAttributeContainer
---@field Description FString
---@field RandomModifier Struct_RandomModifier
---@field SkillId int32[]
---@field DecimalPlaces int32
---@field DisplayPercentage bool

---@class Struct_NumberRange
---@field Min int32
---@field Max int32

---@class Struct_RandomAffixes
---@field AffixIds int32[]
---@field NumberRange Struct_NumberRange

---@class TableStruct_EquippmentRandomAffix
---@field Id int32
---@field Tips FString
---@field QuantityOfAffixes int32
---@field RandomAffixes Struct_RandomAffixes[]
---@field IsRepeat bool
---@field EquipSlot FString

---@class FModeConfig
---@field ModeID int32
---@field ModeName FText
---@field Difficulty FText
---@field LevelCount int32
---@field UnlockDesc FText
---@field UnlockMode int32[]
---@field EnemyRefresh int32
---@field ItemRefresh int32
---@field ShopAfterLevel int32[]
---@field TrapRefresh int32
---@field SettlementExpCount int32
---@field SettlementTalentCount int32
---@field GameModeActorMgr FString
---@field FreeReviveCount int32
---@field PaidReviveCount  int32
---@field Price int32[]

---@class FModeDetail
---@field ID int32
---@field ModeName FText
---@field ModeDesc FText
---@field ModeBanner UTexture2D
---@field ModePost UTexture2D
---@field ModeIDs int32[]
---@field Hide bool

---@class Struct_InteractEntityAttribute
---@field Key FString
---@field Value float
---@field bIsTemporary bool
---@field Tip FString

---@class UGCLevelAttribute
---@field Attribute FGameAttributeContainer
---@field Value float

---@class UGCLevelConfigRow
---@field Level int32
---@field Description FString
---@field Exp int32
---@field AcquiredSkills UClass[]
---@field AcquiredPassiveSkills UClass[]
---@field Attributes UGCLevelAttribute[]
---@field TalentPoints int32

---@class UGCLevelGlobalRow
---@field HealthDelta int32
---@field DefenceDelta int32
---@field MagicDelta int32

---@class Affix

---@class Struct_ShowTotalAttributeAffix
---@field ID int32
---@field GameAttributeType FGameAttributeContainer
---@field AttributeName FName
---@field IsShow bool
---@field DisplayPercentage bool

---@class TableStruct_ItemMapAffixId
---@field ItemID int32
---@field EquipAffixId int32

---@class TableStruct_Struct_SkillDetails
---@field id int32
---@field Description FString
---@field Blueprint UClass

---@class Struct_InteractEntityBeahaviour
---@field BehaviourTags FGameplayTag
---@field Playload int32

---@class Struct_interactEntityCondition
---@field SourceTags FGameplayTag
---@field Compare ECompareOperation
---@field ValueType EPropertyDataType
---@field IntValue int32
---@field FloatValue float
---@field StringValue FString
---@field BoolValue bool

---@class Struct_InteractEntityConfig
---@field InteractConfigID int32
---@field bNeedPlayerConfirm bool
---@field Conditions Struct_interactEntityCondition[]
---@field Behaviours Struct_InteractEntityBeahaviour[]
---@field ActorClass FSoftClassPath
---@field DisplayName FString
---@field Description FString
---@field ClientPriority int32
---@field CooldownTime float
---@field PayloadID int32
---@field TotalInteractTimes int32
---@field PlayerInteractTimes int32
---@field CostScore int32
---@field UISchemeConfigID int32

---@class Struct_InteractEntityUIScheme
---@field ID int32
---@field Note FString
---@field TipsText FString
---@field TipsArgs FString[]
---@field ButtonLabel FString

---@class Talent
---@field ID int32
---@field Name FText
---@field Desc FText
---@field CategoryID int32
---@field MaxLevel int32
---@field LimitParameter int32
---@field Skills UClass[]
---@field Buffs UClass[]
---@field Attributes FGameAttributeValueConfig[]
---@field SortPriority int32
---@field Icon UTexture2D

---@class TalentCategory
---@field ID int32
---@field Name FText
---@field IsGeneral bool
---@field HeroID int32
---@field CanReset bool
---@field LimitType LimitType
---@field Description FText[]
---@field UnlockDescription FText[]

---@class Hero
---@field ID int32
---@field Name FText
---@field Desc FText
---@field Icon UTexture2D
---@field HeroSkills UClass[]
---@field HeroBuffs UClass[]
---@field HeroAttributes FGameAttributeValueConfig[]
---@field HeroMeshPath FSoftObjectPath
---@field HeroPortrait UTexture2D

---@class HeroAbilityLabel
---@field ID int32
---@field HeroID int32
---@field Name FText
---@field NameColor FSlateColor
---@field BackgroundColor FSlateColor
---@field Icon UTexture2D
---@field Detail FText

---@class HeroFreeConfig
---@field ID int32
---@field HeroID int32
---@field FreeType EHeroFreeType
---@field StartDate FDateTime
---@field EndDate FDateTime
---@field CycleNumber int32
---@field DurationDays int32

---@class HeroUI
---@field ID int32
---@field HeroID int32
---@field ProductID int32
---@field SortPriority int32
---@field IsShow bool
---@field IsFree bool
---@field HeroDetail1 FText
---@field HeroAbilityLabelIsIcon bool
---@field HeroDetail3 FText

---@class ShopV2_IDAndNum
---@field ID int32
---@field Num int32

---@class ShopV2_ItemQuality
---@field ItemID int32
---@field QualityRank int32

---@class ShopV2_LockSetting
---@field LockID int32

---@class ShopV2_RandomRefreshRule
---@field RefreshNum int32
---@field Price int32

---@class ShopV2_TabInfo
---@field TabID int32
---@field TabName FString
---@field TabShopName FString
---@field TabShopDesc FString

