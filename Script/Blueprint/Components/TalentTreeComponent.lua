---@class TalentTreeComponent_C:ActorComponent
--Edit Below--
UGCGameSystem.UGCRequire("Script.Blueprint.Arts_UI.Lobby.TalentTreeManager")
UGCGameSystem.UGCRequire("Script.Blueprint.Arts_UI.Lobby.UIBP.TalentTree.Test.TalentTreeTestManager")

local TalentTreeComponent = {
    -- Replicate
    TalentPoints = 0,
    GeneralTalentInfo = {},
    HeroTalentInfo = {},
    SelectedHeroID = 0,     -- UI选中的英雄ID，局内英雄以PlayerState为准
}


function TalentTreeComponent:ReceiveBeginPlay()
    ugcprint("[TalentTree] TalentTreeComponent:ReceiveBeginPlay")
    TalentTreeComponent.SuperClass.ReceiveBeginPlay(self)

    TalentTreeManager:Init(self)
    TalentTreeManager:RegisterTalentTreeComponentClass(UGCObjectUtility.GetObjectClass(self))

    if UGCActorComponentUtility.HasAuthority(UGCActorComponentUtility.GetOwner(self)) == true then
        --- 如果PlayerKey是0说明PC的玩家信息还没初始化完，需要在PostLogin后LoadPlayerData
        if UGCGameSystem.GetPlayerKeyByPlayerController(UGCActorComponentUtility.GetOwner(self)) == 0 then
            if UGCGameSystem.GetSTExtraGMDelegatesMgr() and UGCGameSystem.GetSTExtraGMDelegatesMgr().GetInstance() then
                UGCGameSystem.GetSTExtraGMDelegatesMgr().GetInstance().OnPlayerPostLoginDelegate:AddInstance(self.LoadData, self)
                UGCGameSystem.GetSTExtraGMDelegatesMgr().GetInstance().OnPlayerPostLoginDelegate:AddInstance(self.ListenLevel, self)
                UGCGameSystem.GetSTExtraGMDelegatesMgr().GetInstance().OnPlayerPostLoginDelegate:AddInstance(self.ListenMessage, self)
            end
        else
            self:LoadData()
            self:ListenLevel()
            self:ListenMessage()
        end

    else
        TalentTreeTestManager:Init(self)
    end

    self:ListenMessage()
end

function TalentTreeComponent:GetReplicatedProperties()
    return
        {"TalentPoints", "Lazy"},
        {"GeneralTalentInfo", "Lazy"},
        {"HeroTalentInfo", "Lazy"},
        {"SelectedHeroID","Lazy"}
end

function TalentTreeComponent:GetAvailableServerRPCs()
    return "Server_ApplySkills", "Server_ApplyBuffs", "Server_ApplyAttributes", "Server_SelectHero", "Server_ResetTalentCategory", "Server_SetTalentPoints", "Server_AddTalentPoints", "Server_UpgradeTalent", "Server_ReduceTalent", "Server_TestRPC"
end

--[[----------------------------------------------------- ServerRPC ------------------------------------------------------]]--

function TalentTreeComponent:Server_ApplySkills(TalentID,  TargetPawn)
    self:ApplySkills(TalentID, TargetPawn)
end

function TalentTreeComponent:ApplySkills(TalentID, TargetPawn)
    ugcprint("[TalentTree] TalentTreeComponent:ApplySkills(): TalentID = " .. TalentID .. ", TargetPawn = " .. tostring(TargetPawn)) 
    if not TargetPawn then
        return
    end

    local Skills = TalentTreeManager:GetTalentDataByTalentID(TalentID).Skills

    if Skills then
        local PlayerData = self:LoadPlayerData()
        local TalentData = TalentTreeManager:GetTalentDataByTalentID(TalentID)
        local CategoryData = TalentTreeManager:GetCategoryDataByCategoryID(TalentData.CategoryID)
        local HeroID = PlayerData["HeroID"]

        local TalentLevel = self:GetCurrentTalentLevel(TalentID, CategoryData.IsGeneral, HeroID)

        if TalentLevel and TalentLevel > 0 and TalentLevel <= #Skills then
            local SelectedSkill = Skills[TalentLevel]
            if SelectedSkill then
                UGCPersistEffectSystem.AddSkillByClass(TargetPawn, SelectedSkill, -2.0)
            else
                ugcprint("[TalentTree] TalentTreeComponent:ApplySkills(): No Skill found for TalentLevel = " .. TalentLevel)
            end
        else
            ugcprint("[TalentTree] TalentTreeComponent:ApplySkills(): Invalid TalentLevel = " .. tostring(TalentLevel) .. ", or Skills table is empty.")
        end
    end
end

function TalentTreeComponent:Server_ApplyBuffs(TalentID, TargetPawn)
    ugcprint("[TalentTree] TalentTreeComponent:Server_ApplyBuffs")
    self:ApplyBuffs(TalentID, TargetPawn)
end

function TalentTreeComponent:ApplyBuffs(TalentID, TargetPawn)
    ugcprint(string.format("[TalentTree] TalentTreeComponent:ApplyBuffs: TalentID = %s, TargetPawn = %s", TalentID, TargetPawn))
    if not TargetPawn then
        return
    end

    local Buffs = TalentTreeManager:GetTalentDataByTalentID(TalentID).Buffs

    ugcprint("[TalentTree] TalentTreeComponent:Buffs")

    if Buffs then
        local PlayerData = self:LoadPlayerData()
        if not PlayerData then
            ugcprint("[Error] Failed to load PlayerData in ApplyBuffs.")
            return
        end
        local TalentData = TalentTreeManager:GetTalentDataByTalentID(TalentID)
        local CategoryData = TalentTreeManager:GetCategoryDataByCategoryID(TalentData.CategoryID)
        local HeroID = PlayerData["HeroID"]

        if not PlayerData then
            ugcprint("[Error] PlayerData is nil Before GetCurrentTalentLevel.")
        else
            ugcprint("[Debug] PlayerData loaded successfully.")
        end

        local TalentLevel = self:GetCurrentTalentLevel(TalentID, CategoryData.IsGeneral, HeroID)

        -- 检查TalentLevel是否有效
        if TalentLevel and TalentLevel > 0 and TalentLevel <= #Buffs then
            -- 取出对应等级的Buffs
            local SelectedBuff = Buffs[TalentLevel]
            if SelectedBuff then
                UGCPersistEffectSystem.AddBuffByClass(TargetPawn, SelectedBuff, -2.0)
            else
                ugcprint("[TalentTree] TalentTreeComponent:ApplyBuffs(): No Buff found for TalentLevel = " .. TalentLevel)
            end
        else
            ugcprint("[TalentTree] TalentTreeComponent:ApplyBuffs(): Invalid TalentLevel = " .. tostring(TalentLevel) .. ", or Buffs table is empty.")
        end
    end
