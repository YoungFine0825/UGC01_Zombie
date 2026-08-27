---@class LobbyModeActor_C:UGCLevelActor
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local LobbyModeActor = {}
 
--[[
function LobbyModeActor:ReceiveBeginPlay()
    LobbyModeActor.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function LobbyModeActor:ReceiveTick(DeltaTime)
    LobbyModeActor.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function LobbyModeActor:ReceiveEndPlay()
    LobbyModeActor.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function LobbyModeActor:GetReplicatedProperties()
    return
end
--]]

--[[
function LobbyModeActor:GetAvailableServerRPCs()
    return
end
--]]

return LobbyModeActor