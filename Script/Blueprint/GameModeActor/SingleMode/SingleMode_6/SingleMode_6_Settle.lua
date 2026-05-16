local SingleMode_6_Settle = {}

function SingleMode_6_Settle:LuaExecuteWithFinish(InstanceId, IsFinish)
    
    ugcprint("SingleMode_6_Settle:LuaExecuteWithFinish")

    UGCLevelFlowSystem.GameSettle(IsFinish)

end

--[[
function SingleMode_6_Settle:ReceiveBeginPlay()
    SingleMode_6_Settle.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SingleMode_6_Settle:ReceiveTick(DeltaTime)
    SingleMode_6_Settle.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SingleMode_6_Settle:ReceiveEndPlay()
    SingleMode_6_Settle.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SingleMode_6_Settle:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleMode_6_Settle:GetAvailableServerRPCs()
    return
end
--]]

return SingleMode_6_Settle