end

function TalentTreeComponent:Server_ApplyAttributes(TalentID, TargetPawn)
    self:ApplyAttributes(TalentID, TargetPawn)
end

function TalentTreeComponent:ApplyAttributes(TalentID, TargetPawn)
    ugcprint("[TalentTree] TalentTreeComponent:ApplyAttributes")
    if not TargetPawn then
        return
    end

    local Attributes = TalentTreeManager:GetTalentDataByTalentID(TalentID).Attributes

    if Attributes then
        local PlayerData = self:LoadPlayerData()

        if not PlayerData then
            ugcprint("[Error] Failed to load PlayerData in ApplyAttributes.")
            return
        end

        local TalentData = TalentTreeManager:GetTalentDataByTalentID(TalentID)
        local CategoryData = TalentTreeManager:GetCategoryDataByCategoryID(TalentData.CategoryID)
        local HeroID = PlayerData["HeroID"]

        if not PlayerData then
            ugcprint("[Error] PlayerData is nil Before GetCurrentTalentLevel.")
        else
            ugcprint("[Debug] PlayerData loaded successfully.")
        end

        local TalentLevel = self:GetCurrentTalentLevel(TalentID, CategoryData.IsGeneral, HeroID)

        -- 检查TalentLevel是否有效
        if TalentLevel and TalentLevel > 0 and TalentLevel <= #Attributes then
            -- 取出对应等级的Attribute
            local SelectedAttribute = Attributes[TalentLevel]
            if SelectedAttribute then
                ugcprint("[TalentTree] TalentTreeComponent:ApplyAttributes(): Applying Attribute for TalentLevel = " .. TalentLevel .. ", Attribute = " .. tostring(SelectedAttribute.GameAttribute.AttributeName) .. ", Value = " .. tostring(SelectedAttribute.InitialValue))
                UGCAttributeSystem.SetGameAttributeValue(TargetPawn, SelectedAttribute.GameAttribute.AttributeName, SelectedAttribute.InitialValue)
            else
                ugcprint("[TalentTree] TalentTreeComponent:ApplyAttributes(): No Attribute found for TalentLevel = " .. TalentLevel)
            end
        else
            ugcprint("[TalentTree] TalentTreeComponent:ApplyAttributes(): Invalid TalentLevel = " .. tostring(TalentLevel) .. ", or Attributes table is empty.")
        end
    end
end

function TalentTreeComponent:Server_UpgradeTalent(PlayerKey, TalentID)
    ugcprint(string.format("[TalentTree] TalentTreeComponent:Server_UpgradeTalent(): TalentID = %s" , TalentID))

    local Data = self:GetTalentValidationData(TalentID)
    if not Data then
        ugcprint(string.format("[TalentTree] Upgrade validation failed for TalentID: %s" , TalentID))
        return
    end

    local ValidationResult = self:ValidateTalentUpgrade(TalentID)
    if not ValidationResult then
        ugcprint("[TalentTree] Upgrade validation failed for TalentID: %d" .. TalentID)
        return
    end

    self:UpgradeTalent(Data.PlayerData, TalentID, Data.CategoryData)
    self:SavePlayerData(Data.PlayerData)
end

--- 升级天赋
---@param PlayerData @玩家数据
---@param TalentID int32 @天赋ID
---@param CategoryData UGCTalentCategory @要升级的的天赋数据
function TalentTreeComponent:UpgradeTalent(PlayerData, TalentID, CategoryData)
    print(string.format("[TalentTree] TalentTreeComponent:UpgradeTalent(): TalentID = %d", TalentID))
    local Upgraded = false

    if CategoryData.IsGeneral then
        print(string.format("[TalentTree] TalentTreeComponent:UpgradeTalent(): General Talent"))
        for _, talentInfo in ipairs(PlayerData["TalentTree"].GeneralTalentInfo) do
            if talentInfo[1] == TalentID then
                talentInfo[2] = talentInfo[2] + 1
                Upgraded = true
                print(string.format("[TalentTree] TalentTreeComponent:UpgradeTalent(): TalentID = %d, TalentLevel = %d", TalentID, talentInfo[2]))
                break
            end
        end
        if not Upgraded then
            table.insert(PlayerData["TalentTree"].GeneralTalentInfo, {TalentID, 1})
            print(string.format("[TalentTree] TalentTreeComponent:UpgradeTalent(): TalentID = %d, TalentLevel = 1", TalentID))
        end
        self.GeneralTalentInfo = PlayerData["TalentTree"].GeneralTalentInfo
        UnrealNetwork.RepLazyProperty(self, "GeneralTalentInfo")
    else
        print(string.format("[TalentTree] TalentTreeComponent:UpgradeTalent(): Hero Talent"))
        local HeroID = PlayerData["TalentTree"].SelectedHeroID
        print(string.format("[TalentTree] TalentTreeComponent:UpgradeTalent(): HeroID = %d", HeroID))
        if not PlayerData["TalentTree"].HeroTalentInfo[HeroID] then
            PlayerData["TalentTree"].HeroTalentInfo[HeroID] = {}
        end
        local HeroTalents = PlayerData["TalentTree"].HeroTalentInfo[HeroID]
        for _, talentInfo in ipairs(HeroTalents) do
            print(string.format("[TalentTree] TalentTreeComponent:UpgradeTalent(): TalentID = %d", TalentID))
            if talentInfo[1] == TalentID then
                talentInfo[2] = talentInfo[2] + 1
                Upgraded = true
                print(string.format("[TalentTree] TalentTreeComponent:UpgradeTalent(): TalentID = %d, TalentLevel = %d", TalentID, talentInfo[2]))
                break
            end
        end
        if not Upgraded then
            table.insert(HeroTalents, {TalentID, 1})
            print(string.format("[TalentTree] TalentTreeComponent:UpgradeTalent(): TalentID = %d, TalentLevel = 1", TalentID))
        end
        self.HeroTalentInfo = PlayerData["TalentTree"].HeroTalentInfo
        UnrealNetwork.RepLazyProperty(self, "HeroTalentInfo")
    end

    PlayerData["TalentTree"].TalentPoints = PlayerData["TalentTree"].TalentPoints - 1
    self.TalentPoints = PlayerData["TalentTree"].TalentPoints
    UnrealNetwork.RepLazyProperty(self, "TalentPoints")

    print(string.format("[TalentTree] TalentTreeComponent:UpgradeTalent(): TalentPoints = %d", PlayerData["TalentTree"].TalentPoints))
