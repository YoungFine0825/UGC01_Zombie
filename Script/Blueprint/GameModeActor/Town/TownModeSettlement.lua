local TownModeSettlement = {}
 
--[[--]]
function TownModeSettlement:LuaExecuteWithFinish(_, IsFinish)
    GameplayUtils.Print("TownModeSettlement.LuaExecuteWithFinish")
    local AllPlayer = UGCLevelFlowSystem.GetAllPlayerControllerInCurrentLevel()
    if AllPlayer and #AllPlayer > 0 then
        for k, Player in pairs(AllPlayer) do

            ---@type UGCPlayerState_C
            local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(Player)
            -- 在玩家结算的时候更新游戏时间
            PlayerState:UpdateGameTime()

            if not PlayerState.SettleParams.bIsSettled then

                --local UID = tonumber(Player.PlayerUID)

                -- 通知玩家结算
                PlayerState.SettleParams.bIsSettled = true
                PlayerState.SettleParams.bIsFinished = true

                UnrealNetwork.RepLazyProperty(PlayerState, "SettleParams")
            end
        end
    end
    self:OnFinish()
end


return TownModeSettlement