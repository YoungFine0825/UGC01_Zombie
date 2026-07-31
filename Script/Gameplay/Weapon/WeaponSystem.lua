local Print = GameplayUtils.Print
local Exception = GameplayUtils.Exception

---@class Gameplay.WeaponSystem
local WeaponSystem = LuaClass("Gameplay.WeaponSystem")

function WeaponSystem:Ctor()

end

---获取主武器槽位名称
---@public
---@return string[] @槽位名称列表
function WeaponSystem:GetMainWeaponSlots()
    return {"EquipmentSlot.Core.MainSlot1", "EquipmentSlot.Core.MainSlot2"}
end

---获取所有武器槽位名称
---@public
---@return string[] @槽位名称列表
function WeaponSystem:GetAllWeaponSlots()
    return {
        "EquipmentSlot.Core.MainSlot1",--武器1
        "EquipmentSlot.Core.MainSlot2",--武器2
        "EquipmentSlot.Core.SubSlot",--手雷（原本为手枪槽位，先作为手雷槽位）
    }
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

---@private 补充满武器道具
---@param player PlayerPawn | PlayerController
function WeaponSystem:Internal_ServerReplenishWeaponItem(player,itemId,maxNum)
    if itemId <= 0 then
        return
    end
    local currentNum = UGCBackpackSystemV2.GetItemCountV2(player, itemId) or 0
    local itemToDeliver = math.max(0, maxNum - currentNum)
    if itemToDeliver > 0 then
        local actualAmmoCnt, _ = UGCBackpackSystemV2.AddItemV2(player, itemId, itemToDeliver)
        if actualAmmoCnt <= 0 then
            Print(string.format("WeaponSystem.Internal_ServerReplenishWeaponItem: 补满道具失败！ItemId=%d, 期望补充=%d", itemId, itemToDeliver))
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
        --补充满武器数量
        self:Internal_ServerReplenishWeaponItem(playerController,weaponConfig.WeaponItemId,weaponConfig.MaxWeaponNum)
        --已装备的武器，不重新装备，直接加满后备弹药后返回
        self:Internal_ServerReplenishWeaponItem(playerController,weaponConfig.AmmoItemId,weaponConfig.DeliverAmmoNumber)
        return true
    end
    --
    local weaponSlotName,isEmptySlot = self:GetAvailableWeaponSlotName(playerController,weaponConfigId)
    if weaponSlotName == nil then
        Exception("WeaponSystem.ServerDeliverAndEquipWeaponToPlayer： 装备武器失败！！！ 未找到有效的武器槽位！"..weaponConfigId)
        return false
    end
    --
    local curWeaponCofnigId = self:GetPlayerWeaponConfigIDBySlot(playerKey,weaponSlotName)
    Print("WeaponSystem.ServerDeliverAndEquipWeaponToPlayer: 玩家 ",playerKey," 的槽位 ",weaponSlotName," 当前装备武器 ",curWeaponCofnigId)
    local addWeapSuccessful = false
    local weaponItemId = weaponConfig.WeaponItemId
    local curWeaponItemNum = UGCBackpackSystemV2.GetItemCountV2(playerPawn,weaponItemId)
    ---@type ItemDefineID
    local weaponDefineId = nil
    if curWeaponItemNum > weaponConfig.MaxWeaponNum then--武器数量已满
        addWeapSuccessful = true
        weaponDefineId = GameplaySystem.BackpackSystem:GetGainedItemDefineId(playerPawn,weaponItemId)
    else
        local neededWeaponNum = math.max(0, weaponConfig.MaxWeaponNum - curWeaponItemNum)--只派发缺省数量
        addWeapSuccessful,weaponDefineId = GameplaySystem.BackpackSystem:DeliverItemToPlayer(playerPawn,weaponItemId,neededWeaponNum)
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
    self:Internal_ServerReplenishWeaponItem(playerPawn,weaponConfig.AmmoItemId,weaponConfig.DeliverAmmoNumber)
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
    if weaponAmmoId > 0 then
        local ammoCnt = UGCBackpackSystemV2.GetItemCountV2(player,weaponAmmoId)
        UGCBackpackSystemV2.RemoveItemV2(player,weaponAmmoId,ammoCnt)
    end
    --
    local weaponItemId = weaponConfig.WeaponItemId
    local curCnt = UGCBackpackSystemV2.GetItemCountV2(player,weaponItemId)
    local removeCnt = UGCBackpackSystemV2.RemoveItemV2(player,weaponItemId,curCnt)
    return removeCnt >= curCnt
