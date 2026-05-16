local SingleModeTimeOut = {}

function SingleModeTimeOut:LuaExecute()

    ugcprint(string.format("SingleModeTimeOut:LuaExecute InstanceId"))

    -- 获取当前InstanceId内的所有玩家
    local AllPlayer = UGCLevelFlowSystem.GetAllPlayerControllerInCurrentLevel()

    if AllPlayer and #AllPlayer > 0 then
        for k, Player in pairs(AllPlayer) do

            local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(Player)
            -- 如果超时，逐个玩家调用失败结算
            if not PlayerState.SettleParams.bIsSettled then
                PlayerState.SettleParams.bIsSettled = true
                PlayerState.SettleParams.bIsFinished = false
                UnrealNetwork.RepLazyProperty(PlayerState, "SettleParams")
            end
        end
    else
        ugcprint("SingleModeTimeOut:LuaExecute AllPlayer is nil")
    end

end
 
--[[
function SingleModeTimeOut:ReceiveBeginPlay()
    SingleModeTimeOut.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SingleModeTimeOut:ReceiveTick(DeltaTime)
    SingleModeTimeOut.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SingleModeTimeOut:ReceiveEndPlay()
    SingleModeTimeOut.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SingleModeTimeOut:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleModeTimeOut:GetAvailableServerRPCs()
    return
end
--]]

return SingleModeTimeOut