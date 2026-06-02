---@class Strcut.WeaponConfig
---@field Id number
---@field WeaponItemId number
---@field AmmoItemId number
---@field DeliverAmmoNumber number
---@field WeaponDesc string
---@field WeaponLevel number

---@class Gameplay.WeaponConfigMgr
local WeaponConfigMgr = {}

local PathToWeaponConfigTable = 'Data/Table/Weapon/DT_WeaponConfigs'
local WeaponConfigTable = nil
---@type table<number,Strcut.WeaponConfig>
local WeaponConfigDataCaches = {}

---@private
---@return Strcut.WeaponConfig[]
function WeaponConfigMgr.GetDataTableData()
    if not WeaponConfigTable then
        WeaponConfigTable = UGCGameSystem.GetTableData(PathToWeaponConfigTable)
    end
    return WeaponConfigTable
end

---@public
---@return Strcut.WeaponConfig|nil
function WeaponConfigMgr.GetWeaponConfigData(weaponConfigId)
    local cache = WeaponConfigDataCaches[weaponConfigId]
    if cache then
        return cache
    end
    local CfgTable = WeaponConfigMgr.GetDataTableData()
    local ret = nil
    for _,weaponCfg in pairs(CfgTable) do
        if weaponCfg.Id == weaponConfigId then
            ret = weaponCfg
            WeaponConfigDataCaches[weaponConfigId] = ret
            break
        end
    end
    return ret
end

return WeaponConfigMgr