end

---@public
---@return number[]
function WeaponSystem:GetDefaultWeaponIDList(playerKey)
    return {10011,10091}
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

---@public 获取武器数量
function WeaponSystem:GetWeaponNumber(playerKey,weaponConfigID)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    if not playerPawn then
        return 0
    end
    local weaponItemID = GameplaySystem.WeaponConfigMgr:GetWeaponItemIDByConfigID(weaponConfigID)
    local ret = UGCBackpackSystemV2.GetItemCountV2(playerPawn,weaponItemID)
    return ret
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

---@public
---@return number[]
function WeaponSystem:GetPlayerWeaponConfigIDBySlot(playerKey,slotName)
    local playerController = UGCGameSystem.GetPlayerControllerByPlayerKey(playerKey)
    if not playerController then
        return 0
    end
    local itemDefineID = UGCBackpackSystemV2.GetEquippedItemBySlotName(playerController,slotName)
    if itemDefineID and itemDefineID.TypeSpecificID > 0 then
        local weaponConfigID = GameplaySystem.WeaponConfigMgr:GetWeaponConfigIDByItemID(itemDefineID.TypeSpecificID)
        return weaponConfigID
    end
    return 0
end

---@public
---@return number[]
function WeaponSystem:GetPlayerEquippedWeaponsConfigID(playerKey)
    local playerController = UGCGameSystem.GetPlayerControllerByPlayerKey(playerKey)
    if not playerController then
        return {}
    end
    local allWeaponSlots = self:GetAllWeaponSlots()
    local ret = {}
    for k,slotName in pairs(allWeaponSlots) do
        local itemDefineID = UGCBackpackSystemV2.GetEquippedItemBySlotName(playerController,slotName)
        if itemDefineID and itemDefineID.TypeSpecificID > 0 then
            local weaponConfigID = GameplaySystem.WeaponConfigMgr:GetWeaponConfigIDByItemID(itemDefineID.TypeSpecificID)
            table.insert(ret,weaponConfigID)
        end
    end
    return ret
end

---@public 补充武器以及弹药
function WeaponSystem:ServerReplenishWeaponAndAmmos(playerKey,weaponConfigID)
    local playerController = UGCGameSystem.GetPlayerControllerByPlayerKey(playerKey)
    if not UGCBackpackSystemV2.CheckInitPersistCompleted(playerController) then
        Print("WeaponSystem.ServerReplenishWeaponAndAmmos: Persist not ready")
        return false
    end
    local weaponConfig = GameplaySystem.WeaponConfigMgr:GetWeaponConfigData(weaponConfigID)
    local isWeaponEquipped = self:IsWeaponEquipped(playerKey,weaponConfigID)
    if not isWeaponEquipped then
        return false
    end
    --补充满武器数量
    self:Internal_ServerReplenishWeaponItem(playerController,weaponConfig.WeaponItemId,weaponConfig.MaxWeaponNum)
    --加满后备弹药
    self:Internal_ServerReplenishWeaponItem(playerController,weaponConfig.AmmoItemId,weaponConfig.DeliverAmmoNumber)
    return true
end

---@public 是否应该补充武器自身的数量
function WeaponSystem:ShouldReplenishWeaponSelfCount(weaponConfigID)
    local weaponConfig = GameplaySystem.WeaponConfigMgr:GetWeaponConfigData(weaponConfigID)
    if not weaponConfig then
        return false
    end
    local ret = weaponConfig.AmmoItemId <= 0
    return ret
end

return WeaponSystem