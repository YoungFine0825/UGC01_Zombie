---@class Gameplay.WeaponSystem
local WeaponSystem = {}

---@public 向玩家派发武器
---@param player PlayerPawn | PlayerController
---@param weaponConfigId number
---@return boolean,ItemDefineID
function WeaponSystem.DeliverWeaponToPlayer(player,weaponConfigId)
    if player == nil then
        ugcprint("WeaponSystem.DeliverWeaponToPlayer: player is nil")
        return false
    end
    if not UGCBackpackSystemV2.CheckInitPersistCompleted(player) then
        ugcprint("WeaponSystem.DeliverWeaponToPlayer: Persist not ready")
        return false
    end
    local weaponConfig = GameplaySystem.WeaponConfigMgr.GetWeaponConfigData(weaponConfigId)
    if not weaponConfig then
        return false
    end
    local weaponItemId = weaponConfig.WeaponItemId
    local weaponAmmoId = weaponConfig.AmmoItemId
    local ammoNumber = weaponConfig.DeliverAmmoNumber
    local addWeapSuccessful,weaponDefineId = GameplaySystem.BackpackSystem.DeliverItemToPlayer(player,weaponItemId,1)
    local addAmmoSuccessful,ammoDefineId = GameplaySystem.BackpackSystem.DeliverItemToPlayer(player,weaponAmmoId,ammoNumber)
    if not addWeapSuccessful then
        ugcprint("[WeaponSystem.DeliverWeaponToPlayer: 添加默认武器道具进背包失败！！！")
    end
    if weaponDefineId == nil then
        ugcprint("WeaponSystem.DeliverWeaponToPlayer: 无法找到武器道具的DefineID！！！")
        return false
    end
    return addWeapSuccessful,weaponDefineId
end

---@public 让玩家装备以获取的武器
---@param player PlayerPawn | PlayerController
---@param weaponConfigId number
---@param weaponSlotName string
---@return boolean
function WeaponSystem.EquipGainedWeapon(player,weaponConfigId,weaponSlotName)
    if player == nil then
        ugc_exception("WeaponSystem.EquipGainedWeapon： player is nil")
        return false
    end
    local weaponConfig = GameplaySystem.WeaponConfigMgr.GetWeaponConfigData(weaponConfigId)
    if not weaponConfig then
        ugc_exception("WeaponSystem.EquipGainedWeapon： 武器配置不存在！")
        return false
    end
    local weaponItemId = weaponConfig.WeaponItemId
    local weaponDefineId = GameplaySystem.BackpackSystem.GetGainedItemDefineId(player,weaponItemId)
    if weaponDefineId == nil then
        ugc_exception("WeaponSystem.EquipGainedWeapon： 未获得武器!!")
        return false
    end
    if not UGCBackpackSystemV2.ItemCanEquipToSlot(player, weaponItemId, weaponSlotName) then
        ugcprint_concat("WeaponSystem.EquipGainedWeapon： 槽位",weaponSlotName,"无法装备武器",weaponItemId)
        return false
    end
    --
    local equipped = UGCBackpackSystemV2.GetEquippedItemBySlotName(player, weaponSlotName)
    if equipped and equipped.InstanceID == weaponDefineId.InstanceID then
        return true--已装备
    end
    --
    local equipSuccess = UGCBackpackSystemV2.EquipItemV2(player, weaponSlotName, weaponDefineId)
    if equipSuccess then
        ugcprint("WeaponSystem.EquipGainedWeapon： 装备武器成功！！！weaponDefineId="..weaponConfigId)
    else
        ugcprint("WeaponSystem.EquipGainedWeapon： 装备武器失败！！！ weaponDefineId="..weaponConfigId)
    end
    return equipSuccess
end

return WeaponSystem