end

--- 服务端完整验证
---@param TalentID int32 @Talent ID
---@return boolean @验证结果
---生效范围：服务器
function TalentTreeComponent:ValidateTalentUpgrade(TalentID)
    local Data = self:GetTalentValidationData(TalentID)
    if not Data then 
        ugcprint(string.format("[TalentTree] Upgrade validation failed for TalentID: %d", TalentID))
        return
    end

    if not self:ValidatePrerequisites(Data.PlayerData, Data.TalentData, Data.CategoryData) then
        ugcprint("[TalentTree] Not meeting the preconditions")
        return false
    end

    if not self:ValidateTalentPoints(Data.PlayerData) then
        ugcprint("[TalentTree] Not enough talent points")
        return false
    end

    local HeroID = Data.HeroID
    local CurrentTalentLevel = self:GetCurrentTalentLevel(TalentID, Data.CategoryData.IsGeneral, HeroID)
    if not self:ValidateMaxLevel(CurrentTalentLevel, Data.TalentData.MaxLevel, TalentID) then
        ugcprint("[TalentTree] Has reached the maximum level")
        return false
    end

    if self:ValidateHeroLocked(self.SelectedHeroID) then
        ugcprint("[TalentTree] Hero not unlocked")
        return false
    end

    return true
end

--- 客户端快速验证是否可升级（使用复制数据）
---@param TalentID int32 @Talent ID
---@return boolean @可升级时返回true
---生效范围：客户端
function TalentTreeComponent:ClientValidateTalentUpgrade(TalentID)
    local Data = self:GetClientValidationData(TalentID)
    if not Data then return false end
    
    return self.TalentPoints > 0
        and not self:ValidateHeroLocked(self.SelectedHeroID)
        and self:GetClientTalentLevel(TalentID, Data.CategoryData.IsGeneral) < Data.TalentData.MaxLevel
        and not self:IsInMatchingState()
end

--- 返还选中天赋的天赋点
function TalentTreeComponent:Server_ReduceTalent(PlayerKey, TalentID)
    ugcprint(string.format("[TalentTree] TalentTreeComponent:Server_ReduceTalent(): TalentID = %s", TalentID))

    local Data = self:GetTalentValidationData(TalentID)
    if not Data then 
        ugcprint(string.format("[TalentTree] Reduce validation failed for TalentID: %d", TalentID))
        return
    end

    if not self:ValidateTalentReduce(TalentID) then
        return
    end
    
    -- 执行返还逻辑
    if Data.CategoryData.IsGeneral then
        for _, talentInfo in ipairs(Data.PlayerData["TalentTree"].GeneralTalentInfo) do
            if talentInfo[1] == TalentID then
                talentInfo[2] = talentInfo[2] - 1
                break
            end
        end

        self.GeneralTalentInfo = Data.PlayerData["TalentTree"].GeneralTalentInfo
        UnrealNetwork.RepLazyProperty(self, "GeneralTalentInfo")
    else
        local HeroID = Data.PlayerData["TalentTree"].SelectedHeroID
        local HeroTalents = Data.PlayerData["TalentTree"].HeroTalentInfo[HeroID]
        for _, talentInfo in ipairs(HeroTalents) do
            if talentInfo[1] == TalentID then
                talentInfo[2] = talentInfo[2] - 1
                break
            end
        end

        self.HeroTalentInfo = Data.PlayerData["TalentTree"].HeroTalentInfo
        UnrealNetwork.RepLazyProperty(self, "HeroTalentInfo")
    end

    Data.PlayerData["TalentTree"].TalentPoints = Data.PlayerData["TalentTree"].TalentPoints + 1
    self.TalentPoints = Data.PlayerData["TalentTree"].TalentPoints
    UnrealNetwork.RepLazyProperty(self, "TalentPoints")
    self:SavePlayerData(Data.PlayerData)
    ugcprint(string.format("[TalentTree] TalentID = %s has been reduce for PlayerKey = %s", TalentID, PlayerKey))
    return true
end

--- 服务端完整验证
---@param TalentID int32 @Talent ID
---@return boolean @验证结果
---生效范围：服务端
function TalentTreeComponent:ValidateTalentReduce(TalentID)
    local Data = self:GetTalentValidationData(TalentID)
    if not Data then
        ugcprint(string.format("[TalentTree] No TalentValidationData found for TalentID = %s", TalentID))
        return false
    end

    -- 检查天赋是否属于最后一层
    if Data.CategoryData.CanReset then
        if not self:ValidateLastUnlockedLayer(Data.PlayerData, Data.TalentData, Data.CategoryData, Data.LayeredData) then
            ugcprint(string.format("[TalentTree] The current talent is not in the last unlocked layer for TalentID = %s", TalentID))
            return false
        end
    end

    -- 检查天赋等级是否大于0
    if not self:ValidateLevel(Data.PlayerData, Data.TalentData, Data.CategoryData) then
        ugcprint(string.format("[TalentTree] Level is less than or equal to 0 for TalentID = %s", TalentID))
        return false
    end

    return true
end

--- 客户端快速验证是否可减级（使用复制数据）
---@param TalentID int32 @Talent ID to validate
---@return boolean @Validation result
---生效范围：客户端
function TalentTreeComponent:ClientValidateTalentReduce(TalentID)
    local Data = self:GetClientValidationData(TalentID)
    if not Data then
        ugcprint("[TalentTree][Client] Validation data not available")
        return false 
    end

    -- 使用客户端已有的复制数据验证基础条件
    local currentLevel = self:GetClientTalentLevel(TalentID, Data.CategoryData.IsGeneral)
    if currentLevel <= 0 then return false end
    
    if self:IsInMatchingState() then return false end
    if self:ValidateHeroLocked(self.SelectedHeroID) then return false end
    
    if Data.CategoryData.CanReset then
        -- 对于能重置的类别，检查是否在最后加点的层
        if not self:IsTalentInLastUpgradedLayer(TalentID, Data) then return false end
    else
        -- 对于不能重置的类别，检查是否比打开面板时的初始等级高
        if not TalentTreeManager:HasAdditionalPoints(TalentID) then return false end
    end
    
    return true
