local SingleModeSettlement = {}
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')

function SingleModeSettlement:LuaExecuteWithFinish(_, IsFinish)

    ugcprint("Mgr2Settlement:LuaExecuteWithFinish")

    -- 获取当前InstanceId内的所有玩家
    local AllPlayer = UGCLevelFlowSystem.GetAllPlayerControllerInCurrentLevel()
    if AllPlayer and #AllPlayer > 0 then
    
        for k, Player in pairs(AllPlayer) do
            print(string.format("[SingleModeSettlement:LuaExecuteWithFinish] %s",tostring(k)))
        end

        for k, Player in pairs(AllPlayer) do
            

            local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(Player)
            -- 在玩家结算的时候更新游戏时间
            PlayerState:UpdateGameTime()
            print(string.format("[SingleModeSettlement:LuaExecuteWithFinish] Player: %s , PlayerState.SettleParams.bIsSettled : %s , PlayerState.SettleParams.bIsFinished : %s", tostring(Player.PlayerKey), tostring(PlayerState.SettleParams.bIsSettled), tostring(PlayerState.SettleParams.bIsFinished)))

            if not PlayerState.SettleParams.bIsSettled then

                if IsFinish then
                    -- 保存玩家通关数据，将解锁的下一关保存到玩家数据中
                    local UID = tonumber(Player.PlayerUID)
                    ugcprint(string.format("[Mgr2Settlement:LuaExecuteWithFinish] UID: %d", UID))
                    local PlayerData = UGCPlayerStateSystem.GetPlayerArchiveData(UID)


                    if PlayerData == nil then
                        ugcprint(string.format("[Mgr2Settlement:LuaExecuteWithFinish] UID: %d PlayerData is empty, creating new one.", UID))
                        PlayerData = {
                            GameCompletionRecord = {}
                        }
                    end

                    local ModeID = UGCMultiMode.GetModeID()
                    local UnlockModeIDs = UGCGameData.GetUnlockModeID(ModeID)
                    PlayerState.IsModeUnLock = false
                    -- 遍历所有需要解锁的模式ID
                    for _, modeId in ipairs(UnlockModeIDs) do
                        local bIsFind = false
                        -- 检查是否已存在解锁记录
                        for _, v in pairs(PlayerData.GameCompletionRecord) do
                            if v == modeId then
                                bIsFind = true
                                break
                            end
                        end
                        -- 如果未找到则添加新记录
                        if not bIsFind then
                            PlayerState.IsModeUnLock = true  -- 只要有一个新模式解锁就标记
                            table.insert(PlayerData.GameCompletionRecord, modeId)
                        end
                    end
                    UnrealNetwork.RepLazyProperty(PlayerState, "IsModeUnLock")
                    
                    UGCPlayerStateSystem.SavePlayerArchiveData(tonumber(Player.PlayerUID), PlayerData)

                    ugcprint(string.format("[Mgr2Settlement:LuaExecuteWithFinish] UID: %d PlayerData.GameCompletionRecord: %s", UID, table.concat( PlayerData.GameCompletionRecord, ", ")))

                end

                -- 通知玩家结算
                PlayerState.SettleParams.bIsSettled = true
                PlayerState.SettleParams.bIsFinished = IsFinish == nil and true or IsFinish

                UnrealNetwork.RepLazyProperty(PlayerState, "SettleParams")
            end
        end
    else
        ugcprint("SingleModeSettlement:LuaExecuteWithFinish AllPlayer is nil")
    end

end

--[[
function SingleModeSettlement:ReceiveBeginPlay()
    SingleModeSettlement.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SingleModeSettlement:ReceiveTick(DeltaTime)
    SingleModeSettlement.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SingleModeSettlement:ReceiveEndPlay()
    SingleModeSettlement.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SingleModeSettlement:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleModeSettlement:GetAvailableServerRPCs()
    return
end
--]]

return SingleModeSettlement