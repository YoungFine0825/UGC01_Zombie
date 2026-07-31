---@class BP_Interact_TeamBuff_InstaKill_C:BP_Interact_TeamBuff_C
---@field InteractBehaviour_Grant InteractBehaviour_Grant_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_TeamBuff_InstaKill_C
local BP_Interact_TeamBuff_InstaKill = BPExtent({},"Script.Blueprint.TeamBuffs.BP_Interact_TeamBuff")
 
--[[
function BP_Interact_TeamBuff_InstaKill:ReceiveBeginPlay()
    BP_Interact_TeamBuff_InstaKill.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Interact_TeamBuff_InstaKill:ReceiveTick(DeltaTime)
    BP_Interact_TeamBuff_InstaKill.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Interact_TeamBuff_InstaKill:ReceiveEndPlay()
    BP_Interact_TeamBuff_InstaKill.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Interact_TeamBuff_InstaKill:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_TeamBuff_InstaKill:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_TeamBuff_InstaKill