local UGCGameData = {}

UGCGameData.ModeName = {
    Lobby = "大厅",
    SingleMode = "单人闯关",
    SingleMode2 = "2号单人闯关",
    TeamModeWithTwoPlayer = "多人闯关（二人）",
    TeamModeWithThreePlayer = "多人闯关（三人）",
    TeamModeWithFourPlayer = "多人闯关（四人）",
}

UGCGameData.AliveState = {
    Alive = 0,
    Dying = 1,
    Dead = 2,
}

function UGCGameData.GetLevelConfig(Lv)
    return UGCGameSystem.GetTableDataByRowName(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Level/UGCLevelConfig.UGCLevelConfig'), tostring(Lv))
end

function UGCGameData.GetGlobalLevelConfig()
    return UGCGameSystem.GetTableDataByRowName(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Level/UGCLevelGlobal.UGCLevelGlobal'), "Global")
end

function UGCGameData.GetMonsterConfig(MonsterID)
    return UGCGameSystem.GetTableDataByRowName(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/DT_MonsterDetails.DT_MonsterDetails'), tostring(MonsterID))
end

function UGCGameData.GetEquippmentAffixConfig(EquippmentID)
    return UGCGameSystem.GetTableDataByRowName(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCEquippmentRandomAffix.UGCEquippmentRandomAffix'), tostring(EquippmentID))
end

function UGCGameData.GetAffixDetailsAllConfig()
    return UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCAffixDetails.UGCAffixDetails'));
end

function UGCGameData.GetAffixDetailsConfig(AffixID)
    return UGCGameSystem.GetTableDataByRowName(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCAffixDetails.UGCAffixDetails'), tostring(AffixID))
end

function UGCGameData.GetSkillDetailsConfig(SkillID)
    return UGCGameSystem.GetTableDataByRowName(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCSkillDetails.UGCSkillDetails'), tostring(SkillID))
end

function UGCGameData.GetItemMapAffixIDAllConfig()
    return UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCItemMapAffixId.UGCItemMapAffixId'));
end

function UGCGameData.GetItemMapAffixIDConfig(ItemID)
    return UGCGameSystem.GetTableDataByRowName(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCItemMapAffixId.UGCItemMapAffixId'), tostring(ItemID))
end

function UGCGameData.GetRespawnConfig(ModeID)
    local RespawnConfigTable = {}
    local GameModeConfigTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCGameModeConfig.UGCGameModeConfig'))
    for _, GameModeConfig in pairs(GameModeConfigTable) do
        if GameModeConfig.ModeID == ModeID then
            if GameModeConfig.FreeReviveCount then
                RespawnConfigTable.TotalFreeReviveCount = GameModeConfig.FreeReviveCount
                RespawnConfigTable.CurrentFreeReviveCount = GameModeConfig.FreeReviveCount
            else
                ugcprint("Warning: UGCGameData.GetRespawnConfig(ModeID) Table not found FreeReviveCount")
                RespawnConfigTable.TotalFreeReviveCount = 0
                RespawnConfigTable.CurrentFreeReviveCount = 0
            end

            if GameModeConfig.PaidReviveCount then
                RespawnConfigTable.TotalPaidReviveCount = GameModeConfig.PaidReviveCount
                RespawnConfigTable.CurrentPaidReviveCount = GameModeConfig.PaidReviveCount
            else
                ugcprint("Warning: UGCGameData.GetRespawnConfig(ModeID) Table not found PaidReviveCount")
                RespawnConfigTable.TotalPaidReviveCount = 0
                RespawnConfigTable.CurrentPaidReviveCount = 0
            end
            
            if GameModeConfig.Price then
                RespawnConfigTable.CurrencyID = GameModeConfig.Price[1]
                RespawnConfigTable.Price = GameModeConfig.Price[2]
            end
            if not RespawnConfigTable.CurrencyID then
                ugcprint("Warning: UGCGameData.GetRespawnConfig(ModeID) Table not found CurrencyID")
                RespawnConfigTable.CurrencyID = 0
            end
            if not RespawnConfigTable.Price then
                ugcprint("Warning: UGCGameData.GetRespawnConfig(ModeID) Table not found Price")
                RespawnConfigTable.Price = 0
            end
        end
    end
    return RespawnConfigTable
end

function UGCGameData.GetGameModeName(ModeID)
    local GameModeConfigTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCGameModeConfig.UGCGameModeConfig'))
    for _, GameModeConfig in pairs(GameModeConfigTable) do
        if GameModeConfig.ModeID == ModeID then
            return GameModeConfig.ModeName
        end
    end
end

function UGCGameData.GetGameModeActorMgrConfig(ModeID)
    local GameModeConfigTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCGameModeConfig.UGCGameModeConfig'))
    for _, GameModeConfig in pairs(GameModeConfigTable) do
        if GameModeConfig.ModeID == ModeID then
            return GameModeConfig.GameModeActorMgr
        end
    end
end

function UGCGameData.GetUnlockModeID(ModeID)
    local GameModeConfigTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCGameModeConfig.UGCGameModeConfig'))
    for _, GameModeConfig in pairs(GameModeConfigTable) do
        if GameModeConfig.ModeID == ModeID then
            return GameModeConfig.UnlockMode
        end
    end
end

function UGCGameData.GetAttributeName(GameAttrubteType)
    local TotalAttributeShowConfig = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCTotalAttributeShowConfig.UGCTotalAttributeShowConfig'))
    for _, Config in pairs(TotalAttributeShowConfig) do
        local AttributeType = totable(Config.GameAttributeType)
        if AttributeType.AttributeName == GameAttrubteType.AttributeName then
            return Config.AttributeName
        end
    end
end

function UGCGameData.GetShopAfterLevelDropGroupID(ModeID, CurrentStage)
    local GameModeConfigTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCGameModeConfig.UGCGameModeConfig'))
    for _, GameModeConfig in pairs(GameModeConfigTable) do
        if GameModeConfig.ModeID == ModeID then
            return GameModeConfig.ShopAfterLevel[CurrentStage]
        end
    end
end

function UGCGameData.GetSettlementExpCount(ModeID)
    local GameModeConfigTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCGameModeConfig.UGCGameModeConfig'))
    for _, GameModeConfig in pairs(GameModeConfigTable) do
        if GameModeConfig.ModeID == ModeID then
            return GameModeConfig.SettlementExpCount
        end
    end
end

function UGCGameData.GetSettlementTalentCount(ModeID)
    local GameModeConfigTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCGameModeConfig.UGCGameModeConfig'))
    for _, GameModeConfig in pairs(GameModeConfigTable) do
        if GameModeConfig.ModeID == ModeID then
            return GameModeConfig.SettlementTalentCount
        end
    end
end

return UGCGameData
