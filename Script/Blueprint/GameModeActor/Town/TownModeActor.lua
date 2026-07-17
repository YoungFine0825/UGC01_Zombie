---@class TownModeActor_C:BP_Gameplay_LevelAcor_Base_C
---@field ServerGameplayComponent BP_ServerGameplayComponent_C
--Edit Below--
local TownModeActor = {}

local Metatable = UGCGameSystem.UGCRequire('Script.Blueprint.GameModeActor.BP_Gameplay_LevelAcor_Base')
setmetatable(TownModeActor,{__index = Metatable})
 
--[[--]]
function TownModeActor:ReceiveBeginPlay()
    TownModeActor.SuperClass.ReceiveBeginPlay(self)
end


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