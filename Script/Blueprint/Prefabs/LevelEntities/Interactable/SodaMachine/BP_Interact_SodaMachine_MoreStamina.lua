---@class BP_Interact_SodaMachine_MoreStamina_C:BP_Interact_SodaMachine_C
--Edit Below--
local BP_Interact_SodaMachine_MoreStamina = {}
 
--[[
function BP_Interact_SodaMachine_MoreStamina:ReceiveBeginPlay()
    BP_Interact_SodaMachine_MoreStamina.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Interact_SodaMachine_MoreStamina:ReceiveTick(DeltaTime)
    BP_Interact_SodaMachine_MoreStamina.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Interact_SodaMachine_MoreStamina:ReceiveEndPlay()
    BP_Interact_SodaMachine_MoreStamina.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Interact_SodaMachine_MoreStamina:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_SodaMachine_MoreStamina:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_SodaMachine_MoreStamina