---@class BP_Interact_SodaMachine_DoubleShoots_C:BP_Interact_SodaMachine_C
--Edit Below--
local BP_Interact_SodaMachine_DoubleShoots = {}
 
--[[
function BP_Interact_SodaMachine_DoubleShoots:ReceiveBeginPlay()
    BP_Interact_SodaMachine_DoubleShoots.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Interact_SodaMachine_DoubleShoots:ReceiveTick(DeltaTime)
    BP_Interact_SodaMachine_DoubleShoots.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Interact_SodaMachine_DoubleShoots:ReceiveEndPlay()
    BP_Interact_SodaMachine_DoubleShoots.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Interact_SodaMachine_DoubleShoots:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_SodaMachine_DoubleShoots:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_SodaMachine_DoubleShoots