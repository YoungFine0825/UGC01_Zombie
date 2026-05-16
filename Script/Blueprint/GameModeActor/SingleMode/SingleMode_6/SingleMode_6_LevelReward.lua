local SingleMode_6_LevelReward = {}
 
--[[
function SingleMode_6_LevelReward:ReceiveBeginPlay()
    SingleMode_6_LevelReward.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SingleMode_6_LevelReward:ReceiveTick(DeltaTime)
    SingleMode_6_LevelReward.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SingleMode_6_LevelReward:ReceiveEndPlay()
    SingleMode_6_LevelReward.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SingleMode_6_LevelReward:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleMode_6_LevelReward:GetAvailableServerRPCs()
    return
end
--]]

return SingleMode_6_LevelReward