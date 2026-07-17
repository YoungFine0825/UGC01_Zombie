---@class BP_Interact_WeaponLottery_C:BP_InteractableBase_C
---@field BoxMesh UStaticMeshComponent
---@field InteractBehaviour_WeaponLottery InteractBehaviour_WeaponLottery_C
--Edit Below--
local BP_Interact_WeaponLottery = {}
 
--[[
function BP_Interact_WeaponLottery:ReceiveBeginPlay()
    BP_Interact_WeaponLottery.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Interact_WeaponLottery:ReceiveTick(DeltaTime)
    BP_Interact_WeaponLottery.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Interact_WeaponLottery:ReceiveEndPlay()
    BP_Interact_WeaponLottery.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Interact_WeaponLottery:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_WeaponLottery:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_WeaponLottery