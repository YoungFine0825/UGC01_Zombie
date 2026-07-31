---@class BP_Interact_SodaMachine_QuickRevive_C:BP_Interact_SodaMachine_C
--Edit Below--
local BP_Interact_SodaMachine_QuickRevive = {}
 
--[[
function BP_Interact_SodaMachine_QuickRevive:ReceiveBeginPlay()
    BP_Interact_SodaMachine_QuickRevive.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Interact_SodaMachine_QuickRevive:ReceiveTick(DeltaTime)
    BP_Interact_SodaMachine_QuickRevive.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Interact_SodaMachine_QuickRevive:ReceiveEndPlay()
    BP_Interact_SodaMachine_QuickRevive.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Interact_SodaMachine_QuickRevive:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_SodaMachine_QuickRevive:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_SodaMachine_QuickRevive