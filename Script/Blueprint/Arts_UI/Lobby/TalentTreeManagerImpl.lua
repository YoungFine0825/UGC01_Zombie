UGCGameSystem.UGCRequire("Script.Blueprint.Arts_UI.Lobby.TalentTreeTypes")
UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.Common.Common")
UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.Common.UIManager")

---@type UUserWidget
local UserWidget = UserWidget == nil and nil or UserWidget
local Delegate = require("common.Delegate")
local PromiseFuture = require("common.PromiseFuture")

---@class TalentTreeManagerImpl
local TalentTreeManagerImpl = {
    TalentTreeComponentClass = nil, 
    ---@type BP_TalentTreeComponent_C
    TalentTreeComponent = nil,
    ---@type UGCPlayerController_C
    PlayerController = nil,
    ---@type UGCPlayerPawn_C
    PlayerPawn = nil,
    ---@type string
    PlayerKey = nil,
    ---@type BP_TestButton_C
    TestButtonWidget = nil,
    ---@type boolean
    bInitialized = false,
    ---@type number
    HeroIdx = 1,                    -- 英雄页签对应的Idx
    ---@type number
    CurrentTabIdx = 1,              -- 当前选中的页签Idx
    ---@type number
    CurrentHeroIdx = 1,             -- 当前选中的英雄Idx
    ---@type table<int32, UGCTalent>
    TalentDataMap = {},
    ---@type table<int32, UGCTalentCategory>
    TalentCategoryDataMap = {},
    ---@type table<int32, UGCHero>
    HeroDataMap = {},
    ---@type table<int32, int32>
    HeroIDToCategoryIDMap = {},     -- HeroID -> CategoryID列表
    ---@type table<int32, int32>
    CategoryIDToTalentIDMap = {},   -- CategoryID -> TalentID列表
    ---@type table<int32, int32>
    IdxToCategoryIDMap = {},        -- TabIdx -> CategoryID列表
    ---@type table<int32, int32>
    IdxToHeroIDMap = {},            -- HeroIdx -> HeroID列表
    ---@type table<int32, table<int32, int32>>
    LayeredTalentCache = {},        -- CategoryID -> { LayerIdx -> {LimitParameter, TalentID} 列表 }
    ---@type table<int32, int32>
    TalentInfoCache = {},           -- TalentID -> Level 列表
    ---@type table<int32, int32>
    TalentPointsByLevel = {},       -- Level -> TalentPoints
    ---@type table<int32, int32>
    TempTalentInfo = {},            -- 临时存储天赋初始等级，TalentID -> Level 列表
    ---@type table<int32, int32>
    PendingUpgradeCount = {},       -- 待确认的加点计数，TalentID -> 待确认次数（用于弱网环境下正确取消）
    

    -- delegates
    OnMainWidgetOpened = Delegate.New(),
    OnMainWidgetClosed = Delegate.New(),
    OnTalentSelected = Delegate.New(),
    OnTalentPointsUpdate = Delegate.New(),
    OnTalentInfoUpdate = Delegate.New(),
    OnTabSelected = Delegate.New(),
    OnHeroSelected = Delegate.New(),
    OnButtonStatesUpdate = Delegate.New(),
}

function TalentTreeManagerImpl:Init(InTalentTreeComponent)
    ugcprint("[TalentTree] TalentTreeManagerImpl:Init")

    if self.bInitialized then
        ugcprint("[TalentTree] TalentTreeManagerImpl:Init(): bInitialized is true")
        return
    end

    self.TalentTreeComponent = InTalentTreeComponent
    self.CurrentCategoryID = 1

    PromiseFuture.New():Set(
        function(PromiseFuture)
            while true do
                local Success = self:UpdateCachedVariables()

                if Success then
                    -- if UGCGameSystem.IsServer() then
                    --     self:AddTalentPoints(10,10001)
                    --     self:AddTalentPoints(15,10002)
                    -- end
                    return
                else
                    PromiseFuture:Yield()
                end
            end
        end
    ):AutoResume(InTalentTreeComponent, 0.2, 60)

    if not self:InitTalentCategoryData() then
        ugcprint("[TalentTree] TalentTreeManagerImpl:Init(): InitTalentCategoryData is nil")
        return
    end

    if not self:InitHeroData() then
        ugcprint("[TalentTree] TalentTreeManagerImpl:Init(): HeroTable is nil")
        return
    end
    
    if not self:InitTalentData() then
        ugcprint("[TalentTree] TalentTreeManagerImpl:Init(): InitTalentData is nil")
        return
    end

    if not self:InitLevelData() then
        ugcprint("[TalentTree] TalentTreeManagerImpl:Init(): InitLevelData is nil")
        return
    end

    self:PreprocessLayeredTalents()

    self.bInitialized = true
end

function TalentTreeManagerImpl:InitHeroData()
    ugcprint("[TalentTree] TalentTreeManagerImpl:Init(): InitHeroData")
    local HeroTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/Hero/UGCHero.UGCHero'))

    self.HeroDataMap = {}

    local SortIdx = 1
    
    if HeroTable ~= nil then
        for _, v in pairs(HeroTable) do
            ---@type UGCHero
            local HeroData = {}

            -- 英雄ID
            HeroData.ID = v.ID
            -- 英雄名称
            HeroData.Name = v.Name
            -- 英雄描述
            HeroData.Desc = v.Desc
            -- 英雄图标
            HeroData.Icon = v.Icon
            -- 英雄立绘
            HeroData.HeroPortrait = v.HeroPortrait

            self.HeroDataMap[v.ID] = HeroData

            -- 检查是否存在于 HeroIDToCategoryIDMap 的 key 中，用于仅显示有英雄天赋的英雄
            if self.HeroIDToCategoryIDMap[v.ID] then
                self.IdxToHeroIDMap[SortIdx] = v.ID
                SortIdx = SortIdx + 1
            end

            ugcprint(string.format("[TalentTree] Init hero data: id = %s, name = %s", v.ID, v.Name))
        end
    else
        return false
    end

    return true
end

