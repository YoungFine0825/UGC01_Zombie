---@class Gameplay.SodaConfigMgr
local SodaConfigMgr = LuaClass("Gameplay.SodaConfigMgr")

function SodaConfigMgr:Ctor()
    self.PathToSodaConfigTable = 'Data/Table/PlayerSoda/DT_PlayerSodaConfig'
    self.SodaConfigTable = nil
    ---@type table<number,Struct_PlayerSodaConfig>
    self.SodaConfigDataCaches = {}
    ---@type table<number,number>
    self.SodaItemIdToConfigIdCaches = {}
end

---@private
---@return Struct_PlayerSodaConfig[]
function SodaConfigMgr:GetDataTableData()
    if not self.SodaConfigTable then
        self.SodaConfigTable = UGCGameSystem.GetTableData(self.PathToSodaConfigTable)
    end
    return self.SodaConfigTable
end

---@public
---@return Struct_PlayerSodaConfig|nil
function SodaConfigMgr:GetSodaConfigData(sodaConfigId)
    local cache = self.SodaConfigDataCaches[sodaConfigId]
    if cache then
        return cache
    end
    local CfgTable = self:GetDataTableData()
    local ret = nil
    for _,sodaCfg in pairs(CfgTable) do
        if sodaCfg.ID == sodaConfigId then
            ret = sodaCfg
            self.SodaConfigDataCaches[sodaConfigId] = ret
            break
        end
    end
    return ret
end

---@public
---@return string
function SodaConfigMgr:GetSodaName(sodaConfigId)
    local config = self:GetSodaConfigData(sodaConfigId)
    if not config then
        return ""
    end
    local ret = config.Name
    return ret
end

---@public
---@return string
function SodaConfigMgr:GetSodaDesc(sodaConfigId)
    local config = self:GetSodaConfigData(sodaConfigId)
    if not config then
        return ""
    end
    local ret = config.Desc
    return ret
end

---@public
---@return number
function SodaConfigMgr:GetSodaItemID(sodaConfigId)
    local config = self:GetSodaConfigData(sodaConfigId)
    if not config then
        return 0
    end
    return config.ItemID
end

---@public
---@return UClass|nil
function SodaConfigMgr:GetSodaBuffClass(sodaConfigId)
    local config = self:GetSodaConfigData(sodaConfigId)
    if not config then
        return nil
    end
    return config.BuffClass
end

---@public
---@return FGameplayTag
function SodaConfigMgr:GetSodaBuffTag(sodaConfigId)
    local config = self:GetSodaConfigData(sodaConfigId)
    if not config then
        return nil
    end
    return config.BuffTag
end

---@public
---@return number
function SodaConfigMgr:GetSodaConfigIDByItemID(sodaItemId)
    local cache = self.SodaItemIdToConfigIdCaches[sodaItemId]
    if cache then
        return cache
    end
    local CfgTable = self:GetDataTableData()
    for _, sodaCfg in pairs(CfgTable) do
        if sodaCfg.ItemID == sodaItemId then
            self.SodaItemIdToConfigIdCaches[sodaItemId] = sodaCfg.ID
            return sodaCfg.ID
        end
    end
    return 0
end

---@public
---@return UBattleItemHandleBase|nil
function SodaConfigMgr:GetSodaItemHandleByConfigID(sodaConfigId)
    local sodaItemId = self:GetSodaItemID(sodaConfigId)
    if sodaItemId <= 0 then
        return nil
    end
    return UGCItemSystemV2.GetConfigItemHandle(sodaItemId)
end

---@public
---@return FSoftObjectPath|nil
function SodaConfigMgr:GetSodaEquipBarIconByConfigID(sodaConfigId)
    local sodaItemId = self:GetSodaItemID(sodaConfigId)
    if sodaItemId <= 0 then
        return nil
    end
    return UGCItemSystemV2.GetWhiteIconTextureV2(sodaItemId)
end

---@public
---@return FSoftObjectPath|nil
function SodaConfigMgr:GetSodaBackpackIconByConfigID(sodaConfigId)
    local sodaItemId = self:GetSodaItemID(sodaConfigId)
    if sodaItemId <= 0 then
        return nil
    end
    return UGCItemSystemV2.GetBigIconTextureV2(sodaItemId)
end

return SodaConfigMgr