local Print = GameplayUtils.Print
local Exception = GameplayUtils.Exception

---@class Gameplay.WeaponSystem
local WeaponSystem = LuaClass("Gameplay.WeaponSystem")

function WeaponSystem:Ctor()

end

---@public 获取可用的武器槽位
---@return string 槽位名称
---@return boolean 返回的槽位是否是空槽位
function WeaponSystem:GetAvailableWeaponSlotName(playerController,weaponConfigId)
    local weaponConfig = GameplaySystem.WeaponConfigMgr:GetWeaponConfigData(weaponConfigId)
    local slotName = nil
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(playerController)
    local isEmptySlot = false

    --寻找空槽位
    for k,v in pairs(weaponConfig.WeaponSlots) do
        local equippedItem = UGCBackpackSystemV2.GetEquippedItemBySlotName(playerPawn,v.SlotTag.TagName)
        if equippedItem == nil or equippedItem.TypeSpecificID <= 0 then
            slotName = v.SlotTag.TagName
            isEmptySlot = true--使用空槽位
            Print("WeaponSystem.GetAvailableWeaponSlotName： 找到空装备槽",slotName)
            break
        end
    end
    if slotName == nil then
        --获取当前槽位名称
        local slotEnum = UGCWeaponManagerSystem.GetCurrentWeaponSlot(playerPawn)
        for k,v in pairs(weaponConfig.WeaponSlots) do
            if v.SlotEnum == slotEnum then
                slotName = v.SlotTag.TagName--使用当前武器槽位
                Print("WeaponSystem.GetAvailableWeaponSlotName： 使用当前持有的武器所属的空装备槽",slotName)
                break
            end
        end
    end
    if slotName ~= nil then
        local isWeaponSlotEnabled = UGCBackpackSystemV2.GetEquipSlotEnable(playerPawn,slotName)
        Print("WeaponSystem.GetAvailableWeaponSlotName： 装备槽",slotName,"是否可用？ ",tostring(isWeaponSlotEnabled))
        if not isWeaponSlotEnabled  then
            UGCBackpackSystemV2.SetEquipSlotEnable(playerPawn,slotName)
        end
    end
    return slotName,isEmptySlot
end

---@public
function WeaponSystem:GetCurrentWeaponItemID(playerPawn)
    local curWeapon = UGCWeaponManagerSystem.GetCurrentWeapon(playerPawn)
    if not curWeapon then
        return 0
    end
    local curWeaponId = UGCWeaponManagerSystem.GetWeaponItemID(curWeapon)
    return curWeaponId
end

---@public
function WeaponSystem:GetCurrentWeaponConfigID(playerPawn)
    local curWeapon = UGCWeaponManagerSystem.GetCurrentWeapon(playerPawn)
    if not curWeapon then
        GameplayUtils.Exception("WeaponSystem:GetCurrentWeaponConfigID: 无法获取当前WeaponActor!!")
        return 0
    end
    local curWeaponId = UGCWeaponManagerSystem.GetWeaponItemID(curWeapon)
    local curWeaponConfigID = GameplaySystem.WeaponConfigMgr:GetWeaponConfigIDByItemID(curWeaponId)
    if curWeaponConfigID <= 0 then
        GameplayUtils.Exception("WeaponSystem:GetCurrentWeaponConfigID: 无法获取WeaponItemId ",curWeaponId," 对应的ConfigID")
    end
    return curWeaponConfigID
end