function TalentTreeManagerImpl:InitTalentData()
    ugcprint("[TalentTree] TalentTreeManagerImpl:Init(): InitTalentData")
    local TalentTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/TalentTree/UGCTalent.UGCTalent'))
    self.TalentDataMap = {}
    
    if TalentTable ~= nil then
        for _, v in pairs(TalentTable) do
            ---@type UGCTalent
            local TalentData = {}

            -- 天赋ID
            TalentData.ID = v.ID
            -- 天赋名称
            TalentData.Name = v.Name
            -- 天赋描述
            TalentData.Desc = v.Desc
            -- 天赋属于的类别ID
            TalentData.CategoryID = v.CategoryID
            -- 天赋在类别中的排序
            TalentData.SortPriority = v.SortPriority
            -- 天赋的最大等级
            TalentData.MaxLevel = v.MaxLevel
            -- 天赋的限制类型
            TalentData.LimitType = v.LimitType
            -- 天赋的限制参数
            TalentData.LimitParameter = v.LimitParameter
            -- 天赋生效对应的技能
            TalentData.Skills = totable(v.Skills)
            -- 天赋生效对应的Buff
            TalentData.Buffs = totable(v.Buffs)
            -- 天赋生效对应的属性修改
            TalentData.Attributes = totable(v.Attributes)
            -- 天赋的图标
            TalentData.Icon = v.Icon

            self.TalentDataMap[v.ID] = TalentData
            ugcprint(string.format("[TalentTree] Init talent data: id = %s, name = %s", v.ID, v.Name))

            if self.CategoryIDToTalentIDMap[TalentData.CategoryID] == nil then
                self.CategoryIDToTalentIDMap[TalentData.CategoryID] = {}
            end
            table.insert(self.CategoryIDToTalentIDMap[TalentData.CategoryID], TalentData.ID)
        end
        return true
    end
    return false
end

function TalentTreeManagerImpl:InitTalentCategoryData()
    ugcprint("[TalentTree] TalentTreeManagerImpl:Init(): InitCategoryData")
    local TalentCategoryTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/TalentTree/UGCTalentCategory.UGCTalentCategory'))
    self.TalentCategoryDataMap = {}
    self.HeroIDToCategoryIDMap = {}     -- HeroID -> TalentCategoryData列表
    self.IdxToCategoryIDMap = {}

    local SortIdx = 1

    if TalentCategoryTable ~= nil then
        for _, v in pairs(TalentCategoryTable) do
            ---@type UGCTalentCategory
            local TalentCategoryData = {}
    
            -- 类别ID
            TalentCategoryData.ID = v.ID
            -- 类别名称
            TalentCategoryData.Name = v.Name
            -- 类别限制类型
            TalentCategoryData.LimitType = v.LimitType
            -- 类别对应的英雄，只有在英雄专属类别时生效
            TalentCategoryData.HeroID = v.HeroID
            -- 天赋是否是通用类别，与英雄专属类别相对
            TalentCategoryData.IsGeneral = v.IsGeneral
            -- 该类别是否配置图标
            TalentCategoryData.ShowIcon = v.ShowIcon
            -- 该类别是否可以重置
            TalentCategoryData.CanReset = v.CanReset
            -- 每一层的描述
            TalentCategoryData.Description = v.Description:Copy()
            -- 每一层的解锁条件
            TalentCategoryData.UnlockDescription = v.UnlockDescription:Copy()

            self.TalentCategoryDataMap[v.ID] = TalentCategoryData
            self.IdxToCategoryIDMap[SortIdx] = v.ID
            ugcprint(string.format("[TalentTree] Init talent category data: id = %s, name = %s", v.ID, v.Name))

            -- 根据HeroID建立映射关系
            if TalentCategoryData.HeroID ~= nil then
                if not self.HeroIDToCategoryIDMap[TalentCategoryData.HeroID] then
                    self.HeroIDToCategoryIDMap[TalentCategoryData.HeroID] = {}
                end
                if TalentCategoryData.HeroID ~= 0 then
                    self.HeroIDToCategoryIDMap[TalentCategoryData.HeroID] = TalentCategoryData.ID    
                end
            end

            if v.IsGeneral then
                SortIdx = SortIdx + 1
            end
        end
        self.HeroIdx = SortIdx  -- 最后一个类别为英雄页签

        return true
    end
    return false
end

function TalentTreeManagerImpl:InitLevelData()
    ugcprint("[TalentTree] TalentTreeManagerImpl:Init(): InitLevelData")
    local LevelTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Level/UGCLevelConfig.UGCLevelConfig'))

    if LevelTable ~= nil then
        for _, v in pairs(LevelTable) do
            self.TalentPointsByLevel[v.Level] = v.TalentPoints
        end
        return true
    end
    return false
end

--- 预处理方法：在初始化时调用一次
function TalentTreeManagerImpl:PreprocessLayeredTalents()
    self.LayeredTalentCache = {}    -- 清空缓存

    for CategoryID, _ in pairs(self.CategoryIDToTalentIDMap) do
        local TalentIDs = self:GetTalentIDsByCategoryID(CategoryID)
        local TalentLayers = {}

        for _, TalentID in ipairs(TalentIDs) do
            local TalentData = self.TalentDataMap[TalentID]
            local LimitParameter = TalentData.LimitParameter
            if not TalentLayers[LimitParameter] then
                TalentLayers[LimitParameter] = {}
            end
            table.insert(TalentLayers[LimitParameter], TalentID)
        end

        -- 将层数按LimitParameter进行排序并存储
        local SortedLayers = {}
        for limitParameter, talentIDs in pairs (TalentLayers) do
            table.insert(SortedLayers, {LimitParameter = limitParameter, TalentIDs = talentIDs})
        end
        table.sort(SortedLayers, function(a, b)
            return a.LimitParameter < b.LimitParameter
        end)
        
        -- 添加Description和UnlockDescription
        local CategoryData = self:GetCategoryDataByCategoryID(CategoryID)
        if CategoryData then
            for index, layer in ipairs(SortedLayers) do
                ugcprint(string.format("添加描述 = %s， 添加解锁条件 = %s", CategoryData.Description[index], CategoryData.UnlockDescription[index]))
                layer.Description = CategoryData.Description and CategoryData.Description[index] or "未配置描述"
                layer.UnlockDescription = CategoryData.UnlockDescription and CategoryData.UnlockDescription[index] or "未配置解锁条件"
            end
        end

        self.LayeredTalentCache[CategoryID] = SortedLayers
    end
end