end

--- 重置选中页签的天赋
function TalentTreeComponent:Server_ResetTalentCategory(PlayerKey, CategoryID)
    ugcprint(string.format("[TalentTree] TalentTreeComponent:ResetTalentCategory(): Resetting talents for PlayerKey = %s, CategoryID = %s", PlayerKey, CategoryID))

    local PlayerData = self:LoadPlayerData(PlayerKey)
    if not PlayerData then
        ugcprint(string.format("[TalentTree] No PlayerData found for PlayerKey = %s", PlayerKey))
        return
    end 

    -- 获取对应的 TalentCategory
    local CategoryData = TalentTreeManager:GetCategoryDataByCategoryID(CategoryID)

    -- 重置天赋并返回天赋点
    local TalentsToRemove = {}
    local TalentDataMap = TalentTreeManager:GetTalentDataMap()
    if CategoryData.IsGeneral then
        -- 通用天赋
        for index, talentInfo in ipairs(PlayerData["TalentTree"].GeneralTalentInfo) do
            local TalentID, TalentLevel = talentInfo[1], talentInfo[2]
            if TalentDataMap[TalentID].CategoryID == CategoryID then
                table.insert(TalentsToRemove, index)
                PlayerData["TalentTree"].TalentPoints = PlayerData["TalentTree"].TalentPoints + TalentLevel
            end
        end
        -- 移除天赋
        for i = #TalentsToRemove, 1, -1 do
            table.remove(PlayerData["TalentTree"].GeneralTalentInfo, TalentsToRemove[i])
        end

        self.GeneralTalentInfo = PlayerData["TalentTree"].GeneralTalentInfo
        UnrealNetwork.RepLazyProperty(self, "GeneralTalentInfo")
    else
        -- 英雄专属天赋
        local HeroID = PlayerData["TalentTree"].SelectedHeroID
        if PlayerData["TalentTree"].HeroTalentInfo[HeroID] then
            for index, talentInfo in ipairs(PlayerData["TalentTree"].HeroTalentInfo[HeroID]) do
                local TalentID, TalentLevel = talentInfo[1], talentInfo[2]
                if TalentDataMap[TalentID].CategoryID == CategoryID then
                    table.insert(TalentsToRemove, index)
                    PlayerData["TalentTree"].TalentPoints = PlayerData["TalentTree"].TalentPoints + TalentLevel
                end
            end
            -- 移除天赋
            for i = #TalentsToRemove, 1, -1 do
                table.remove(PlayerData["TalentTree"].HeroTalentInfo[HeroID], TalentsToRemove[i])
            end
        end

        self.HeroTalentInfo = PlayerData["TalentTree"].HeroTalentInfo
        UnrealNetwork.RepLazyProperty(self, "HeroTalentInfo")
    end

    self.TalentPoints = PlayerData["TalentTree"].TalentPoints
    UnrealNetwork.RepLazyProperty(self, "TalentPoints")
    self:SavePlayerData(PlayerData)
    ugcprint(string.format("[TalentTree] TalentCategory ID = %s has been reset for PlayerKey = %s", CategoryID, PlayerKey))
    return true
end

--- 设置某个玩家当前选中的英雄
function TalentTreeComponent:Server_SelectHero(PlayerKey, SelectedHeroID)
    ugcprint(string.format("[TalentTree] TalentTreeComponent:Server_SelectHero(): Setting SelectedHeroID = %s for PlayerKey = %s", SelectedHeroID, PlayerKey))

    local PlayerData = self:LoadPlayerData()
    if not PlayerData then
        return false
    end

    PlayerData["TalentTree"].SelectedHeroID = SelectedHeroID
    self.SelectedHeroID = SelectedHeroID
    UnrealNetwork.RepLazyProperty(self, "SelectedHeroID")

    self:SavePlayerData(PlayerData)
end

--- 设置当前的天赋点
function TalentTreeComponent:Server_SetTalentPoints(PlayerKey, TalentPoints)
    ugcprint(string.format("[TalentTree] TalentTreeComponent:Server_SetTalentPoints(): Setting TalentPoints = %s for PlayerKey = %s", TalentPoints, PlayerKey))

    local PlayerData = self:LoadPlayerData()
    if not PlayerData then
        return false
    end

    PlayerData["TalentTree"].TalentPoints = TalentPoints
    self.TalentPoints = PlayerData["TalentTree"].TalentPoints
    UnrealNetwork.RepLazyProperty(self, "TalentPoints")

    self:SavePlayerData( PlayerData)
end

--- 增加天赋点
function TalentTreeComponent:Server_AddTalentPoints(PlayerKey, TalentPoints)
    if not UGCGameSystem.IsUGCPIE() and not UGCGameSystem.IsOuterlineDEV() then
        -- 上行RPC安全处理规范，涉及到Server的RPC，需要在Server端进行安全检查或者校验，不能随意调用
        return
    end
    ugcprint(string.format("[TalentTree] TalentTreeComponent:Server_AddTalentPoints(): Adding TalentPoints = %s for PlayerKey = %s", TalentPoints, PlayerKey))
    self:AddTalentPoints(TalentPoints)
end

function TalentTreeComponent:AddTalentPoints(TalentPoints)
    if not UGCGameSystem:IsServer() then
        ugcprint("[TalentTree][Error] AddTalentPoints called on client")
        return false
    end

    -- local ownerKey = UGCGameSystem.GetPlayerKeyByPlayerController(UGCActorComponentUtility.GetOwner(self))
    -- if PlayerKey ~= ownerKey then
    --     ugcprint(string.format("[TalentTree] TalentTreeComponent:AddTalentPoints(): PlayerKey = %s is not equal to self.PlayerKey = %s", PlayerKey, ownerKey))
    --     return false
    -- end

    local PlayerData = self:LoadPlayerData()
    if not PlayerData then
        return false
    end

    local CurrentTalentPoints = PlayerData["TalentTree"].TalentPoints
    PlayerData["TalentTree"].TalentPoints = CurrentTalentPoints + TalentPoints
    self.TalentPoints = PlayerData["TalentTree"].TalentPoints
    UnrealNetwork.RepLazyProperty(self, "TalentPoints")

    return self:SavePlayerData(PlayerData)
