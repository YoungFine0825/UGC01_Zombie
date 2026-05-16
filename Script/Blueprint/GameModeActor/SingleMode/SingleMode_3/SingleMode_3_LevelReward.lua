local SingleMode_3_LevelReward = {}
 
--[[
function SingleMode_3_LevelReward:ReceiveBeginPlay()
    SingleMode_3_LevelReward.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SingleMode_3_LevelReward:ReceiveTick(DeltaTime)
    SingleMode_3_LevelReward.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SingleMode_3_LevelReward:ReceiveEndPlay()
    SingleMode_3_LevelReward.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SingleMode_3_LevelReward:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleMode_3_LevelReward:GetAvailableServerRPCs()
    return
end
--]]

return SingleMode_3_LevelReward