function TalentTreeManagerImpl:GetHeroDataByHeroID(HeroID)
    ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:GetHeroDataByHeroID(): Getting herodata for HeroID = %s", HeroID))
    
    return self.HeroDataMap[HeroID]
end

--- 通过CategoryID获取该页签对应的所有天赋ID
function TalentTreeManagerImpl:GetTalentIDsByCategoryID(CategoryID)
    ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:GetTalentIDsByCategoryID(): Getting talents for CategoryID = %s", CategoryID))
    return self.CategoryIDToTalentIDMap[CategoryID]
end

function TalentTreeManagerImpl:GetHeroDataByIdx(Idx)
    local HeroID = self.IdxToHeroIDMap[Idx]
    return self:GetHeroDataByHeroID(HeroID)
end

function TalentTreeManagerImpl:GetCategoryDataByIdx(Idx)
    local CategoryID = self.IdxToCategoryIDMap[Idx]
    return self:GetCategoryDataByCategoryID(CategoryID)
end

function TalentTreeManagerImpl:GetLayerTalentIDs(CategoryID, Idx)
    -- 如果没有传入 CategoryID，则使用当前的 CategoryID
    if not CategoryID then
        CategoryID = self.CurrentCategoryID
        -- ugcprint(string.format("TalentTreeManagerImpl:GetLayerData, using CurrentCategoryID = %d", CategoryID))
    end
    
    if CategoryID then
        local SortedLayers = self.LayeredTalentCache[CategoryID]
        if not SortedLayers then
            ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:GetLayerTalentIDs: CategoryID %d not found in cache. ", CategoryID))
        end

        if Idx then
            -- ugcprint(string.format("TalentTreeManagerImpl:GetLayerTalentIDs, CategoryID = %d, Idx = %d.", CategoryID, Idx))
            local Layer = SortedLayers[Idx]
            if Layer then
                return Layer.TalentIDs, #Layer.TalentIDs
            else
                ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:GetLayerTalentIDs: Invalid layer index %d for CategoryID %d.", Idx, CategoryID))
            end
        end

        -- 如果没有传入Idx，则返回所有层级的天赋数据
        return SortedLayers, #SortedLayers
    end
end

function TalentTreeManagerImpl:GetLayerTalentData(CategoryID, Idx)
    -- 如果没有传入 CategoryID，则使用当前的 CategoryID
    if not CategoryID then
        CategoryID = self.CurrentCategoryID
        -- ugcprint(string.format("TalentTreeManagerImpl:GetLayerTalentData, using CurrentCategoryID = %d", CategoryID))
    else
        -- ugcprint(string.format("TalentTreeManagerImpl:GetLayerTalentData, CategoryID = %d", CategoryID))
    end

    local SortedLayers = self.LayeredTalentCache[CategoryID]
    if not SortedLayers then
        ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:GetLayerTalentData: CategoryID %d not found in cache. ", CategoryID))
        return nil
    end

    local TalentInfoCache = self.TalentInfoCache

    if Idx then
        local Layer = SortedLayers[Idx]
        if Layer then
            local TalentDataList = {}
            for _ , talentID in ipairs(Layer.TalentIDs) do
                local TalentData = self:GetTalentDataByTalentID(talentID)
                if TalentData then
                    TalentData.Level = TalentInfoCache[talentID] or 0
                    TalentData.isSelected = (talentID == self.CurrentTalentID)
                    table.insert(TalentDataList, TalentData)
                end
            end
            return TalentDataList
        else
            ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:GetLayerTalentData: Invalid layer index %d for CategoryID %d.", Idx, CategoryID))
            return nil
        end
    end

    -- 如果没有传入Idx，则返回所有层级的天赋数据
    local AllTalentData = {}
    for _, layer in ipairs(SortedLayers) do
        for _, talentID in ipairs(layer.TalentIDs) do
            local TalentData = self:GetTalentDataByTalentID(talentID)
            if TalentData then
                TalentData.Level = TalentInfoCache[talentID] or 0
                table.insert(AllTalentData, TalentData)
            end
        end
    end
    return AllTalentData
end

function TalentTreeManagerImpl:GetLayerData(CategoryID)
    -- 如果没有传入 CategoryID，则使用当前的 CategoryID
    if not CategoryID then
        CategoryID = self.CurrentCategoryID
        -- ugcprint(string.format("TalentTreeManagerImpl:GetLayerData, using CurrentCategoryID = %d", CategoryID))
    else
        -- ugcprint(string.format("TalentTreeManagerImpl:GetLayerData, CategoryID = %d", CategoryID))
    end

    local SortedLayers = self.LayeredTalentCache[CategoryID]
    if not SortedLayers then
        ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:GetLayerTalentData: CategoryID %d not found in cache. ", CategoryID))
        return nil
    end

    return SortedLayers
end

function TalentTreeManagerImpl:GetUnlockState(CategoryID, Idx)
    local LayeredData = self.LayeredTalentCache[CategoryID]   -- { Idx -> { LimitParameter, TalentIDs }} 层数到解锁点数和天赋ID合集的映射
    if not LayeredData then
        ugcprint(string.format("[TalentTree] GetUnlockState: No LayeredData found for CategoryID %d", CategoryID))
        return false  -- 如果找不到数据，默认为未解锁
    end

    local LayerInfo = LayeredData[Idx]
    if not LayerInfo then
        ugcprint(string.format("[TalentTree] GetUnlockState: No data for layer %d in CategoryID %d", Idx, CategoryID))
        return false
    end

    local LimitParameter = LayerInfo.LimitParameter -- 这一层的解锁需求（天赋点数）
    local TalentIDs = LayerInfo.TalentIDs           -- 这一层包含的天赋ID合集
    local TalentInfoCache = self.TalentInfoCache    -- 客户端缓存的天赋数据（TalentID -> Level）

    if not TalentInfoCache then
        ugcprint("[TalentTree] GetUnlockState: TalentInfoCache not initialized.")
        return false
    end

    -- 计算当前 Category 下累计的天赋点数
    local TotalPointsUsed = 0
    for TalentID, Level in pairs(TalentInfoCache) do
        local TalentData = self:GetTalentDataByTalentID(TalentID)
        if TalentData and TalentData.CategoryID == CategoryID then
            TotalPointsUsed = TotalPointsUsed + Level
        end
    end

    -- 检查当前层的累计点数是否满足解锁条件
    local IsUnlocked = TotalPointsUsed >= LimitParameter

    -- ugcprint(string.format(
    --     "[TalentTree] GetUnlockState: CategoryID = %d, Layer = %d, TotalPointsUsed = %d, LimitParameter = %d, IsUnlocked = %s",
    --     CategoryID, Idx, TotalPointsUsed, LimitParameter, tostring(IsUnlocked)
    -- ))

    return IsUnlocked