end

--[[----------------------------------------------------- Data ------------------------------------------------------]]--

--- 加载并同步
function TalentTreeComponent:LoadData()
    ugcprint("[TalentTree] TalentTreeComponent:LoadData()")
    local TalentTreeData = self:LoadPlayerData()["TalentTree"]

    self.TalentPoints = TalentTreeData.TalentPoints

    UnrealNetwork.RepLazyProperty(self, "TalentPoints")
    ugcprint("[TalentTree] TalentTreeComponent:LoadData(): UnrealNetwork.RepLazyProperty TalentPoints")

    self.GeneralTalentInfo = TalentTreeData.GeneralTalentInfo
    self.HeroTalentInfo = TalentTreeData.HeroTalentInfo
    UnrealNetwork.RepLazyProperty(self, "GeneralTalentInfo")
    UnrealNetwork.RepLazyProperty(self, "HeroTalentInfo")

    local PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(UGCActorComponentUtility.GetOwner(self))
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerKey(PlayerKey)
    self.SelectedHeroID = PlayerState.HeroID
    UnrealNetwork.RepLazyProperty(self, "SelectedHeroID")
    ugcprint("[TalentTree] TalentTreeComponent:LoadData(): UnrealNetwork.RepLazyProperty TalentInfo")
end

--- 加载玩家数据
function TalentTreeComponent:LoadPlayerData()
    ugcprint("[TalentTree] TalentTreeComponent:LoadPlayerData()")
    if UGCActorComponentUtility.HasAuthority(UGCActorComponentUtility.GetOwner(self)) == false then
        return
    end

    local UID = UGCGameSystem.GetUIDByPlayerController(UGCActorComponentUtility.GetOwner(self))
    ugcprint(string.format("[TalentTree] TalentTreeComponent:Begin read UID: %d PlayerData", UID))

    local PlayerData = UGCPlayerStateSystem.GetPlayerArchiveData(UID)

    local bChanged = false
    if PlayerData == nil then
        ugcprint(string.format("[TalentTree] TalentTreeComponent: UID: %d PlayerData is empty, creating new one.", UID))
        PlayerData = {
            TalentTree = {
                GeneralTalentInfo = {},    -- 通用天赋列表，{TalentID, Level}
                HeroTalentInfo = {},       -- 所有英雄天赋，HeroID -> {TalentID, Level}天赋列表的映射
                SelectedHeroID = 0,       -- 当前选择的英雄ID
                TalentPoints = 0,         -- 玩家剩余的天赋点
            }
        }
        bChanged = true
    end

    if PlayerData["TalentTree"] == nil then
        PlayerData["TalentTree"] = {
            GeneralTalentInfo = {},
            HeroTalentInfo = {},
            SelectedHeroID = 0,
            TalentPoints = 0,
        }
        bChanged = true
    end

    if PlayerData["TalentTree"].GeneralTalentInfo == nil then
        PlayerData["TalentTree"].GeneralTalentInfo = {}
        bChanged = true
    end

    if PlayerData["TalentTree"].HeroTalentInfo == nil then
        PlayerData["TalentTree"].HeroTalentInfo = {}
        bChanged = true
    end

    if PlayerData["TalentTree"].SelectedHeroID == nil then
        PlayerData["TalentTree"].SelectedHeroID = 0
        bChanged = true
    end

    if PlayerData["TalentTree"].TalentPoints == nil then
        PlayerData["TalentTree"].TalentPoints = 0
        bChanged = true
    end

    if bChanged == true then
        UGCPlayerStateSystem.SavePlayerArchiveData(UID, PlayerData)
    end

    ugcprint(string.format("[TalentTree] TalentTreeComponent: Read UID: %d PlayerData Success", UID))

    return PlayerData
end

--- 保存玩家数据
--- @param PlayerData table
function TalentTreeComponent:SavePlayerData(PlayerData)
    if UGCActorComponentUtility.HasAuthority(UGCActorComponentUtility.GetOwner(self)) == false then
        return false
    end

    local UID = UGCGameSystem.GetUIDByPlayerController(UGCActorComponentUtility.GetOwner(self))
    local bSuccess = UGCPlayerStateSystem.SavePlayerArchiveData(UID, PlayerData)

    if bSuccess == true then
        ugcprint(string.format("TalentTreeModel:Save UID:%d PlayerData Success", UID));
    else
        ugcprint(string.format("TalentTreeModel:Save UID:%d PlayerData Failed", UID));
    end

    return bSuccess
end

function TalentTreeComponent:SetTalentPoints(InTalentPoints)
    self.TalentPoints = InTalentPoints
    UnrealNetwork.RepLazyProperty(self, "TalentPoints")
    ugcprint("[TalentTree] TalentTreeComponent:SetTalentPoints(): UnrealNetwork.RepLazyProperty TalentPoints")
end

--[[----------------------------------------------------- Gameplay ------------------------------------------------------]]--