---@public 向玩家派发武器到背包
---@param player PlayerPawn | PlayerController
---@param weaponConfigId number
---@return boolean,ItemDefineID
function WeaponSystem:DeliverWeaponToPlayer(player,weaponConfigId)
    if player == nil then
        Print("WeaponSystem.DeliverWeaponToPlayer: player is nil")
        return false
    end
    if not UGCBackpackSystemV2.CheckInitPersistCompleted(player) then
        Print("WeaponSystem.DeliverWeaponToPlayer: Persist not ready")
        return false
    end
    local weaponConfig = GameplaySystem.WeaponConfigMgr:GetWeaponConfigData(weaponConfigId)
    if not weaponConfig then
        return false
    end
    local weaponItemId = weaponConfig.WeaponItemId
    local weaponAmmoId = weaponConfig.AmmoItemId
    self:Internal_ServerDeliverWeaponMagAmmo(player,weaponAmmoId,weaponConfig.DeliverAmmoNumber)
    local addWeapSuccessful = false
    local weaponDefineId = 0
    if UGCBackpackSystemV2.GetItemCountV2(player,weaponItemId) > 0 then--同种武器只能存在一把
        addWeapSuccessful = true
        weaponDefineId = GameplaySystem.BackpackSystem:GetGainedItemDefineId(player,weaponItemId)
    else
        addWeapSuccessful,weaponDefineId = GameplaySystem.BackpackSystem:DeliverItemToPlayer(player,weaponItemId,1)
    end
    if not addWeapSuccessful then
        Print("[WeaponSystem.DeliverWeaponToPlayer: 添加默认武器道具进背包失败！！！")
    end
    if weaponDefineId == nil then
        Print("WeaponSystem.DeliverWeaponToPlayer: 无法找到武器道具的DefineID！！！")
        return false
    end
    return addWeapSuccessful,weaponDefineId
end

---@public 让玩家装备以获取的武器
---@param player PlayerPawn | PlayerController
---@param weaponConfigId number
---@param weaponSlotName string
---@return boolean
function WeaponSystem:EquipGainedWeapon(player,weaponConfigId,weaponSlotName)
    if player == nil then
        Exception("WeaponSystem.EquipGainedWeapon： player is nil")
        return false
    end
    local weaponConfig = GameplaySystem.WeaponConfigMgr:GetWeaponConfigData(weaponConfigId)
    if not weaponConfig then
        Exception("WeaponSystem.EquipGainedWeapon： 武器配置不存在！")
        return false
    end
    local weaponItemId = weaponConfig.WeaponItemId
    local weaponDefineId = GameplaySystem.BackpackSystem:GetGainedItemDefineId(player,weaponItemId)
    if weaponDefineId == nil then
        Exception("WeaponSystem.EquipGainedWeapon： 未获得武器!!")
        return false
    end
    --
    local isWeaponSlotEnabled = UGCBackpackSystemV2.GetEquipSlotEnable(player,weaponSlotName)
    if not isWeaponSlotEnabled  then
        UGCBackpackSystemV2.SetEquipSlotEnable(player,weaponSlotName)
    end
    --
    if not UGCBackpackSystemV2.ItemCanEquipToSlot(player, weaponItemId, weaponSlotName) then
        Exception("WeaponSystem.EquipGainedWeapon： 槽位",weaponSlotName,"无法装备武器",weaponItemId)
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
        Print("WeaponSystem.EquipGainedWeapon： 装备武器成功！！！weaponDefineId="..weaponConfigId)
    else
        Exception("WeaponSystem.EquipGainedWeapon： 装备武器失败！！！ weaponDefineId="..weaponConfigId)
    end
    return equipSuccess
end

---@private
---@param player PlayerPawn | PlayerController
function WeaponSystem:Internal_ServerDeliverWeaponMagAmmo(player,ammoItemId,maxAmmoNum)
    -- 已拥有该类型子弹时，把 DeliverAmmoNumber 视为上限，仅补充到上限的差额
    local currentAmmo = UGCBackpackSystemV2.GetItemCountV2(player, ammoItemId) or 0
    local ammoToDeliver = math.max(0, maxAmmoNum - currentAmmo)
    if ammoToDeliver > 0 then
        local actualAmmoCnt, _ = UGCBackpackSystemV2.AddItemV2(player, ammoItemId, ammoToDeliver)
        if actualAmmoCnt <= 0 then
            Print(string.format("WeaponSystem.Internal_ServerDeliverWeaponMagAmmo: 补充子弹失败！AmmoItemId=%d, 期望补充=%d", ammoItemId, ammoToDeliver))
        end
    end
end