end

--- 访问到的ID在点击时就做判断
function TalentTreeManagerImpl:GetCurrentCategoryTalents(CategoryID)
    if type(CategoryID) ~= "number" then
        ugcprint("[TalentTree] TalentTreeManagerImpl:GGetCurrentTabTalents: Trying to index TalentCategory with invalid ID! expect: int32, get: " .. type(CategoryID))
    end

    if CategoryID and next(self.CategoryDataMap) then
        if self.CategoryDataMap[CategoryID] then
            return self.CategoryDataMap[CategoryID].Talents
        else
            ugcprint("[TalentTree] TalentTreeManagerImpl:GetCurrentCategoryData(): param CategoryID is invalid.")
        end
    end
end

--- 根据天赋ID获取天赋信息
function TalentTreeManagerImpl:GetTalentDataByTalentID(TalentID)
    if self.bInitialized then
        if type(TalentID) ~= "number" then
            ugcprint("[TalentTree] TalentTreeManagerImpl:GetUGCTalentData(): Trying to index talent with invalid ID! expect: int32, get: " .. type(TalentID))
        end

        if TalentID and next(self.TalentDataMap) then
            if self.TalentDataMap[TalentID] then
                return self.TalentDataMap[TalentID]
            else
                ugcprint("[TalentTree] TalentTreeManagerImpl:GetUGCTalentData(): param TalentID is invalid.")
            end
        else
            ugcprint("[TalentTree] TalentTreeManagerImpl:GetUGCTalentData(): param TalentID or TalentDataArr is nil.")
        end
    else
        ugcprint("[TalentTree] TalentTreeManagerImpl:GetUGCTalentData(): TalentTreeManagerImpl not initialized.")
        return nil
    end
end

--- 根据类别ID获取类别信息
function TalentTreeManagerImpl:GetCategoryDataByCategoryID(CategoryID)
    if not CategoryID then
        return self.TalentCategoryDataMap[self.CurrentCategoryID]
    else
        return self.TalentCategoryDataMap[CategoryID]
    end
end

--- 获取天赋信息
function TalentTreeManagerImpl:GetTalentDataMap()
    return self.TalentDataMap
end

--- 获取天赋页签信息
function TalentTreeManagerImpl:GetTalentCategoryDataMap()
    return self.TalentCategoryDataMap, #self.IdxToCategoryIDMap
end

--- 获取所有的英雄信息
---@return table<int32, UGCHero>, number @英雄数据表，表长度
function TalentTreeManagerImpl:GetUGCHeroDataMap()
    return self.HeroDataMap, #self.IdxToHeroIDMap
end

--- 获取Component
function TalentTreeManagerImpl:GetTalentTreeComponent(PlayerController)
    if PlayerController == nil and UGCGameSystem.IsServer() == false then
        if self.TalentTreeComponent == nil then
            if self.TalentTreeComponentClass ~= nil then
                self.TalentTreeComponent = self.PlayerController:GetComponentByClass(self.TalentTreeComponent)
            else
                ugcprint("[TalentTree] TalentTreeManagerImpl:GetTalentTreeComponent: Cannot get TalentTreeComponent")
            end
        end

        return self.TalentTreeComponent
    end

    if self.TalentTreeComponentClass ~= nil then
        return PlayerController:GetComponentByClass(self.TalentTreeComponentClass)
    else
        ugcprint("[TalentTree] TalentTreeManagerImpl:GetTalentTreeComponent: ComponentClass is nil!")
        return nil
    end 
end

function TalentTreeManagerImpl:RegisterTalentTreeComponentClass(CompClass)
    if CompClass ~= nil then
        self.TalentTreeComponentClass = CompClass
    end
end

function TalentTreeManagerImpl:UpdateCachedVariables()
    if not self.TalentTreeComponent then
        ugcprint("[TalentTree] UpdateCachedVariables: TalentTreeComponent is nil")
        return false
    end

    self.PlayerController = UGCGameSystem.IsServer() and 
                            UGCActorComponentUtility.GetOwner(self.TalentTreeComponent) or 
                            UGCGameSystem.GetLocalPlayerController()
    
    if not self.PlayerController then
        ugcprint("[TalentTree] UpdateCachedVariables: Failed to get PlayerController")
        return false
    end

    self.PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(self.PlayerController)
    if not self.PlayerKey or self.PlayerKey == 0 then
        ugcprint("[TalentTree] UpdateCachedVariables: Invalid PlayerKey")
        return false
    end

    self.PlayerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(self.PlayerController)
    if not self.PlayerPawn then
        ugcprint("[TalentTree] UpdateCachedVariables: Failed to get PlayerPawn")
        return false
    end

    ugcprint(string.format("[TalentTree] UpdateCachedVariables: Component=%s, Controller=%s, Key=%s, Pawn=%s",
        tostring(self.TalentTreeComponent),
        tostring(self.PlayerController),
        tostring(self.PlayerKey),
    tostring(self.PlayerPawn)))

    return true
end

function TalentTreeManagerImpl:OpenMainWidget()
    ugcprint("[TalentTree] TalentTreeManagerImpl:OpenMainWidget()")
end

function TalentTreeManagerImpl:CloseMainWidget()
    self.OnMainWidgetClosed()
    self:ValidateAndCancelChanges()
    self:CloseTalentTip()
    LobbyFlow:Go(LobbyFlowState.LFS_Lobby)
end

