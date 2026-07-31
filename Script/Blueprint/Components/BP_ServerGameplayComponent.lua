---@class BP_ServerGameplayComponent_C:ActorComponent
--Edit Below--
--[[
    局内游戏基础服务端逻辑组件，主要用于控制游戏流程，挂在LevelActor上

--]]
---@type BP_ServerGameplayComponent_C
local BP_ServerGameplayComponent = {
    ---@type boolean
    bGameplayStarted = false,
    ---@type boolean
    bUGCLevelBegin = false,
    ---@type boolean
    bUGCGameBegin = false,
}
 
--[[--]]
function BP_ServerGameplayComponent:ReceiveBeginPlay()
    GameplayUtils.Print("BP_ServerGameplayComponent.ReceiveBeginPlay")
    BP_ServerGameplayComponent.SuperClass.ReceiveBeginPlay(self)
    if UGCGameSystem.IsServer() then
        self:OnServerBeginPlay()
    end
end


--[[
function BP_ServerGameplayComponent:ReceiveTick(DeltaTime)
    BP_ServerGameplayComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]

function BP_ServerGameplayComponent:ReceiveEndPlay()
    BP_ServerGameplayComponent.SuperClass.ReceiveEndPlay(self) 
    if UGCGameSystem.IsServer() then
        self:OnServerEndPlay()
    end
end

---@protected
function BP_ServerGameplayComponent:OnServerBeginPlay()
    GameplayUtils.Print("BP_ServerGameplayComponent.OnServerBeginPlay")
    local MsgSys = UGCGenericMessageSystem
    MsgSys.ListenGlobalMessage(self,"UGC.LevelFlow.LevelBegin",self,self.OnLevelBegin)
    MsgSys.ListenGlobalMessage(self,"UGC.LevelFlow.GameBegin",self,self.OnGameBegin)
    local SpawnMessage = MsgSys.Messages.UGC.PlayerPawn.PawnSpawn
    MsgSys.ListenGlobalMessage(self, SpawnMessage, self, self.OnPlayerSpawn)
    MsgSys.ListenGlobalMessage(self,GameplayEvents.Server.OnPlayerAliveStateChanged,self,self.OnPlayerAliveStateChanged)
    MsgSys.ListenGlobalMessage(self,GameplayEvents.Server.OnAllZombiesBeEliminated,self,self.OnAllZombiesBeEliminated)
    MsgSys.ListenGlobalMessage(self,GameplayEvents.Server.OnAllPlayersDead,self,self.OnAllPlayersDead)
end

---@protected
function BP_ServerGameplayComponent:OnServerEndPlay()
    GameplayUtils.Print("BP_ServerGameplayComponent.OnServerEndPlay")
    local MsgSys = UGCGenericMessageSystem
    MsgSys.UnListenMessage(self,"UGC.LevelFlow.LevelBegin")
    MsgSys.UnListenMessage(self,"UGC.LevelFlow.GameBegin")
    MsgSys.UnListenMessage(self,UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnSpawn)
    MsgSys.UnListenMessage(self,GameplayEvents.Server.OnPlayerAliveStateChanged)
    MsgSys.UnListenMessage(self,GameplayEvents.Server.OnAllZombiesBeEliminated)
    MsgSys.UnListenMessage(self,GameplayEvents.Server.OnAllPlayersDead)
end

--[[
function BP_ServerGameplayComponent:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_ServerGameplayComponent:GetAvailableServerRPCs()
    return
end
--]]

---@protected
function BP_ServerGameplayComponent:OnLevelBegin()
    GameplayUtils.Print("BP_ServerGameplayComponent.OnLevelBegin: 关卡加载完成！！！")
    self.bUGCLevelBegin = true
    self:TryStartGameplay()
end

---@protected
function BP_ServerGameplayComponent:OnGameBegin()
    if self.bUGCGameBegin then
        return
    end
    self.bUGCGameBegin = true
    self:TryStartGameplay()
end

---@protected
function BP_ServerGameplayComponent:OnPlayerSpawn(PlayerKey)
    GameplayUtils.Print("BP_ServerGameplayComponent.OnPlayerSpawn: 玩家PlayerPawn创建完成！！！")

    self:TryStartGameplay()
end

---@protected
function BP_ServerGameplayComponent:TryStartGameplay()
    if self.bGameplayStarted then
        return
    end
    if not self.bUGCLevelBegin then
        return
    end
    local allPC = UGCGameSystem.GetAllPlayerController(false)
    if not allPC or #allPC <= 0 then
        GameplayUtils.Print("BP_ServerGameplayComponent.TryStartGameplay: 还未创建任何PlayerController！！！")
        return
    end
    for _, pc in pairs(allPC) do
        local pawn = UGCGameSystem.GetPlayerPawnByPlayerController(pc)
        if pawn == nil then
            GameplayUtils.Print("BP_ServerGameplayComponent.TryStartGameplay: 还有玩家的PlayerPawn未创建！！！")
            return--还有玩家Pawn未创建完成
        end
    end
    GameplayUtils.Print("BP_ServerGameplayComponent.TryStartGameplay")
    self.bGameplayStarted = true
    self:ReadyToStartGameplay()
end

function BP_ServerGameplayComponent:ReadyToStartGameplay()
    GameplayUtils.Print("BP_ServerGameplayComponent.ReadyToStartGameplay")
    local gameplayState = GameplaySystem.GetGameplayStateComponent()
    --
    gameplayState.GameStateInfo.GameState = EGameState.Gaming
    gameplayState.GameStateInfo.GameStartTime = UGCGameSystem.GetServerTimeSec()
    --
    gameplayState.RoundFlowInfo.RoundPhase = ERoundPhase.FreezePlayer
    --修改后标记属性为脏，触发网络复制
    gameplayState:RepLazyProperties()
    --
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnGameplayStart)
    --
    UGCTimerUtility.CreateLuaTimer(10, function() self:OnStartGameplay() end)
