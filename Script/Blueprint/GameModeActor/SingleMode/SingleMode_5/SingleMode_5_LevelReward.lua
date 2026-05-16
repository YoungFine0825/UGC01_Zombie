local SingleMode_5_LevelReward = {}
 
--[[
function SingleMode_5_LevelReward:ReceiveBeginPlay()
    SingleMode_5_LevelReward.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SingleMode_5_LevelReward:ReceiveTick(DeltaTime)
    SingleMode_5_LevelReward.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SingleMode_5_LevelReward:ReceiveEndPlay()
    SingleMode_5_LevelReward.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SingleMode_5_LevelReward:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleMode_5_LevelReward:GetAvailableServerRPCs()
    return
end
--]]

return SingleMode_5_LevelReward