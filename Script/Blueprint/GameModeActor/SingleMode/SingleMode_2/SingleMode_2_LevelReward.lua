local SingleMode_2_LevelReward = {}
 
--[[
function SingleMode_2_LevelReward:ReceiveBeginPlay()
    SingleMode_2_LevelReward.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SingleMode_2_LevelReward:ReceiveTick(DeltaTime)
    SingleMode_2_LevelReward.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SingleMode_2_LevelReward:ReceiveEndPlay()
    SingleMode_2_LevelReward.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SingleMode_2_LevelReward:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleMode_2_LevelReward:GetAvailableServerRPCs()
    return
end
--]]

return SingleMode_2_LevelReward