---@class GymModeActor_C:BP_Gameplay_LevelAcor_Base_C
--Edit Below--
local GymModeActor = {}
 
--[[
function GymModeActor:ReceiveBeginPlay()
    GymModeActor.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function GymModeActor:ReceiveTick(DeltaTime)
    GymModeActor.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function GymModeActor:ReceiveEndPlay()
    GymModeActor.SuperClass.ReceiveEndPlay(self) 
end
--]]

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