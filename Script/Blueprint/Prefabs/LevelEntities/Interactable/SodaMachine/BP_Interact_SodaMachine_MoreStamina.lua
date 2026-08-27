---@class BP_Interact_SodaMachine_MoreStamina_C:BP_Interact_SodaMachine_C
--Edit Below--

local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_SodaMachine_MoreStamina_C
local BP_Interact_SodaMachine_MoreStamina = BPExtent({},"Script.Blueprint.Prefabs.LevelEntities.Interactable.SodaMachine.BP_Interact_SodaMachine")


--[[--]]
function BP_Interact_SodaMachine_MoreStamina:ReceiveBeginPlay()
    BP_Interact_SodaMachine_MoreStamina.SuperClass.ReceiveBeginPlay(self)
end


--[[--]]
function BP_Interact_SodaMachine_MoreStamina:ReceiveTick(DeltaTime)
    BP_Interact_SodaMachine_MoreStamina.SuperClass.ReceiveTick(self, DeltaTime)
end


--[[--]]
function BP_Interact_SodaMachine_MoreStamina:ReceiveEndPlay()
    if BP_Interact_SodaMachine_MoreStamina.SuperClass then
        BP_Interact_SodaMachine_MoreStamina.SuperClass.ReceiveEndPlay(self)
    end
end


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
