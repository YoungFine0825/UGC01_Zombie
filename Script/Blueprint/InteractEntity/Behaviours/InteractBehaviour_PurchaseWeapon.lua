---@class InteractBehaviour_PurchaseWeapon_C:BP_InteractEntityBehaviourComponent_C
---@field WeaponConfigID int32
---@field WeaponPrice float
---@field AmmoPrice float
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_PurchaseWeapon_C
local InteractBehaviour_PurchaseWeapon = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_PurchaseWeapon:ReceiveBeginPlay()
    InteractBehaviour_PurchaseWeapon.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_PurchaseWeapon:ReceiveTick(DeltaTime)
    InteractBehaviour_PurchaseWeapon.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_PurchaseWeapon:ReceiveEndPlay()
    InteractBehaviour_PurchaseWeapon.SuperClass.ReceiveEndPlay(self) 
end

---@public 客户端提前判断是否可以交互
---@param playerKey number 请求交互的玩家的playerKey
---@return boolean
---@return number EInteractEntityErrCode
function InteractBehaviour_PurchaseWeapon:CanInteract(playerKey)
    local canInteract,errcode = self.BaseClass.CanInteract(self,playerKey)
    if not canInteract then
        return canInteract,errcode
    end
    --
    local weaponGained = GameplaySystem.WeaponSystem:IsWeaponEquipped(playerKey,self.WeaponConfigID)
    local weaponName = GameplaySystem.WeaponConfigMgr:GetWeaponName(self.WeaponConfigID)
    if weaponGained then
        self.m_interactEntityComp:ClientOverrideHUDTipsText(string.format("购买%s子弹[花费%d点数]",weaponName,self.AmmoPrice))
    else
        self.m_interactEntityComp:ClientOverrideHUDTipsText(string.format("购买%s[花费%d点数]",weaponName,self.WeaponPrice))
    end
    return true
end

---@public 服务端检查交互行为是否符合条件
---@param playerKey number 请求交互的玩家的playerKey
---@return boolean
---@return number EInteractEntityErrCode
function InteractBehaviour_PurchaseWeapon:CanExecute(playerKey)
    if self.m_isClient then
        return true,EInteractEntityErrCode.None
    end
    local parentRet,parentErr = self.BaseClass.CanExecute(self,playerKey)
    if not parentRet then
        return parentRet,parentErr
    end
    local isWeaponEquipped = GameplaySystem.WeaponSystem:IsWeaponEquipped(playerKey,self.WeaponConfigID)
    local price = isWeaponEquipped and self.AmmoPrice or self.WeaponPrice
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    local playerPropertyName = "Score"
    local propertyValue = UGCAttributeSystem.GetGameAttributeValue(playerPawn,playerPropertyName)
    if propertyValue < price then
        return false,EInteractEntityErrCode.FailUnavailable--得分不够
    end
    if isWeaponEquipped then
        local curMagAmmoNum = GameplaySystem.WeaponSystem:GetWeaponMagAmmoNum(playerKey,self.WeaponConfigID)
        local maxMagAmmoNum = GameplaySystem.WeaponSystem:GetWeaponMaxMagAmmoNum(self.WeaponConfigID)
        if curMagAmmoNum >= maxMagAmmoNum then
            return false,EInteractEntityErrCode.FailAmmoAlreadyFully--已经是满弹药
        end
    end
    return true,EInteractEntityErrCode.None
end

---@public 服务端&客户端执行
---@param playerKey number 请求交互的玩家的playerKey
function InteractBehaviour_PurchaseWeapon:Execute(playerKey)
    if self.m_isClient then
        return
    end
    --派发武器
    local successful = GameplaySystem.WeaponSystem:ServerDeliverAndEquipWeaponToPlayer(playerKey,self.WeaponConfigID)
    if successful then
        local isWeaponEquipped = GameplaySystem.WeaponSystem:IsWeaponEquipped(playerKey,self.WeaponConfigID)
        local price = isWeaponEquipped and self.AmmoPrice or self.WeaponPrice
        local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
        local playerPropertyName = "Score"
        local propertyValue = UGCAttributeSystem.GetGameAttributeValue(playerPawn,playerPropertyName)
        local newValue = math.max(0,propertyValue - price)
        UGCAttributeSystem.SetGameAttributeValue(playerPawn,playerPropertyName,newValue)
    end
end

return InteractBehaviour_PurchaseWeapon