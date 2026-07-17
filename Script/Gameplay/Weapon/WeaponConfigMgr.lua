
---@class Gameplay.WeaponConfigMgr
local WeaponConfigMgr = LuaClass("Gameplay.WeaponConfigMgr")

function WeaponConfigMgr:Ctor()
    self.PathToWeaponConfigTable = 'Data/Table/Weapon/DT_WeaponConfigs'
    self.WeaponConfigTable = nil
    ---@type table<number,Struct_WeaponConfig>
    self.WeaponConfigDataCaches = {}
    ---@type table<number,number>
    self.WeaponItemIdToConfigIdCaches = {}
end

---@private
---@return Struct_WeaponConfig[]
function WeaponConfigMgr:GetDataTableData()
    if not self.WeaponConfigTable then
        self.WeaponConfigTable = UGCGameSystem.GetTableData(self.PathToWeaponConfigTable)
    end
    return self.WeaponConfigTable
end

---@public
---@return Struct_WeaponConfig|nil
function WeaponConfigMgr:GetWeaponConfigData(weaponConfigId)
    local cache = self.WeaponConfigDataCaches[weaponConfigId]
    if cache then
        return cache
    end
    local CfgTable = self:GetDataTableData()
    local ret = nil
    for _,weaponCfg in pairs(CfgTable) do
        if weaponCfg.Id == weaponConfigId then
            ret = weaponCfg
            self.WeaponConfigDataCaches[weaponConfigId] = ret
            break
        end
    end
    return ret
end

---@public
---@return string
function WeaponConfigMgr:GetWeaponName(weaponConfigID)
    local config = self:GetWeaponConfigData(weaponConfigID)
    if not config then
        return ""
    end
    local ret = config.WeaponName
    return ret
end

---@public
---@return number
function WeaponConfigMgr:GetWeaponAmmoItemID(weaponConfigID)
    local config = self:GetWeaponConfigData(weaponConfigID)
    if not config then
        return 0
    end
    local ret = config.AmmoItemId
    return ret
end

---@public
---@return number
function WeaponConfigMgr:GetWeaponItemIDByConfigID(weaponConfigID)
    local config = self:GetWeaponConfigData(weaponConfigID)
    if not config then
        return 0
    end
    return config.WeaponItemId
end

---@public
---@return number
function WeaponConfigMgr:GetWeaponConfigIDByItemID(weaponItemId)
    local cache = self.WeaponItemIdToConfigIdCaches[weaponItemId]
    if cache then
        return cache
    end
    local CfgTable = self:GetDataTableData()
    for _, weaponCfg in pairs(CfgTable) do
        if weaponCfg.WeaponItemId == weaponItemId then
            self.WeaponItemIdToConfigIdCaches[weaponItemId] = weaponCfg.Id
            return weaponCfg.Id
        end
    end
    return 0
end

---@public
---@return UBattleItemHandleBase|nil
function WeaponConfigMgr:GetWeaponItemHandleByConfigID(weaponConfigID)
    local weaponItemId = self:GetWeaponItemIDByConfigID(weaponConfigID)
    if weaponItemId <= 0 then
        return nil
    end
    return UGCItemSystemV2.GetConfigItemHandle(weaponItemId)
end

---@public
---@return FSoftObjectPath|nil
function WeaponConfigMgr:GetWeaponEquipBarIconByConfigID(weaponConfigID)
    local weaponItemId = self:GetWeaponItemIDByConfigID(weaponConfigID)
    if weaponItemId <= 0 then
        return nil
    end
    return UGCItemSystemV2.GetWhiteIconTextureV2(weaponItemId)
end

---@public
---@return FSoftObjectPath|nil
function WeaponConfigMgr:GetWeaponBackpackIconByConfigID(weaponConfigID)
    local weaponItemId = self:GetWeaponItemIDByConfigID(weaponConfigID)
    if weaponItemId <= 0 then
        return nil
    end
    return UGCItemSystemV2.GetBigIconTextureV2(weaponItemId)
end

return WeaponConfigMgr