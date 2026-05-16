local SingleMode_1_Settle = {}
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')

function SingleMode_1_Settle:LuaExecuteWithFinish(InstanceId, IsFinish)

    if not IsFinish then
        -- 如果关卡失败，则返回，若需自定义逻辑可在这里处理
        print("SingleMode_1 Failed")
        UGCGameSystem.GameState.LevelState = UGCGameSystem.GameState.LevelStateEnum.Failure
        return
    end

    ugcprint("SingleMode_1_Settle:LuaExecuteWithFinish")
    UGCGameSystem.GameState.LevelState = UGCGameSystem.GameState.LevelStateEnum.Victory

    -- 获取当前InstanceId内的所有玩家
    local AllPlayer = UGCLevelFlowSystem.GetAllPlayerControllerInCurrentLevel()
    
    -- 每个玩家调用RPC弹出商店UI
    if AllPlayer and #AllPlayer > 0 then
        for k, Player in pairs(AllPlayer) do
            if Player and UGCObjectUtility.IsObjectValid(Player) then
                -- 如果玩家在通关的时候仍然处于倒地状态，则扶起
                local pawn = UGCGameSystem.GetPlayerPawnByPlayerController(Player)
                local DyingTag = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Dying")
                local DeadTag = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Dead")
                if pawn and UGCPersistEffectSystem.HasDynamicState(pawn, DyingTag) then
                    ugcprint("SingleMode_1_Settle:LuaExecuteWithFinish Player"..tostring(UGCGameSystem.GetPlayerKeyByPlayerController(Player)).." is dying")
                    pawn.RescueOtherComponent:RescueSucImmediately(pawn)
                end

                -- 如果玩家在通关的时候仍然处于死亡状态，则复活
                if not pawn or UGCPersistEffectSystem.HasDynamicState(pawn, DeadTag) then
                    ugcprint("SingleMode_1_Settle:LuaExecuteWithFinish Player"..tostring(UGCGameSystem.GetPlayerKeyByPlayerController(Player)).." is dead")
                    UGCPlayerPawnSystem.RespawnPlayer(UGCGameSystem.GetPlayerKeyByPlayerController(Player), 0, true)
                else
                    UGCPawnAttrSystem.SetHealth(pawn, UGCPawnAttrSystem.GetHealthMax(pawn))
                end
                -- 打开关底商店
                ugcprint("SingleMode_1_Settle:LuaExecuteWithFinish Player"..tostring(UGCGameSystem.GetPlayerKeyByPlayerController(Player)).." open shop")
                Player:CallOpenShop()

                -- 为通关玩家加经验
                ugcprint("SingleMode_1_Settle:LuaExecuteWithFinish Player"..tostring(UGCGameSystem.GetPlayerKeyByPlayerController(Player)).." add exp")
                UGCGameSystem.GetPlayerStateByPlayerController(Player):AddExp(UGCGameData.GetSettlementExpCount(UGCMultiMode.GetModeID()))

                -- 为通关玩家加天赋点
                ugcprint("SingleMode_1_Settle:LuaExecuteWithFinish Player"..tostring(UGCGameSystem.GetPlayerKeyByPlayerController(Player)).." add talent point")
                TalentTreeManager:AddTalentPoints(UGCGameData.GetSettlementTalentCount(UGCMultiMode.GetModeID()), UGCGameSystem.GetPlayerKeyByPlayerController(Player))
            end
        end
    else
        ugcprint("SingleMode_1_Settle:LuaExecuteWithFinish AllPlayer is nil")
    end
    
    -- 结算完成，弹出传送门
    self:OnFinish()

end

--[[
function SingleMode_1_Settle:ReceiveBeginPlay()
    SingleMode_1_Settle.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SingleMode_1_Settle:ReceiveTick(DeltaTime)
    SingleMode_1_Settle.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SingleMode_1_Settle:ReceiveEndPlay()
    SingleMode_1_Settle.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SingleMode_1_Settle:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleMode_1_Settle:GetAvailableServerRPCs()
    return
end
--]]

return SingleMode_1_Settle