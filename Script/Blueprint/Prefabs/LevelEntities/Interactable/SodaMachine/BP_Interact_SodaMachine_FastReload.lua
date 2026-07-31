---@class BP_Interact_SodaMachine_FastReload_C:BP_Interact_SodaMachine_C
--Edit Below--
local BP_Interact_SodaMachine_FastReload = {}
 
--[[
function BP_Interact_SodaMachine_FastReload:ReceiveBeginPlay()
    BP_Interact_SodaMachine_FastReload.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Interact_SodaMachine_FastReload:ReceiveTick(DeltaTime)
    BP_Interact_SodaMachine_FastReload.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Interact_SodaMachine_FastReload:ReceiveEndPlay()
    BP_Interact_SodaMachine_FastReload.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Interact_SodaMachine_FastReload:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_SodaMachine_FastReload:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_SodaMachine_FastReload