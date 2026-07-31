---@class BP_Interact_WeaponSeller_C:BP_InteractableBase_C
---@field InteractBehaviour_PlaySound InteractBehaviour_PlaySound_C
---@field InteractBehaviour_PurchaseWeapon InteractBehaviour_PurchaseWeapon_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_WeaponSeller_C
local BP_Interact_WeaponSeller = BPExtent({},"Script.Blueprint.InteractEntity.BP_InteractableBase")
 
--[[--]]
function BP_Interact_WeaponSeller:ReceiveBeginPlay()
    BP_Interact_WeaponSeller.SuperClass.ReceiveBeginPlay(self)
end


--[[
function BP_Interact_WeaponSeller:ReceiveTick(DeltaTime)
    BP_Interact_WeaponSeller.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function BP_Interact_WeaponSeller:ReceiveEndPlay()
    BP_Interact_WeaponSeller.SuperClass.ReceiveEndPlay(self) 
end


--[[
function BP_Interact_WeaponSeller:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_WeaponSeller:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_WeaponSeller