function TalentTreeManagerImpl:SelectHero(Idx)
    if not self.bInitialized then
        ugcprint("[TalentTree] TalentTreManagerImpl:SelectHero(): not initialized")
        return
    end

    self:ValidateAndCancelChanges()
    self:CloseTalentTip()

    self.CurrentHeroIdx = Idx
    local HeroID = self.IdxToHeroIDMap[Idx]

    -- 如果没有传入 HeroID，则默认选择 self.HeroIDToCategoryIDMap 的第一个 HeroID
    if not HeroID then
        for heroID, categoryID in pairs(self.HeroIDToCategoryIDMap) do
            if heroID ~= 0  then
                HeroID = heroID
                break
            end
        end
    end

    ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:SelectHero(): Selecting hero for PlayerController = %s, TalentTreeComponent = %s, PlayerKey = %s, HeroID = %s", self.PlayerController, self.TalentTreeComponent, self.PlayerKey, HeroID))
    UnrealNetwork.CallUnrealRPC(self.PlayerController, self.TalentTreeComponent, "Server_SelectHero", self.PlayerKey, HeroID)

    self.IdxToCategoryIDMap[self.HeroIdx] = self.HeroIDToCategoryIDMap[HeroID]
    self.OnHeroSelected(self.CurrentHeroIdx)

    local CurrentCategoryData = self:GetCategoryDataByCategoryID(self.CurrentCategoryID)
    if not CurrentCategoryData then
        ugcprint("[TalentTree] TalentTreeManagerImpl:SelectHero: Invalid Category Index")
        return
    end

    -- 如果有英雄天赋数据再切换，否则弹tip且隐藏英雄页签，可切回通用页签
    if not CurrentCategoryData.IsGeneral then
        if self.HeroIDToCategoryIDMap[HeroID] then
            self:SelectTab(self.HeroIdx)  
        else
            UGCWidgetManagerSystem.ShowTipsUI("此英雄无专属天赋")
            self:SelectTab(1)       
        end
    else
        self.OnTabSelected(self.CurrentTabIdx)
    end
end

function TalentTreeManagerImpl:SelectTab(TabIdx)
    self:ValidateAndCancelChanges()
    self:CloseTalentTip()

    self.CurrentCategoryID = self.IdxToCategoryIDMap[TabIdx]
    self.CurrentTabIdx = TabIdx

    self.OnTabSelected(TabIdx)
    self:UpdateTalentInfo()
end

function TalentTreeManagerImpl:SelectTalent(TalentID)
    self.CurrentTalentID = TalentID
    self.OnTalentInfoUpdate()
end

---局内为玩家附加天赋
function TalentTreeManagerImpl:ApplyTalents(TalentDataParams, TalentID, InPawnObj)
    local TargetPawn = InPawnObj or self.PlayerPawn

    ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:ApplyTalents(): TalentID = %s, TargetPawn = %s", TalentID, TargetPawn))

    for _, TalentDataParam in ipairs(TalentDataParams) do
        if TalentDataParam == ETalentDataParams.Skills then
            self:ApplySkills(TalentID ,TargetPawn)
        elseif TalentDataParam == ETalentDataParams.Buffs then
            self:ApplyBuffs(TalentID, TargetPawn)
        elseif TalentDataParam == ETalentDataParams.Attributes then
            self:ApplyAttributes(TalentID, TargetPawn)
        end        
    end
end

---调用天赋技能效果附加RPC
function TalentTreeManagerImpl:ApplySkills(TalentID, TargetPawn)
    if not self.bInitialized then
        ugcprint("[TalentTree] TalentTreManagerImpl:ApplySkills(): not initialized")
        return
    end

    self.TalentTreeComponent:ApplySkills(TalentID, TargetPawn)
end

---调用天赋Buff效果附加RPC
function TalentTreeManagerImpl:ApplyBuffs(TalentID, TargetPawn)
    if not self.bInitialized then
        ugcprint("[TalentTree] TalentTreManagerImpl:ApplayBuffs(): not initialized")
        return
    end

    self.TalentTreeComponent:ApplyBuffs(TalentID, TargetPawn)
end

---调用天赋属性效果附加RPC
function TalentTreeManagerImpl:ApplyAttributes(TalentID, TargetPawn)
    if not self.bInitialized then
        ugcprint("[TalentTree] TalentTreManagerImpl:ApplyAttributes(): not initialized")
        return
    end

    self.TalentTreeComponent:ApplyAttributes(TalentID, TargetPawn)
end

function TalentTreeManagerImpl:ApplySelectedHeroSkill(HeroID)
    ugcprint(string.format("[TalentTree] TalentTreManagerImpl:ApplySelectedHeroSkill(): HeroID = %s", HeroID))
    if not self.bInitialized then
        ugcprint("[TalentTree] TalentTreManagerImpl:ApplySelectedHeroSkill(): not initialized")
        return
    end

    local CategoryID = self.HeroIDToCategoryIDMap[HeroID]
    if not CategoryID then
        ugcprint(string.format("[TalentTree] TalentTreManagerImpl:ApplySelectedHeroSkill(): HeroID = %s not found in HeroIDToCategoryIDMap", HeroID))
        return
    end

    local TalentIDs = self:GetTalentIDsByCategoryID(CategoryID)
    if not TalentIDs then
        ugcprint(string.format("[TalentTree] TalentTreManagerImpl:ApplySelectedHeroSkill(): CategoryID = %s not found in GetTalentIDsByCategoryID", CategoryID))
        return
    end

    for _, TalentID in ipairs(TalentIDs) do
        local TalentData = self:GetTalentDataByTalentID(TalentID)
        if TalentData and TalentData.Skills and #TalentData.Skills > 0 then
            local TalentLevel = self.TalentInfoCache[TalentID] or 0
            ugcprint(string.format("[TalentTree] TalentTreManagerImpl:ApplySelectedHeroSkill(): TalentID = %s, TalentLevel = %s, PlayerPawn = %s", TalentID, TalentLevel, self.PlayerPawn))
            if TalentLevel > 0 then
                self:ApplySkills(TalentID, self.PlayerPawn)
            end
        end
    end
end

function TalentTreeManagerImpl:UpgradeTalent(TalentID)
    ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:UpgradeTalent(): Upgrading talents for PlayerController = %s, TalentTreeComponent = %s, PlayerKey = %s, TalentID = %s", self.PlayerController, self.TalentTreeComponent, self.PlayerKey, TalentID))

    -- 记录待确认的加点请求（用于弱网环境下正确取消）
    self.PendingUpgradeCount[TalentID] = (self.PendingUpgradeCount[TalentID] or 0) + 1
    ugcprint(string.format("[TalentTree] PendingUpgradeCount[%s] = %d", TalentID, self.PendingUpgradeCount[TalentID]))

    UnrealNetwork.CallUnrealRPC(self.PlayerController, self.TalentTreeComponent, "Server_UpgradeTalent", self.PlayerKey, TalentID)
