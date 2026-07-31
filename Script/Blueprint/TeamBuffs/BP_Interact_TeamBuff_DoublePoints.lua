---@class BP_Interact_TeamBuff_DoublePoints_C:BP_Interact_TeamBuff_C
---@field InteractBehaviour_Grant InteractBehaviour_Grant_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_TeamBuff_DoublePoints_C
local BP_Interact_TeamBuff_DoublePoints = BPExtent({},"Script.Blueprint.TeamBuffs.BP_Interact_TeamBuff")
 
--[[--]]
function BP_Interact_TeamBuff_DoublePoints:ReceiveBeginPlay()
    BP_Interact_TeamBuff_DoublePoints.SuperClass.ReceiveBeginPlay(self)
end


--[[
function BP_Interact_TeamBuff_DoublePoints:ReceiveTick(DeltaTime)
    BP_Interact_TeamBuff_DoublePoints.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function BP_Interact_TeamBuff_DoublePoints:ReceiveEndPlay()
    BP_Interact_TeamBuff_DoublePoints.SuperClass.ReceiveEndPlay(self) 
end


--[[
function BP_Interact_TeamBuff_DoublePoints:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_TeamBuff_DoublePoints:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_TeamBuff_DoublePoints