---@public 向玩家派发武器通用流程
---@param playerKey number
---@param weaponConfigId number
---@return boolean
function WeaponSystem:ServerDeliverAndEquipWeaponToPlayer(playerKey,weaponConfigId,bSwithWeapon)
    local playerController = UGCGameSystem.GetPlayerControllerByPlayerKey(playerKey)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(playerController)
    if not UGCBackpackSystemV2.CheckInitPersistCompleted(playerPawn) then
        Print("WeaponSystem.DeliverWeaponToPlayer: Persist not ready")
        return false
    end
    local weaponConfig = GameplaySystem.WeaponConfigMgr:GetWeaponConfigData(weaponConfigId)
    local isWeaponEquipped = self:IsWeaponEquipped(playerKey,weaponConfigId)
    if isWeaponEquipped then
        --已装备的武器，不重新装备，直接加满后备弹药后返回
        self:Internal_ServerDeliverWeaponMagAmmo(playerController,weaponConfig.AmmoItemId,weaponConfig.DeliverAmmoNumber)
        return true
    end
    --
    local weaponSlotName,isEmptySlot = self:GetAvailableWeaponSlotName(playerController,weaponConfigId)
    if weaponSlotName == nil then
        Exception("WeaponSystem.ServerDeliverAndEquipWeaponToPlayer： 装备武器失败！！！ 未找到有效的武器槽位！"..weaponConfigId)
        return false
    end
    --
    local curWeaponCofnigId = self:GetCurrentWeaponConfigID(playerPawn)
    Print("WeaponSystem.ServerDeliverAndEquipWeaponToPlayer: 玩家",playerKey,"当前持有武器",curWeaponCofnigId)
    local addWeapSuccessful = false
    local weaponItemId = weaponConfig.WeaponItemId
    ---@type ItemDefineID
    local weaponDefineId = nil
    if UGCBackpackSystemV2.GetItemCountV2(playerPawn,weaponItemId) > 0 then--同种武器只能存在一把
        addWeapSuccessful = true
        weaponDefineId = GameplaySystem.BackpackSystem:GetGainedItemDefineId(playerPawn,weaponItemId)
    else
        addWeapSuccessful,weaponDefineId = GameplaySystem.BackpackSystem:DeliverItemToPlayer(playerPawn,weaponItemId,1)
    end
    if not addWeapSuccessful then
        Exception("[WeaponSystem.ServerDeliverAndEquipWeaponToPlayer: 添加默认武器道具进背包失败！！！")
        return false
    elseif weaponDefineId == nil then
        Exception("WeaponSystem.ServerDeliverAndEquipWeaponToPlayer: 无法找到武器道具的DefineID！！！")
        return false
    end
    --如果是要替换槽位内已有武器，需要移除武器道具和弹药道具
    if not isEmptySlot and curWeaponCofnigId > 0 and curWeaponCofnigId ~= weaponConfigId then
        local removeSuccessful = self:ServerRemoveEquippedWeapon(playerPawn,curWeaponCofnigId)
        if removeSuccessful then
            Print("WeaponSystem.ServerDeliverAndEquipWeaponToPlayer: 玩家",playerKey,"移除槽位上",weaponSlotName,"已装备的武器",curWeaponCofnigId)
        else
            Exception("WeaponSystem.ServerDeliverAndEquipWeaponToPlayer: 玩家",playerKey,"移除槽位上",weaponSlotName,"已装备的武器",curWeaponCofnigId,"失败！！")
        end
    end
    --派发弹药道具
    self:Internal_ServerDeliverWeaponMagAmmo(playerPawn,weaponConfig.AmmoItemId,weaponConfig.DeliverAmmoNumber)
    --
    if not UGCBackpackSystemV2.ItemCanEquipToSlot(playerPawn, weaponItemId, weaponSlotName) then
        Exception("WeaponSystem.ServerDeliverAndEquipWeaponToPlayer： 槽位",weaponSlotName,"无法装备武器",weaponItemId)
    end
    --讲武器装备到指定槽位
    weaponDefineId = GameplaySystem.BackpackSystem:GetGainedItemDefineId(playerPawn,weaponItemId)
    local equipSuccess = UGCBackpackSystemV2.EquipItemV2(playerPawn, weaponSlotName, weaponDefineId)
    if equipSuccess then
        if bSwithWeapon then
            self:SwitchMainWeaponSlot(playerKey,weaponSlotName)
        end
    else
        Exception("WeaponSystem.ServerDeliverAndEquipWeaponToPlayer： 装备武器",weaponConfigId,"[DefineID=",tostring(weaponDefineId.TypeSpecificID),"]到装备栏",weaponSlotName,"失败！")
    end
    return true
