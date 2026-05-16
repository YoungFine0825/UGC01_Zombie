-- auto exported UStruct while compiling 

-- sorted by struct name asc 

---@class BackpackTabInfo
---@field TabName FString
---@field Tags FString[]

---@class GiftPackData
---@field ID int32
---@field ItemID int32
---@field type EGiftPackType
---@field OpenWay EGiftPackOpenType
---@field DropID int32
---@field DropGroupID int32

---@class Hero
---@field ID int32
---@field Name FText
---@field Desc FText
---@field Icon UTexture2D
---@field HeroSkills UClass[]
---@field HeroBuffs UClass[]
---@field HeroAttributes FGameAttributeValueConfig[]
---@field HeroMeshPath FSoftObjectPath

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

---@class LotteryDrawInfo
---@field LotteryID int32
---@field LotteryRecords LotteryRecord[]
---@field TotalDrawTimes int32

---@class LotteryDrawItemInfo
---@field ID int32
---@field Num int32
---@field DropType FString
---@field IsDrawTenth bool

---@class LotteryExchangeInfo
---@field ProductID int32
---@field ExchangeInfo LotteryExchangeItemInfo[]

---@class LotteryExchangeItemInfo
---@field ExchangeNum int32
---@field ExchangeTime int32

---@class LotteryGiftProgressInfo
---@field LotteryID int32
---@field ProgressInfo LotteryGiftProgressReciveState[]

---@class LotteryGiftProgressReciveState
---@field Progress int32
---@field State bool

---@class LotteryInfo
---@field LotteryGroup bool
---@field Lottery bool
---@field LotteryExchangeInfo bool
---@field LotteryGiftProgress bool
---@field LotterySkipAnim bool

---@class LotteryRecord
---@field DrawItemInfo LotteryDrawItemInfo
---@field DrawTime int32

---@class LotteryData
---@field ID int32
---@field GiftProgressRewards ProgressReward[]
---@field LotteryRule FString
---@field DailyDrawLimit int32
---@field DailyDrawGroup int32
---@field OverrideDropID int32
---@field DropGroupID int32
---@field DrawCostID int32
---@field TenDrawCostNum int32
---@field OverrideGuarantDropID int32
---@field GuarantDropGroupID int32
---@field IsFirstDrawDiscountOpen bool
---@field FirstDrawDiscountCost int32
---@field FirstDrawDiscountResetType ELotteryResetType
---@field OverrideFirstDrawGuarantDropID int32
---@field FirstDrawGuarantDropGroupID int32
---@field FirstDrawGuarantResetType ELotteryResetType
---@field OneDrawCostNum int32
---@field Name FString
---@field Icon FSoftObjectPath

---@class ProgressItem
---@field ItemID int32
---@field ItemCount int32

---@class ProgressReward
---@field Progress int32
---@field ItemList ProgressItem[]
---@field Desc FString

---@class RankingListData
---@field Index int32
---@field LimitPeopleNum int32
---@field ResetType RankingListResetType
---@field PeriodType RankingListPeriodType
---@field BeginDate FString
---@field CalculateTime int32
---@field SettleTime int32
---@field CycleNum int32
---@field SettleDate FString
---@field EndDate FString
---@field SortPropertyName FString
---@field SortType RankingListSortType
---@field AwardList int32

---@class IDAndNum
---@field ID int32
---@field Num int32

---@class ItemQuality
---@field ItemID int32
---@field QualityRank int32

---@class TabInfo
---@field TabID int32
---@field TabName FString

---@class ShopV2_IDAndNum
---@field ID int32
---@field Num int32

---@class ShopV2_LockSetting
---@field LockID int32
---@field CanLock bool

---@class ShopV2_RandomRefreshRule
---@field RefreshNum int32
---@field Price int32

---@class ShopV2_TabInfo
---@field TabID int32
---@field TabName FString
---@field TabShopName FString
---@field TabShopDesc FString

---@class ShopV2_Time
---@field Hour int32
---@field Min int32
---@field Sec int32

---@class ShopV2_Timespan
---@field Day int32
---@field Hour int32
---@field Min int32
---@field Sec int32

---@class FEventTabInfo
---@field EventID int32
---@field TabName FString

---@class FSignInAward
---@field ItemID int32
---@field ItemNum int32

---@class FSignInEventConfig
---@field EventID int32
---@field EventName FString
---@field Type ESignInEventType
---@field IsActive bool
---@field StartTime FDateTime
---@field EndTime FDateTime
---@field Desc FString
---@field SupplementDay int32
---@field SupplementItemID int32
---@field SupplementItemNum int32
---@field AwardTablePath FSoftObjectPath
---@field HighLight7thDay bool

---@class FSignInEventData
---@field EventID int32
---@field DayNum int32
---@field NextDayTime int32
---@field SupplementDayNum int32

---@class ShopV2_ItemQuality
---@field ItemID int32
---@field QualityRank int32

