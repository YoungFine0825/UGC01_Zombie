---@class BP_Interact_SodaMachine_MoreHealth_C:BP_Interact_SodaMachine_C
--Edit Below--

local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_SodaMachine_MoreHealth_C
local BP_Interact_SodaMachine_MoreHealth = BPExtent({},"Script.Blueprint.Prefabs.LevelEntities.Interactable.SodaMachine.BP_Interact_SodaMachine")


--[[--]]
function BP_Interact_SodaMachine_MoreHealth:ReceiveBeginPlay()
    BP_Interact_SodaMachine_MoreHealth.SuperClass.ReceiveBeginPlay(self)
end


--[[--]]
function BP_Interact_SodaMachine_MoreHealth:ReceiveTick(DeltaTime)
    BP_Interact_SodaMachine_MoreHealth.SuperClass.ReceiveTick(self, DeltaTime)
end


--[[--]]
function BP_Interact_SodaMachine_MoreHealth:ReceiveEndPlay()
    if BP_Interact_SodaMachine_MoreHealth.SuperClass then
        BP_Interact_SodaMachine_MoreHealth.SuperClass.ReceiveEndPlay(self)
    end
end


--[[
function BP_Interact_SodaMachine_MoreHealth:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_SodaMachine_MoreHealth:GetAvailableServerRPCs()
    return
end
--]]


return BP_Interact_SodaMachine_MoreHealth