end

function TalentTreeManagerImpl:ReduceTalent(TalentID)
    local TalentData = self:GetTalentDataByTalentID(TalentID)
    local CategoryData = self:GetCategoryDataByCategoryID(TalentData.CategoryID)

    if CategoryData.CanReset then
        ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:ReduceTalent(): Reducing talents for PlayerController = %s, TalentTreeComponent = %s, PlayerKey = %s, TalentID = %s", self.PlayerController, self.TalentTreeComponent, self.PlayerKey, TalentID))
        UnrealNetwork.CallUnrealRPC(self.PlayerController, self.TalentTreeComponent, "Server_ReduceTalent", self.PlayerKey, TalentID)
    else
        local CurrentLevel = self.TalentInfoCache[TalentID] or 0
        local TempLevel = self.TempTalentInfo[TalentID] or 0
        if CurrentLevel > TempLevel then
            ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:ReduceTalent(): Reducing talents for PlayerController = %s, TalentTreeComponent = %s, PlayerKey = %s, TalentID = %s, CurrentLevel = %s, TempLevel = %s", self.PlayerController, self.TalentTreeComponent, self.PlayerKey, TalentID, CurrentLevel, TempLevel))
            self.TalentInfoCache[TalentID] = CurrentLevel - 1   -- 先客户端减少，避免在等DS回调期间快速点击减点错误
            UnrealNetwork.CallUnrealRPC(self.PlayerController, self.TalentTreeComponent, "Server_ReduceTalent", self.PlayerKey, TalentID)
        end
    end
end

function TalentTreeManagerImpl:ResetTalent()
    ugcprint("[TalentTree] TalentTreeManagerImpl:ResetTalent")
    ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:ResetTalent(): Resetting talents for PlayerController = %s, TalentTreeComponent = %s, PlayerKey = %s, TalentCategoryID = %s", self.PlayerController, self.TalentTreeComponent, self.PlayerKey, self.CurrentCategoryID))
    UnrealNetwork.CallUnrealRPC(self.PlayerController, self.TalentTreeComponent, "Server_ResetTalentCategory", self.PlayerKey, self.CurrentCategoryID)
end

function TalentTreeManagerImpl:ConfirmChanges(TalentID)
    local CurrentLevel = self.TalentInfoCache[TalentID] or 0
    local TempLevel = self.TempTalentInfo[TalentID] or 0
    if CurrentLevel > TempLevel then
        self:OpenPopup(ETalentPopup.Confirm)
    else
        self:CloseTalentTip()
    end
end

function TalentTreeManagerImpl:CancelChanges()
    ugcprint("[TalentTree] TalentTreeManagerImpl:CancelChanges")
    
    for TalentID, currentLevel in pairs(self.TalentInfoCache) do
        local initialLevel = self.TempTalentInfo[TalentID] or 0
        local pendingCount = self.PendingUpgradeCount[TalentID] or 0
        local confirmedDelta = currentLevel - initialLevel
        
        ugcprint(string.format("[TalentTree] CancelChanges TalentID=%s: currentLevel=%d, initialLevel=%d, pendingCount=%d, confirmedDelta=%d", 
            TalentID, currentLevel, initialLevel, pendingCount, confirmedDelta))
        
        -- 1. 取消已确认到 TalentInfoCache 的加点（通过正常 ReduceTalent，受客户端等级检查保护）
        if confirmedDelta > 0 then
            for i = 1, confirmedDelta do
                self:ReduceTalent(TalentID)
            end
        end
        
        -- 2. 取消 pending 的加点（直接发 RPC，绕过客户端等级检查，因为服务端尚未回包确认，TalentInfoCache 不含这些点）
        if pendingCount > 0 then
            ugcprint(string.format("[TalentTree] CancelChanges: sending %d direct ReduceTalent RPCs for pending TalentID=%s", pendingCount, TalentID))
            for i = 1, pendingCount do
                UnrealNetwork.CallUnrealRPC(self.PlayerController, self.TalentTreeComponent, "Server_ReduceTalent", self.PlayerKey, TalentID)
            end
        end
    end
    
    -- 处理只在 PendingUpgradeCount 中但不在 TalentInfoCache 中的天赋（首次加点还没同步回来的情况，直接发 RPC）
    for TalentID, pendingCount in pairs(self.PendingUpgradeCount) do
        if not self.TalentInfoCache[TalentID] and pendingCount > 0 then
            ugcprint(string.format("[TalentTree] CancelChanges (pending only) TalentID=%s: pendingCount=%d", TalentID, pendingCount))
            for i = 1, pendingCount do
                UnrealNetwork.CallUnrealRPC(self.PlayerController, self.TalentTreeComponent, "Server_ReduceTalent", self.PlayerKey, TalentID)
            end
        end
    end
    
    -- 清空待确认计数
    self.PendingUpgradeCount = {}
end

function TalentTreeManagerImpl:ValidateAndCancelChanges()
    local CategoryData = self:GetCategoryDataByCategoryID(self.CurrentCategoryID)
    local bTalentTipOpened = LobbyUtils.GetWidget(LobbyWidgetType.LWT_TalentTreeTipConfirm).bIsOpened

    if bTalentTipOpened and not CategoryData.CanReset then
        self:CancelChanges()
    end
end