end

function BP_ServerGameplayComponent:OnStartGameplay()
    GameplayUtils.Print("BP_ServerGameplayComponent.OnStartGameplay")
    local gameplayState = GameplaySystem.GetGameplayStateComponent()
    --
    local curRound = 1
    gameplayState.RoundFlowInfo.RoundPhase = ERoundPhase.RoundStart
    gameplayState.RoundFlowInfo.CurRoundNum = curRound
    gameplayState.RoundFlowInfo.CurRoundStartTime = UGCGameSystem.GetServerTimeSec()
    --修改后标记属性为脏，触发网络复制
    gameplayState:RepLazyProperties()
    --
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnRoundStart,curRound)
end

---@protected
function BP_ServerGameplayComponent:OnAllZombiesBeEliminated()
    local gameplayState = GameplaySystem.GetGameplayStateComponent()
    gameplayState.RoundFlowInfo.RoundPhase = ERoundPhase.RoundEnd
    --修改后标记属性为脏，触发网络复制
    gameplayState:RepLazyProperties()
    --
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnRoundEnd,gameplayState.RoundFlowInfo.CurRoundNum)
    --若干秒后，进入下一回合
    UGCTimerUtility.CreateLuaTimer(10, function() self:EnterNextRound() end)
end

---@private
function BP_ServerGameplayComponent:EnterNextRound()
    local gameplayState = GameplaySystem.GetGameplayStateComponent()
    gameplayState.RoundFlowInfo.RoundPhase = ERoundPhase.RoundStart
    local curRound = gameplayState.RoundFlowInfo.CurRoundNum
    local nextRound = curRound + 1
    gameplayState.RoundFlowInfo.CurRoundNum = nextRound
    gameplayState.RoundFlowInfo.CurRoundStartTime = UGCGameSystem.GetServerTimeSec()
    --修改后标记属性为脏，触发网络复制
    gameplayState:RepLazyProperties()
    --
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnRoundStart,nextRound)
end

---@private
function BP_ServerGameplayComponent:OnAllPlayersDead()
    self:OnSettlement()
end

---@private
function BP_ServerGameplayComponent:OnSettlement()
    local gameplayState = GameplaySystem.GetGameplayStateComponent()
    gameplayState.GameStateInfo.GameState = EGameState.Settlement
    gameplayState:RepLazyProperties()
    --若干秒后，结束游戏
    UGCTimerUtility.CreateLuaTimer(10, function() self:OnGameplayEnd() end)
end

---@private
function BP_ServerGameplayComponent:OnGameplayEnd()
    local gameplayState = GameplaySystem.GetGameplayStateComponent()
    gameplayState.GameStateInfo.GameState = EGameState.GameEnd
    gameplayState:RepLazyProperties()
    --
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnGameplayEnd)
    --触发结算
    --UGCLevelFlowSystem.GameSettle(true)
end

---@private
---@param playerController UGCPlayerController_C
function BP_ServerGameplayComponent:OnPlayerAliveStateChanged(playerController,newState,previousState)
    if newState == EPlayerAliveState.Dead then
        ---@type UGCGameState_C
        local gameState = UGCGameSystem.GetGameState()
        if not gameState:IsPlayerAllDead() then
            GameplaySystem.PlayerSystem:ServerEnableSpectating(playerController,true)
        end
    elseif newState == EPlayerAliveState.Alive then
        GameplaySystem.PlayerSystem:ServerEnableSpectating(playerController,false)
    end
end

return BP_ServerGameplayComponent