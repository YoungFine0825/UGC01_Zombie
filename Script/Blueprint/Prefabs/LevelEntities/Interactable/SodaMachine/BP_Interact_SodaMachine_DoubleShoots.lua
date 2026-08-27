---@class BP_Interact_SodaMachine_DoubleShoots_C:BP_Interact_SodaMachine_C
--Edit Below--

local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_SodaMachine_DoubleShoots_C
local BP_Interact_SodaMachine_DoubleShoots = BPExtent({},"Script.Blueprint.Prefabs.LevelEntities.Interactable.SodaMachine.BP_Interact_SodaMachine")


--[[--]]
function BP_Interact_SodaMachine_DoubleShoots:ReceiveBeginPlay()
    BP_Interact_SodaMachine_DoubleShoots.SuperClass.ReceiveBeginPlay(self)
end


--[[--]]
function BP_Interact_SodaMachine_DoubleShoots:ReceiveTick(DeltaTime)
    BP_Interact_SodaMachine_DoubleShoots.SuperClass.ReceiveTick(self, DeltaTime)
end


--[[--]]
function BP_Interact_SodaMachine_DoubleShoots:ReceiveEndPlay()
    if BP_Interact_SodaMachine_DoubleShoots.SuperClass then
        BP_Interact_SodaMachine_DoubleShoots.SuperClass.ReceiveEndPlay(self)
    end
end


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