function TalentTreeManagerImpl:AddTalentPoints(TalentPoints, TargetPlayerKey)
    ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:AddTalentPoints(): AddTalentPoints for PlayerKey = %s, TalentPoints = %s", tostring(TargetPlayerKey), TalentPoints))
    if UGCGameSystem.IsServer() then
        ugcprint("[TalentTree] TalentTreeManagerImpl:AddTalentPoints(): AddTalentPoints for Server")
        if TargetPlayerKey  then
            ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:AddTalentPoints(): AddTalentPoints for TargetPlayerKey = %s", TargetPlayerKey))
            local PlayerController = UGCGameSystem.GetPlayerControllerByPlayerKey(TargetPlayerKey)
            if PlayerController then
                ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:AddTalentPoints(): AddTalentPoints for PlayerController = %s", PlayerController))
                local Component = PlayerController:GetComponentByClass(self.TalentTreeComponentClass)
                if Component then
                    ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:AddTalentPoints(): AddTalentPoints for Component = %s", Component))
                    Component:AddTalentPoints(TalentPoints)
                end
            end
        else
            local AllPlayerControllers = UGCGameSystem.GetAllPlayerController()
            for _, PlayerController in pairs(AllPlayerControllers) do
                local Component = PlayerController:GetComponentByClass(self.TalentTreeComponentClass)
                if Component then
                    Component:AddTalentPoints(TalentPoints)
                end
            end
        end
    else
        if not self.PlayerController or not self.TalentTreeComponent then
            ugcprint("[Error] Missing controller/component reference")
            return false
        end

        UnrealNetwork.CallUnrealRPC(self.PlayerController, self.TalentTreeComponent, "Server_AddTalentPoints", self.PlayerKey, TalentPoints)
    end
end

function TalentTreeManagerImpl:SaveTempTalentInfo()
    ugcprint("[TalentTree] TalentTreeManagerImpl:SaveTempTalentInfo()")
    self.TempTalentInfo = self:CopyTable(self.TalentInfoCache)
end

function TalentTreeManagerImpl:OpenTalentTip(TalentID, IsUnlock)
    ugcprint(string.format("TalentTreeManagerImpl:ShowTalentTip for TalentID = %d", TalentID))

    local TalentData = self:GetTalentDataByTalentID(TalentID)
    local CategoryData = self:GetCategoryDataByCategoryID(TalentData.CategoryID)

    local bTalentTipOpened = LobbyUtils.GetWidget(LobbyWidgetType.LWT_TalentTreeTipConfirm).bIsOpened

    -- 如果不是取消选择状态
    if bTalentTipOpened and TalentID ~= 0 and self.CurrentTalentID ~= TalentID and not CategoryData.CanReset then
        self:CancelChanges()
    end

    TalentData.IsUnlock = IsUnlock

    local TalentTip = nil
    if CategoryData.CanReset then
        TalentTip = LobbyUtils.GetWidget(LobbyWidgetType.LWT_TalentTreeTip)
        TalentTip:RemoveFromViewport()
        TalentTip:AddToViewport(999)
        LobbyUtils.OpenAndUpdateWidget(LobbyWidgetType.LWT_TalentTreeTip, TalentData)
    else
        TalentTip = LobbyUtils.GetWidget(LobbyWidgetType.LWT_TalentTreeTipConfirm)
        TalentTip:RemoveFromViewport()
        TalentTip:AddToViewport(999)
        LobbyUtils.OpenAndUpdateWidget(LobbyWidgetType.LWT_TalentTreeTipConfirm, TalentData)
    end

    self.TempTalentInfo = self:CopyTable(self.TalentInfoCache)
    -- 打开新的天赋面板时清空待确认计数
    self.PendingUpgradeCount = {}

    self:SelectTalent(TalentID)

    if IsUnlock then
        self:UpdateButtonState()
    end
end

function TalentTreeManagerImpl:CloseTalentTip()
    LobbyUtils.CloseWidget(LobbyWidgetType.LWT_TalentTreeTip)
    LobbyUtils.CloseWidget(LobbyWidgetType.LWT_TalentTreeTipConfirm)
    LobbyUtils.CloseWidget(LobbyWidgetType.LWT_TalentTreePopup)

    self:SelectTalent(0)
    self.TempTalentInfo = self:CopyTable(self.TalentInfoCache)
    -- 关闭面板时清空待确认计数
    self.PendingUpgradeCount = {}
end

function TalentTreeManagerImpl:OpenPopup(popupType)
    local Popup = LobbyUtils.GetWidget(LobbyWidgetType.LWT_TalentTreePopup)
    if Popup ~= nil then
        Popup:RemoveFromViewport()
        Popup:AddToViewport(999)
    else
        ugcprint("[TalentTree] TalentTreePopup is nil, cannot open popup.")
    end
    LobbyUtils.OpenAndUpdateWidget(LobbyWidgetType.LWT_TalentTreePopup, popupType)
end

function TalentTreeManagerImpl:ClosePopup()
    LobbyUtils.CloseWidget(LobbyWidgetType.LWT_TalentTreePopup)
end

function TalentTreeManagerImpl:UpdateTalentPoints()
    if self.TalentTreeComponent == nil then
        self.TalentTreeComponent = self:GetTalentTreeComponent()
    end
    
    if self.TalentTreeComponent then
        self.OnTalentPointsUpdate(self.TalentTreeComponent.TalentPoints)    
    else
        ugcprint("[TalentTree] TalentTreeComponent is nil, cannot update talent points.")
    end
end

-- 遍历并更新天赋信息
function TalentTreeManagerImpl:UpdateTalentInfo()
    if self.TalentTreeComponent == nil then
        self.TalentTreeComponent = self:GetTalentTreeComponent()
    end

    if self.TalentTreeComponent then
        -- 保存旧的缓存用于计算待确认计数的变化
        local oldCache = self:CopyTable(self.TalentInfoCache)
        
        -- 清空缓存中的所有通用天赋信息
        for TalentID, _ in pairs(self.TalentInfoCache) do
            self.TalentInfoCache[TalentID] = nil
        end

        -- 更新通用天赋信息
        for _, talentData in ipairs(self.TalentTreeComponent.GeneralTalentInfo) do
            local TalentID = talentData[1]
            local Level = talentData[2]
            self.TalentInfoCache[TalentID] = Level
        end

        -- 更新当前选择英雄的天赋信息
        for HeroID, heroTalentData in pairs(self.TalentTreeComponent.HeroTalentInfo) do
            for _, talentData in ipairs(heroTalentData) do
                local TalentID = talentData[1]
                local Level = talentData[2]
                self.TalentInfoCache[TalentID] = Level
            end
        end

        -- 根据服务器确认的等级变化，减少待确认计数
        for TalentID, newLevel in pairs(self.TalentInfoCache) do
            local oldLevel = oldCache[TalentID] or 0
            local levelIncrease = newLevel - oldLevel
            if levelIncrease > 0 and self.PendingUpgradeCount[TalentID] then
                -- 服务器确认了加点，减少待确认计数
                self.PendingUpgradeCount[TalentID] = math.max(0, self.PendingUpgradeCount[TalentID] - levelIncrease)
                ugcprint(string.format("[TalentTree] UpdateTalentInfo: TalentID=%s confirmed %d levels, remaining pending=%d", 
                    TalentID, levelIncrease, self.PendingUpgradeCount[TalentID]))
                if self.PendingUpgradeCount[TalentID] == 0 then
                    self.PendingUpgradeCount[TalentID] = nil
                end
            end
        end

        ugcprint("[TalentTree] UpdateTalentInfo")
        self.OnTalentInfoUpdate() 
    else
        ugcprint("[TalentTree] TalentTreeComponent is nil, cannot update talent info.")
    end
