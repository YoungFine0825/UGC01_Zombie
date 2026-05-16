local SingleMode_4_LevelReward = {}
 
--[[
function SingleMode_4_LevelReward:ReceiveBeginPlay()
    SingleMode_4_LevelReward.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SingleMode_4_LevelReward:ReceiveTick(DeltaTime)
    SingleMode_4_LevelReward.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SingleMode_4_LevelReward:ReceiveEndPlay()
    SingleMode_4_LevelReward.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SingleMode_4_LevelReward:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleMode_4_LevelReward:GetAvailableServerRPCs()
    return
end
--]]

return SingleMode_4_LevelReward