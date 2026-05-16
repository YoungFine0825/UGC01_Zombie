---@class ETalentDataParams
ETalentDataParams = {
    Skills = 1,
    Buffs = 2,
    Attributes = 3,
}

---@class UGCTalent
UGCTalent = {
    ---@type int32
    ID = 0,
    ---@type FText
    Name = "",
    ---@type FText
    Desc = "",
    ---@type int32
    CategoryID = 0,
    ---@type int32
    SortPriority = 0,
    ---@type int32
    MaxLevel = 0,
    ---@type int32
    LimitType = 0,
    ---@type FText
    LimitParameter = "",
    ---@type UClass[]
    Skills = {},
    ---@type UClass[]
    Buffs = {},
    ---@type FGameAttributeValueConfig[]
    Attributes = {},
    ---@type UTexture2D
    Icon = "",
}

---@class UGCTalentLevel
UGCTalentLevel = {
    ---@type int32
    Level = 0,
    ---@type int32
    RequiredPoints = 0,
    ---@type int32[]
    Talents = {},
}

---@class UGCTalentCategory
UGCTalentCategory = {
    ---@type int32
    ID = 0,
    ---@type FText
    Name = "",
    ---@type int32
    LimitType = 0,
    ---@type int32
    HeroID = 0,
    ---@type bool
    IsGeneral = true,
    ---@type bool
    ShowIcon = true,
    ---@type bool
    CanReset = false,
}

-- ---@class UGCHero
-- UGCHero = {
--     ---@type int32
--     ID = 0,
--     ---@type FText
--     Name = "",
--     ---@type FText
--     Desc = "",
--     ---@type UTexture2D
--     Icon = "",
-- }

---@class ETalentPopup
ETalentPopup = {
    Reset = 1,      -- 重置弹窗
    Confirm = 2,    -- Tip内确认弹窗
}

-- ---@class ETalentReduceFailure
-- ETalentReduceFailure = {
--     NotResettable = 1,  -- 不可重置
--     NotLastLayer = 2,   -- 不属于最后一层
--     NotGreaterZero = 3, -- 天赋等级不大于0
-- }