end

function TalentTreeManagerImpl:UpdateButtonState()
    -- 检查游戏状态，LobbyUtils.GetWidget可能返回nil
    if not UGCGameSystem or not UGCGameSystem.GameState then
        ugcprint("[TalentTree] UGCGameSystem.GameState is nil, cannot update button state.")
        return
    end

    local confirmWidget = LobbyUtils.GetWidget(LobbyWidgetType.LWT_TalentTreeTipConfirm)
    local tipWidget = LobbyUtils.GetWidget(LobbyWidgetType.LWT_TalentTreeTip)

    if not confirmWidget and not tipWidget then
        ugcprint("[TalentTree] confirmWidget or tipWidget is nil, cannot update button state.")
        return
    end

    local bTalentTipOpened = (confirmWidget and confirmWidget.bIsOpened) or
        (tipWidget and tipWidget.bIsOpened)
    if not bTalentTipOpened then
        return
    end

    if not self.CurrentTalentID or self.CurrentTalentID == 0 then
        return
    end
        
    local ButtonUpgrade = not self.TalentTreeComponent:ClientValidateTalentUpgrade(self.CurrentTalentID) and 1 or 0
    self.OnButtonStatesUpdate(true, ButtonUpgrade)   
    local ButtonReduce = not self.TalentTreeComponent:ClientValidateTalentReduce(self.CurrentTalentID) and 1 or 0 
    self.OnButtonStatesUpdate(false, ButtonReduce)
end

function TalentTreeManagerImpl:UpdateSelectedHero()
    local PlayerKey = UGCGameSystem.GetLocalPlayerKey()
    local SelectedHeroID = HeroSelectionManager:GetSelectedHeroID(PlayerKey)

    for HeroIdx, HeroID in pairs(self.IdxToHeroIDMap) do 
        if HeroID == SelectedHeroID then
            self.CurrentHeroIdx = HeroIdx
        end
    end
end

function TalentTreeManagerImpl:GetTalentPoints()
    ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:GetTalentPoints, TalentPoints = %s", self.TalentTreeComponent.TalentPoints))
    return self.TalentTreeComponent.TalentPoints
end

function TalentTreeManagerImpl:HasAvailableTalentPoints()
    return self.TalentTreeComponent.TalentPoints > 0
end

function TalentTreeManagerImpl:GetTalentLevel(TalentID)
    if TalentID then
        return self.TalentInfoCache[TalentID]
    else
        return 0        
    end
end

function TalentTreeManagerImpl:GetSelectedTabIdx()
    return self.CurrentTabIdx
end

function TalentTreeManagerImpl:GetSelectedHeroIdx()
    return self.CurrentHeroIdx
end

function TalentTreeManagerImpl:GetTalentPointsByLevel()
    return self.TalentPointsByLevel
end

function TalentTreeManagerImpl:HasTalentSkillsForHero(HeroID)
    ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:HasTalentSkillsForHero, HeroID = %s", HeroID))
    if not self.bInitialized or not HeroID then
        ugcprint("[TalentTree] TalentTreeManagerImpl:HasTalentSkillsForHero, TalentTreeManager is not initialized or HeroID is nil.")
        return false
    end

    local CatogoryID = self.HeroIDToCategoryIDMap[HeroID]
    if not CatogoryID then
        ugcprint("[TalentTree] TalentTreeManagerImpl:HasTalentSkillsForHero, HeroID is not found in HeroIDToCategoryIDMap.")
        return false
    end

    local TalentIDs = self:GetTalentIDsByCategoryID(CatogoryID)
    if not TalentIDs then
        ugcprint("[TalentTree] TalentTreeManagerImpl:HasTalentSkillsForHero, TalentIDs is nil.")
        return false
    end

    self:UpdateTalentInfo()

    for _, TalentID in ipairs(TalentIDs) do
        local TalentData = self:GetTalentDataByTalentID(TalentID)
        ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:HasTalentSkillsForHero, TalentID = %s", TalentID))
        if TalentData and TalentData.Skills and #TalentData.Skills > 0 then
            -- 检查该天赋是否已生效（等级 > 0）
            ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:HasTalentSkillsForHero, TalentData = %s", TalentData))
            if (self.TalentInfoCache[TalentID] or 0) > 0 then
                ugcprint("[TalentTree] TalentTreeManagerImpl:HasTalentSkillsForHero, TalentData.Skills is not nil.")
                return true
            end
        end
    end

    ugcprint("[TalentTree] TalentTreeManagerImpl:HasTalentSkillsForHero, TalentData.Skills is nil.")
    return false
end

function TalentTreeManagerImpl:HasAdditionalPoints(TalentID)
    if not TalentID then return false end

    local currentLevel = self.TalentInfoCache[TalentID] or 0
    local initialLevel = self.TempTalentInfo[TalentID] or 0
    return currentLevel > initialLevel
end

function TalentTreeManagerImpl:SubUTF8String(str, maxChars)
    local currentLength = 0
    local result = ""

    for _, char in utf8.codes(str) do
        if currentLength >= maxChars then
            break
        end
        local utf8Char = utf8.char(char)
        result = result .. utf8Char
        currentLength = currentLength + 1
    end

    return result
end

function TalentTreeManagerImpl:ShowNotice(FailureReason)
    if FailureReason == ETalentReduceFailure.NotHeroUnlocked then
        UGCWidgetManagerSystem.ShowTipsUI("英雄未解锁")
    end    
end

function TalentTreeManagerImpl:CopyTable(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = v
    end
    return copy
end

return TalentTreeManagerImpl