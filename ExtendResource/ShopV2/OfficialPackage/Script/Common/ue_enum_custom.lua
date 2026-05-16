-- auto exported UENUM while compiling 

-- sorted by enum name asc 

---@enum ShopV2_ActivateRefreshRule
ShopV2_ActivateRefreshRule = { 
    UseDuration = 0,
    UseTime = 1,
}; 


---@enum ShopV2_LockRefreshRule
ShopV2_LockRefreshRule = { 
    Permanent = 0,
    CloseShop = 1,
    WithTime = 2,
    ExitGame = 3,
}; 


---@enum ShopV2_RefreshResetRule
ShopV2_RefreshResetRule = { 
    PlayTimesPeriod = 0,
    WithTime = 1,
}; 


---@enum EGiftPackOpenType
EGiftPackOpenType = { 
    ManuallyOpen = 0,
    AutoOpen = 1,
}; 


---@enum EGiftPackType
EGiftPackType = { 
    Normal = 0,
    Optional = 1,
}; 


---@enum EHeroFreeType
EHeroFreeType = { 
    Monthly = 0,
    Weekly = 1,
    Daily = 2,
    Fixed = 3,
}; 


---@enum ELotteryMainUIType
ELotteryMainUIType = { 
    Default = 0,
    ShowAward = 1,
    TwoDimensionBg = 2,
    ThreeDimensionBg = 3,
}; 


---@enum ELotteryResetType
ELotteryResetType = { 
    NotReset = 0,
    DailyReset = 1,
    MonthlyReset = 2,
    WeeklyReset = 3,
}; 


---@enum RankingListPeriodType
RankingListPeriodType = { 
    DailyReset = 0,
    WeeklyReset = 1,
    MonthlyReset = 2,
    CustomizeReset = 3,
}; 


---@enum RankingListResetType
RankingListResetType = { 
    CycleRankList = 0,
    NotCycleRankList = 1,
}; 


---@enum RankingListSortType
RankingListSortType = { 
    LargeValuePrefer = 0,
    SmallValuePrefer = 1,
}; 


---@enum ESignInEventType
ESignInEventType = { 
    Monthly = 0,
    Weekly = 1,
    OneOff = 2,
}; 


