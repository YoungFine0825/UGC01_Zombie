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
    self.m_preloadedIconTexture = nil
    self.m_weaponIconDynamicMaterial = nil
    if self.m_isClient then
        self:LoadWeaponIcon()
    end
end


--[[
function InteractBehaviour_PurchaseWeapon:ReceiveTick(DeltaTime)
    InteractBehaviour_PurchaseWeapon.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_PurchaseWeapon:ReceiveEndPlay()
    InteractBehaviour_PurchaseWeapon.SuperClass.ReceiveEndPlay(self)
    self.m_preloadedIconTexture = nil
    self.m_weaponIconDynamicMaterial = nil
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
        if GameplaySystem.WeaponSystem:ShouldReplenishWeaponSelfCount(self.WeaponConfigID) then
            self.m_interactEntityComp:ClientOverrideHUDTipsText(string.format("补充%s数量[花费%d点数]",weaponName,self.AmmoPrice))
        else
            self.m_interactEntityComp:ClientOverrideHUDTipsText(string.format("补充%s子弹[花费%d点数]",weaponName,self.AmmoPrice))
        end
    else
        self.m_interactEntityComp:ClientOverrideHUDTipsText(string.format("购买%s[花费%d点数]",weaponName,self.WeaponPrice))
    end
    return true,EInteractEntityErrCode.None
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
    local curSocre = GameplaySystem.PlayerSystem:GetPlayerCurrentScore(playerKey)
    if curSocre < price then
        return false,EInteractEntityErrCode.FailUnavailable--得分不够
    end
    if isWeaponEquipped then
        if GameplaySystem.WeaponSystem:ShouldReplenishWeaponSelfCount(self.WeaponConfigID) then
            local weaponConfig = GameplaySystem.WeaponConfigMgr:GetWeaponConfigData(self.WeaponConfigID)
            local weaponNum = GameplaySystem.WeaponSystem:GetWeaponNumber(playerKey,self.WeaponConfigID)
            if weaponNum >= weaponConfig.MaxWeaponNum then
                return false,EInteractEntityErrCode.FailWeaponAlreadyFully--武器数量已满
            end
        else
            local curMagAmmoNum = GameplaySystem.WeaponSystem:GetWeaponMagAmmoNum(playerKey,self.WeaponConfigID)
            local maxMagAmmoNum = GameplaySystem.WeaponSystem:GetWeaponMaxMagAmmoNum(self.WeaponConfigID)
            if curMagAmmoNum >= maxMagAmmoNum then
                return false,EInteractEntityErrCode.FailAmmoAlreadyFully--已经是满弹药
            end
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
    local successful = GameplaySystem.WeaponSystem:ServerDeliverAndEquipWeaponToPlayer(playerKey,self.WeaponConfigID,true)
    if successful then
        local isWeaponEquipped = GameplaySystem.WeaponSystem:IsWeaponEquipped(playerKey,self.WeaponConfigID)
        local price = isWeaponEquipped and self.AmmoPrice or self.WeaponPrice
        GameplaySystem.PlayerSystem:ConsumePlayerScore(playerKey,price)
    end
end

---@protected
function InteractBehaviour_PurchaseWeapon:LoadWeaponIcon()
    local iconPathObj = GameplaySystem.WeaponConfigMgr:GetWeaponEquipBarIconByConfigID(self.WeaponConfigID)
    if iconPathObj then
        local iconPath = UGCObjectUtility.GetPathBySoftObjectPath(iconPathObj)
        if iconPath and iconPath ~= "" then
            UGCObjectUtility.AsyncLoadObject(iconPath, function(texture)
                if self then
                    self.m_preloadedIconTexture = texture
                    self:ShowWeaponIcon()
                end
            end)
        end
    end
end

---@protected
function InteractBehaviour_PurchaseWeapon:ShowWeaponIcon()
    ---@type BP_Interact_WeaponSeller_C
    local owner = UGCActorComponentUtility.GetOwner(self)
    ---@type UPrimitiveComponent
    local weaponIconMesh = owner.Mesh0
    self.m_weaponIconDynamicMaterial = weaponIconMesh:CreateDynamicMaterialInstance(0)
    local texture = self.m_preloadedIconTexture
    self.m_weaponIconDynamicMaterial:SetTextureParameterValue("Albedo", texture)
end

return InteractBehaviour_PurchaseWeapon