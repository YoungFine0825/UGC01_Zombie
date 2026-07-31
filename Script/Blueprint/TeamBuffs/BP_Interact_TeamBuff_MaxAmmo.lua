---@class BP_Interact_TeamBuff_MaxAmmo_C:BP_Interact_TeamBuff_C
---@field InteractBehaviour_TeamBuff_MaxAmmo InteractBehaviour_TeamBuff_MaxAmmo_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_TeamBuff_MaxAmmo_C
local BP_Interact_TeamBuff_MaxAmmo = BPExtent({},"Script.Blueprint.TeamBuffs.BP_Interact_TeamBuff")
 
--[[--]]
function BP_Interact_TeamBuff_MaxAmmo:ReceiveBeginPlay()
    BP_Interact_TeamBuff_MaxAmmo.SuperClass.ReceiveBeginPlay(self)
end


--[[
function BP_Interact_TeamBuff_MaxAmmo:ReceiveTick(DeltaTime)
    BP_Interact_TeamBuff_MaxAmmo.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function BP_Interact_TeamBuff_MaxAmmo:ReceiveEndPlay()
    BP_Interact_TeamBuff_MaxAmmo.SuperClass.ReceiveEndPlay(self) 
end


--[[
function BP_Interact_TeamBuff_MaxAmmo:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_TeamBuff_MaxAmmo:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_TeamBuff_MaxAmmo