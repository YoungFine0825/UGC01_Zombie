local SingleMode_1_LevelReward = {}
 
--[[
function SingleMode_1_LevelReward:ReceiveBeginPlay()
    SingleMode_1_LevelReward.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SingleMode_1_LevelReward:ReceiveTick(DeltaTime)
    SingleMode_1_LevelReward.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SingleMode_1_LevelReward:ReceiveEndPlay()
    SingleMode_1_LevelReward.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SingleMode_1_LevelReward:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleMode_1_LevelReward:GetAvailableServerRPCs()
    return
end
--]]

return SingleMode_1_LevelReward