end

---@public
---@return boolean
function WeaponSystem:ServerRemoveEquippedWeapon(player,weaponConfigID)
    local weaponConfig = GameplaySystem.WeaponConfigMgr:GetWeaponConfigData(weaponConfigID)
    if not weaponConfig then
        return false
    end
    --移除子弹
    local weaponAmmoId = weaponConfig.AmmoItemId
    local ammoCnt = UGCBackpackSystemV2.GetItemCountV2(player,weaponAmmoId)
    UGCBackpackSystemV2.RemoveItemV2(player,weaponAmmoId,ammoCnt)
    --
    local weaponItemId = weaponConfig.WeaponItemId
    local curCnt = UGCBackpackSystemV2.GetItemCountV2(player,weaponItemId)
    local removeCnt = UGCBackpackSystemV2.RemoveItemV2(player,weaponItemId,curCnt)
    return removeCnt >= curCnt
end

---@public
function WeaponSystem:GetDefaultWeaponID(playerKey)
    return 10011
end

---@public 是否以获得指定武器
---@return boolean
function WeaponSystem:IsWeaponEquipped(playerKey,weaponConfigID)
    local weaponConfig = GameplaySystem.WeaponConfigMgr:GetWeaponConfigData(weaponConfigID)
    if not weaponConfig then
        return false
    end
    local weaponItemId = weaponConfig.WeaponItemId
    local playerController = UGCGameSystem.GetPlayerControllerByPlayerKey(playerKey)
    local curCnt = UGCBackpackSystemV2.GetItemCountV2(playerController,weaponItemId)
    return curCnt > 0
end

---@public
---@return ASTExtraWeapon
---@return number ESurviveWeaponPropSlot
function WeaponSystem:GetWeaponActorByConfigID(playerKey,weaponConfigID)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    local weaponItemId = GameplaySystem.WeaponConfigMgr:GetWeaponItemIDByConfigID(weaponConfigID)
    for slotEnum = 1,ESurviveWeaponPropSlot.SWPS_TempSpecialWeapon do
        local weapon = UGCWeaponManagerSystem.GetWeaponBySlot(playerPawn,slotEnum)
        if weapon:GetWeaponItemID() == weaponItemId then
            return weapon,slotEnum
        end
    end
    return nil,0
end

---@public 获取指定武器当前弹匣内子弹数量
function WeaponSystem:GetWeaponClipAmmoNum(playerKey,weaponConfigID)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    local weaponActor = self:GetWeaponActorByConfigID(playerKey,weaponConfigID)
    if not weaponActor then
        return 0
    end
    local ret = weaponActor.CurBulletNumInClip or 0
end

---@public 获取指定武器当前后备子弹数量
function WeaponSystem:GetWeaponMagAmmoNum(playerKey,weaponConfigID)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    local ammoItemId = GameplaySystem.WeaponConfigMgr:GetWeaponAmmoItemID(weaponConfigID)
    -- 然后查背包
    local reserveAmmo = UGCBackpackSystemV2.GetItemCountV2(playerPawn, ammoItemId)
    return reserveAmmo
end

---@public 获取指定武器最大后备子弹数量
function WeaponSystem:GetWeaponMaxMagAmmoNum(weaponConfigID)
    local weaponConfig = GameplaySystem.WeaponConfigMgr:GetWeaponConfigData(weaponConfigID)
    if not weaponConfig then
        return 0
    end
    local ret = weaponConfig.DeliverAmmoNumber
    return ret
end

---@public
function WeaponSystem:SwitchMainWeaponSlot(playerKey,targetMainSlot)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    local slotEnum = ESurviveWeaponPropSlot.SWPS_None
    if targetMainSlot == "EquipmentSlot.Core.MainSlot1" then
        slotEnum = ESurviveWeaponPropSlot.SWPS_MainShootWeapon1
    elseif targetMainSlot == "EquipmentSlot.Core.MainSlot2" then
        slotEnum = ESurviveWeaponPropSlot.SWPS_MainShootWeapon2
    end
    UGCWeaponManagerSystem.SwitchWeaponBySlot(playerPawn,slotEnum,true)
end

return WeaponSystem