--- 在玩家出生或复活时，过滤天赋并应用
function TalentTreeComponent:ApplyFilteredTalents(PlayerKey)
    ugcprint("[TalentTree] TalentTreeComponent:ApplyFilteredTalents")
    local PlayerData = self:LoadPlayerData() 
    local SelectedHeroID = PlayerData["HeroID"]
    local AllTalents = {}

    -- 加入通用天赋
    for _, talentInfo in ipairs(PlayerData["TalentTree"].GeneralTalentInfo) do
        ugcprint(string.format("[TalentTree] ApplyGeneralTalents TalentID: %d, Level: %d", talentInfo[1], talentInfo[2]))
        table.insert(AllTalents, talentInfo)
    end

    -- 加入选中英雄的天赋
    if SelectedHeroID then
        local HeroTalentData = PlayerData["TalentTree"].HeroTalentInfo[SelectedHeroID]
        if HeroTalentData then
            ugcprint(string.format("[TalentTree] Selected HeroID: %d", SelectedHeroID))
            for _, herotalentInfo in ipairs(HeroTalentData) do
                ugcprint(string.format("[TalentTree] ApplyHeroTalents TalentID: %d, Level: %d", herotalentInfo[1], herotalentInfo[2]))
                table.insert(AllTalents, herotalentInfo)
            end
        else
            ugcprint("[TalentTree] No HeroTalentData found for SelectedHeroID: "..tostring(SelectedHeroID))
        end
    else
        ugcprint(string.format("[TalentTree] SelectedHeroID is nil"))
    end

    self.TargetPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(PlayerKey)
    ugcprint(string.format("[TalentTree] TargetPawn: %s", tostring(self.TargetPawn)))

    ugcprint(string.format("[TalentTree] Applying %d talents", #AllTalents))
    for _, talentInfo in ipairs(AllTalents) do
        local TalentID = talentInfo[1]
        local TalentLevel = talentInfo[2]

        ugcprint(string.format("[TalentTree] TalentID: %d, Level: %d", TalentID, TalentLevel))

        self:ApplySkills(TalentID, self.TargetPawn)
        self:ApplyBuffs(TalentID, self.TargetPawn)
        self:ApplyAttributes(TalentID, self.TargetPawn)
    end
end

--- 获取天赋等级
---@param TalentID int32 @要升级的的天赋的ID
---@param isGeneral bool @是否是通用天赋
---@param HeroID int32   @当isGeneral=false时，需要传入当前英雄ID
---生效范围：服务器
function TalentTreeComponent:GetCurrentTalentLevel(TalentID, isGeneral, HeroID)
    ugcprint(string.format("[TalentTree] TalentTreeComponent:GetCurrentTalentLevel, TalentID: %d", TalentID))
    local PlayerData = self:LoadPlayerData()

    if not PlayerData then
        ugcprint("[TalentTree] PlayerData is nil")
        return 0
    end

    local CurrentTalentLevel = 0
    if isGeneral then
        ugcprint("[TalentTree] isGeneral")
        for _, talentInfo in ipairs(PlayerData["TalentTree"].GeneralTalentInfo) do
            if talentInfo[1] == TalentID then
                CurrentTalentLevel = talentInfo[2]
                ugcprint(string.format("[TalentTree] Find TalentID: %d, Level: %d", TalentID, CurrentTalentLevel))
                break
            end
        end
    else
        if not HeroID then
            ugcprint("[TalentTree] Error: HeroID parameter is required to query Hero Talent")
            return 0
        end

        ugcprint(string.format("[TalentTree] Selected HeroID: %d", HeroID))
        local HeroTalents = PlayerData["TalentTree"].HeroTalentInfo[HeroID]
        if HeroTalents then
            ugcprint(string.format("[TalentTree] HeroTalents: %s", tostring(HeroTalents)))
            for _, talentInfo in ipairs(HeroTalents) do
                ugcprint(string.format("[TalentTree] TalentInfo: ID:%d, Level:%d", talentInfo[1], talentInfo[2]))
                if talentInfo[1] == TalentID then
                    CurrentTalentLevel = talentInfo[2]
                    ugcprint(string.format("[TalentTree] Find TalentID: %d, Level: %d", TalentID, CurrentTalentLevel))
                    break
                end
            end
        end
    end

    ugcprint(string.format("[TalentTree] CurrentTalentLevel: %d", CurrentTalentLevel))
    return CurrentTalentLevel
end

--- 获取验证天赋加点的通用验证数据
---@param TalentID int32 @TalentID
---@return table|nil @返回验证所需Data的表，获取不到则为nil
---生效范围：服务器
function TalentTreeComponent:GetTalentValidationData(TalentID)
    local PlayerData = self:LoadPlayerData()
    if not PlayerData then
        ugcprint("[TalentTree] Failed to load player data")
        return nil
    end

    local TalentData = TalentTreeManager:GetTalentDataByTalentID(TalentID)
    if not TalentData then
        ugcprint(string.format("[TalentTree] Invalid TalentID: %d", TalentID))
        return nil
    end

    local CategoryData = TalentTreeManager:GetCategoryDataByCategoryID(TalentData.CategoryID)
    local LayeredData = TalentTreeManager:GetLayerData(TalentData.CategoryID)
    if not CategoryData or not LayeredData then
        ugcprint(string.format("[TalentTree] Missing category/layer data for TalentID: %d", TalentID))
        return nil
    end

    return {
        PlayerData = PlayerData,
        TalentData = TalentData,
        CategoryData = CategoryData,
        LayeredData = LayeredData,
        HeroID = PlayerData["TalentTree"].SelectedHeroID
    }
end

--- 客户端验证数据获取
---@param TalentID int32
---@return table|nil
---生效范围：客户端
function TalentTreeComponent:GetClientValidationData(TalentID)
    local TalentData = TalentTreeManager:GetTalentDataByTalentID(TalentID)
    if not TalentData then
        ugcprint(string.format("[TalentTree][Client] Invalid TalentID: %d", TalentID))
        return nil
    end

    local CategoryData = TalentTreeManager:GetCategoryDataByCategoryID(TalentData.CategoryID)
    if not CategoryData then
        ugcprint(string.format("[TalentTree][Client] Missing category data for TalentID: %d", TalentID))
        return nil
    end

    return {
        TalentData = TalentData,
        CategoryData = CategoryData,
        HeroID = self.SelectedHeroID  -- 使用复制的SelectedHeroID
    }
end

--- 客户端获取天赋等级（使用复制数据）
--- 生效范围：客户端
function TalentTreeComponent:GetClientTalentLevel(TalentID, isGeneral)
    if isGeneral then
        for _, talentInfo in ipairs(self.GeneralTalentInfo) do
            if talentInfo[1] == TalentID then
                return talentInfo[2]
            end
        end
    else
        local HeroTalents = self.HeroTalentInfo[self.SelectedHeroID]
        if HeroTalents then
            for _, talentInfo in ipairs(HeroTalents) do
                if talentInfo[1] == TalentID then
                    return talentInfo[2]
                end
            end
        end
    end
    return 0
end

--- 获取类别中使用的天赋点
---@param CategoryID number
---@param isGeneral boolean
---@return number
function TalentTreeComponent:GetTotalPointsUsedInCategory(CategoryID, isGeneral)
    local total = 0
    local talents = isGeneral and self.GeneralTalentInfo or (self.HeroTalentInfo[self.SelectedHeroID] or {})
    
    for _, talentInfo in ipairs(talents) do
        local talentData = TalentTreeManager:GetTalentDataByTalentID(talentInfo[1])
        if talentData and talentData.CategoryID == CategoryID then
            total = total + talentInfo[2]
        end
    end
    
    return total
end

--- 检查玩家是否在匹配
---@return boolean
---生效范围：客户端
function TalentTreeComponent:IsInMatchingState()
    return LobbyModel and LobbyModel.IsMatching and LobbyModel:IsMatching()
end

--- 校验前置条件
---@param PlayerData @玩家数据
---@param TalentData UGCTalent @要升级的的天赋数据
---@param CategoryData UGCTalenCategory @要升级的的天赋所在的类型
function TalentTreeComponent:ValidatePrerequisites(PlayerData, TalentData, CategoryData)
    local CategoryPointsUsed = 0
    local TalentDataMap = TalentTreeManager:GetTalentDataMap()
    if CategoryData.IsGeneral then
        for _, talentInfo in ipairs(PlayerData["TalentTree"].GeneralTalentInfo) do
            local CurrentTalentID, CurrentTalentLevel = talentInfo[1], talentInfo[2]
            if TalentDataMap[CurrentTalentID].CategoryID == TalentData.CategoryID then
                CategoryPointsUsed = CategoryPointsUsed + CurrentTalentLevel
            end
        end
    else
        local HeroID = PlayerData["TalentTree"].SelectedHeroID
        local HeroTalents = PlayerData["TalentTree"].HeroTalentInfo[HeroID]
        if HeroTalents then
            for _, talentInfo in ipairs(HeroTalents) do
                local CurrentTalentID, CurrentTalentLevel = talentInfo[1], talentInfo[2]
                if TalentDataMap[CurrentTalentID].CategoryID == TalentData.CategoryID then
                    CategoryPointsUsed = CategoryPointsUsed + CurrentTalentLevel
                end
            end
        end
    end

    if CategoryPointsUsed < TalentData.LimitParameter then
        ugcprint(string.format("[TalentTree] Cannot upgrade TalentID = %s, required category points = %s, current category points = %s", TalentData.ID, TalentData.LimitParameter, CategoryPointsUsed))
        return false
    end

    return true
end

--- 检查天赋是否在最后加点的层
---@param TalentID number
---@param Data table @Validation data
---@return boolean
function TalentTreeComponent:IsTalentInLastUpgradedLayer(TalentID, Data)
    local layeredData = TalentTreeManager:GetLayerData(Data.TalentData.CategoryID)
    if not layeredData then return true end
    
    local totalPointsUsed = self:GetTotalPointsUsedInCategory(Data.TalentData.CategoryID, Data.CategoryData.IsGeneral)
    
    local lastUpgradedLayerIdx = 0
    for layerIdx, layer in ipairs(layeredData) do
        if totalPointsUsed > layer.LimitParameter then
            lastUpgradedLayerIdx = layerIdx
        else
            break
        end
    end
    
    local lastLayerTalents = layeredData[lastUpgradedLayerIdx] and layeredData[lastUpgradedLayerIdx].TalentIDs or {}
    for _, layerTalentID in ipairs(lastLayerTalents) do
        if layerTalentID == TalentID then
            return true
        end
    end
    
    return false
end

--- 校验是否有剩余的天赋点
---@param PlayerData @玩家数据
function TalentTreeComponent:ValidateTalentPoints(PlayerData)
    if PlayerData["TalentTree"].TalentPoints <= 0 then
        return false
    end
    return true
end

--- 校验是否达到了最大等级
---@param CurrentTalentLevel int32 @天赋当前的等级
---@param MaxLevel int32 @天赋最大的等级
---@param TalentID int32 @天赋ID
function TalentTreeComponent:ValidateMaxLevel(CurrentTalentLevel, MaxLevel, TalentID)
    if CurrentTalentLevel >= MaxLevel then
        return false
    end
    return true
end

--- 校验选中的天赋对应的英雄的英雄是否解锁
---@param HeroID int32 @英雄ID
function TalentTreeComponent:ValidateHeroLocked(HeroID)
    -- 英雄选择锁定接口仅客户端生效
    if UGCGameSystem.IsServer() then
        return false
    else
        return HeroSelectionManager:IsHeroLocked(HeroID)
    end
end

--- 验证天赋是否在解锁最后一层
---@param PlayerData @玩家数据
---@param TalentID int32 @天赋ID
---@param CategoryData UGCTalentCategory @要升级的的天赋数据
function TalentTreeComponent:ValidateLastUnlockedLayer(PlayerData, TalentData, CategoryData, LayeredData)
    local TotalPointsUsed = 0
    local CategoryID = CategoryData.ID

    if CategoryData.IsGeneral then
        for _, talentInfo in ipairs(PlayerData["TalentTree"].GeneralTalentInfo) do
            local CurrentTalentID, CurrentTalentLevel = talentInfo[1], talentInfo[2]
            if CurrentTalentID and CurrentTalentLevel then
                local CurrentTalentData = TalentTreeManager:GetTalentDataByTalentID(CurrentTalentID)
                if CurrentTalentData and CurrentTalentData.CategoryID == CategoryID then
                    TotalPointsUsed = TotalPointsUsed + CurrentTalentLevel
                end
            end
        end
    else
        local HeroID = PlayerData["TalentTree"].SelectedHeroID
        local HeroTalents = PlayerData["TalentTree"].HeroTalentInfo[HeroID]
        if HeroTalents then
            for _, talentInfo in ipairs(HeroTalents) do
                local CurrentTalentID, CurrentTalentLevel = talentInfo[1], talentInfo[2]
                if CurrentTalentID and CurrentTalentLevel then
                    local CurrentTalentData = TalentTreeManager:GetTalentDataByTalentID(CurrentTalentID)
                    if CurrentTalentData and CurrentTalentData.CategoryID == CategoryID then
                        TotalPointsUsed = TotalPointsUsed + CurrentTalentLevel
                    end
                end
            end
        end
    end

    -- 找到最后解锁的层
    local LastUpgradedLayerIdx = nil
    for LayerIdx, LayerData in ipairs(LayeredData) do
        if TotalPointsUsed > LayerData.LimitParameter then
            LastUpgradedLayerIdx = LayerIdx
        else
            break
        end
    end

    if not LastUpgradedLayerIdx then
        ugcprint(string.format("[TalentTree] ValidateLastUnlockedLayer: No unlocked layers for CategoryID %d", CategoryID))
        return false
    end

    -- 检查天赋是否在最后解锁的层
    local LastLayerTalentIDs = LayeredData[LastUpgradedLayerIdx].TalentIDs
    for _, LayerTalentID in ipairs(LastLayerTalentIDs) do
        if LayerTalentID == TalentData.ID then
            return true
        end
    end

    return false
end

--- 校验要返还的天赋等级是否大于0
---@param PlayerData @玩家数据
---@param TalentData @天赋数据
function TalentTreeComponent:ValidateLevel(PlayerData, TalentData, CategoryData)
    local TalentID = TalentData.ID
    local HeroID = PlayerData["TalentTree"].SelectedHeroID
    local CurrentLevel = self:GetCurrentTalentLevel(TalentID, CategoryData.IsGeneral, HeroID)

    if CurrentLevel <= 0 then
        return false
    end
    return true
end

--- 添加等级变化事件监听
function TalentTreeComponent:ListenLevel()
    ugcprint("[TalentTree] TalentTreeComponent:ListenLevel()")
    local PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(UGCActorComponentUtility.GetOwner(self))
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerKey(PlayerKey)
    PlayerState.OnLevelChanged:Add(self.OnLevelChanged, self)
end

    
--- 添加事件监听
function TalentTreeComponent:ListenMessage()
    ugcprint("[TalentTree] TalentTreeComponent:ListenMessage()")

    -- 仅在战斗中监听出生事件（大厅模式ID为1001）
    if UGCMultiMode.GetModeID() ~= 1001 then
        ugcprint("[TalentTree] TalentTreeComponent:ListenMessage() MultiModeID: 1002")
        local SpawnMessage = UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnSpawn
        UGCGenericMessageSystem.ListenGlobalMessage(self, SpawnMessage, self, self.HandlePlayerSpawn)

        local RespawnMessage = UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnRespawn
        UGCGenericMessageSystem.ListenGlobalMessage(self, RespawnMessage, self, self.HandlePlayerRespawn)
    end

    local EnterMessage = UGCGenericMessageSystem.Messages.UGC.PlayerEnter
    UGCGenericMessageSystem.ListenGlobalMessage(self, EnterMessage, self, self.HandlePlayerEnter)
end

function TalentTreeComponent:HandlePlayerSpawn(PlayerKey)
    self:OnPlayerSpawn(PlayerKey)
end

function TalentTreeComponent:HandlePlayerRespawn(PlayerKey)
    self:OnPlayerRespawn(PlayerKey)
end

function TalentTreeComponent:HandlePlayerEnter(PlayerKey)
    self:LoadData()
end

--[[----------------------------------------------------- OnCall ------------------------------------------------------]]--

function TalentTreeComponent:OnPlayerRespawn(InPlayerKey)
    local PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(UGCActorComponentUtility.GetOwner(self))
    ugcprint(string.format("[TalentTree] TalentTreeComponent:OnPlayerRespawn, InPlayerKey = %s, PlayerKey = %s", InPlayerKey, PlayerKey))
    
    if PlayerKey == InPlayerKey then
        self:ApplyFilteredTalents(InPlayerKey)    
    end
end

function TalentTreeComponent:OnPlayerSpawn(InPlayerKey)
    local PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(UGCActorComponentUtility.GetOwner(self))
    -- local PlayerKey = UGCActorComponentUtility.GetOwner(self).PlayerState.PlayerKey
    ugcprint(string.format("[TalentTree] TalentTreeComponent:OnPlayerSpawn, InPlayerKey = %s, PlayerKey = %s", InPlayerKey, PlayerKey))

    if PlayerKey == InPlayerKey then
        self:ApplyFilteredTalents(InPlayerKey)
    end
end

-- 读表计算
function TalentTreeComponent:OnLevelChanged(InitialLevel, CurrentLevel)
    ugcprint("[TalentTree] TalentTreeComponent:OnLevelChanged")

    if not InitialLevel or not CurrentLevel or CurrentLevel <= InitialLevel then
        ugcprint("[TalentTree] OnLevelChanged: Invalid level values.")
        return
    end

    local TalentPointsConfig = TalentTreeManager:GetTalentPointsByLevel()
    if not TalentPointsConfig then
        ugcprint("[TalentTree] OnLevelChanged: TalentPointsConfig not found.")
        return
    end

    ugcprint("[TalentTree] TalentTreeComponent:TalentPointsConfig")

    local TotalPointsToAdd = 0
    for level = InitialLevel + 1, CurrentLevel do
        local points = TalentPointsConfig[level] or 0
        TotalPointsToAdd = TotalPointsToAdd + points
        ugcprint(string.format("[TalentTree] level = %s, points = %s, TotalPointsToAdd = %s", level, points, TotalPointsToAdd))
    end

    local PlayerData = self:LoadPlayerData()
    PlayerData["TalentTree"].TalentPoints = PlayerData["TalentTree"].TalentPoints + TotalPointsToAdd
    self.TalentPoints = PlayerData["TalentTree"].TalentPoints
    UnrealNetwork.RepLazyProperty(self, "TalentPoints")
    ugcprint(string.format("[TalentTree] Add TalentPoints = %s, TotalTalentPoints = %s", TotalPointsToAdd, self.TalentPoints))

    self:SavePlayerData(PlayerData)
end

--[[----------------------------------------------------- OnRep ------------------------------------------------------]]--

function TalentTreeComponent:OnRep_TalentPoints()
    ugcprint("[TalentTree] TalentTreeComponent:OnRep_TalentPoints")

    if LobbyUtils.GetWidget(LobbyWidgetType.LWT_MainLobby) then
        LobbyUtils.UpdateWidget(LobbyWidgetType.LWT_MainLobby)    
    end

    TalentTreeManager:UpdateTalentPoints()
    TalentTreeManager:UpdateButtonState()
end

function TalentTreeComponent:OnRep_GeneralTalentInfo()
    ugcprint("[TalentTree] TalentTreeComponent:OnRep_GeneralTalentInfo")

    TalentTreeManager:UpdateTalentInfo()
end

function TalentTreeComponent:OnRep_HeroTalentInfo()
    ugcprint("[TalentTree] TalentTreeComponent:OnRep_HeroTalentInfo")

    TalentTreeManager:UpdateTalentInfo()
end

return TalentTreeComponent