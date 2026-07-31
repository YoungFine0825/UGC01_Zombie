---@class GymModeActor_C:BP_Gameplay_LevelAcor_Base_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type GymModeActor_C
local GymModeActor = BPExtent({},"Script.Blueprint.GameModeActor.BP_Gameplay_LevelAcor_Base")
 
--[[--]]
function GymModeActor:ReceiveBeginPlay()
    GymModeActor.SuperClass.ReceiveBeginPlay(self)
end


--[[
function GymModeActor:ReceiveTick(DeltaTime)
    GymModeActor.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function GymModeActor:ReceiveEndPlay()
    GymModeActor.SuperClass.ReceiveEndPlay(self) 
end


--[[
function GymModeActor:GetReplicatedProperties()
    return
end
--]]

--[[
function GymModeActor:GetAvailableServerRPCs()
    return
end
--]]

return GymModeActor