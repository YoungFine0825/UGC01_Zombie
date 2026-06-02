---@class TownModeActor_C:UGCLevelActor
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local TownModeActor = {}
 
--[[
function TownModeActor:ReceiveBeginPlay()
    TownModeActor.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function TownModeActor:ReceiveTick(DeltaTime)
    TownModeActor.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function TownModeActor:ReceiveEndPlay()
    TownModeActor.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function TownModeActor:GetReplicatedProperties()
    return
end
--]]

--[[
function TownModeActor:GetAvailableServerRPCs()
    return
end
--]]

return TownModeActor