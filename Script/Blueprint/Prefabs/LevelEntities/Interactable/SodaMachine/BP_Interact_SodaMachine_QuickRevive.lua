---@class BP_Interact_SodaMachine_QuickRevive_C:BP_Interact_SodaMachine_C
--Edit Below--

local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_SodaMachine_QuickRevive_C
local BP_Interact_SodaMachine_QuickRevive = BPExtent({},"Script.Blueprint.Prefabs.LevelEntities.Interactable.SodaMachine.BP_Interact_SodaMachine")


--[[--]]
function BP_Interact_SodaMachine_QuickRevive:ReceiveBeginPlay()
    BP_Interact_SodaMachine_QuickRevive.SuperClass.ReceiveBeginPlay(self)
end


--[[--]]
function BP_Interact_SodaMachine_QuickRevive:ReceiveTick(DeltaTime)
    BP_Interact_SodaMachine_QuickRevive.SuperClass.ReceiveTick(self, DeltaTime)
end


--[[--]]
function BP_Interact_SodaMachine_QuickRevive:ReceiveEndPlay()
    if BP_Interact_SodaMachine_QuickRevive.SuperClass then
        BP_Interact_SodaMachine_QuickRevive.SuperClass.ReceiveEndPlay(self)
    end
end


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
