---@class BP_PlayerAliveStateControlComponent_C:ActorComponent
--Edit Below--

--- 玩家生命状态控制组件
---@type BP_PlayerAliveStateControlComponent_C
local BP_PlayerAliveStateControlComponent = {}

---@type UGCPlayerPawn_C
BP_PlayerAliveStateControlComponent.Owner = nil

BP_PlayerAliveStateControlComponent.m_lastState = 0

--[[--]]
function BP_PlayerAliveStateControlComponent:ReceiveBeginPlay()
    BP_PlayerAliveStateControlComponent.SuperClass.ReceiveBeginPlay(self)
    --
    ---@type UGCPlayerPawn_C
    local playerPawn = UGCActorComponentUtility.GetOwner(self)
    self.Owner = playerPawn
    ---@type UGCPlayerController_C
    local playerController = UGCGameSystem.GetPlayerControllerByPlayerPawn(playerPawn)
    self.m_playerController = playerController
    if playerController then
        self.m_playerKey = UGCGameSystem.GetPlayerKeyByPlayerController(playerController)
    else
        self.m_playerKey = UGCGameSystem.GetPlayerKeyByPlayerPawn(playerPawn)
    end
    self.m_lastState = EPlayerAliveState.Alive
    self.m_isStartSelfRescueCountDown = false
    self.m_selfRescueCompleteTime = 0
    self.m_selfRescueRemainingTime = 0
    self.m_isServer = UGCGameSystem.IsServer()
    --
    if self.m_isServer then
        self:OnBeginPlayServer()
    end
end


--[[--]]
function BP_PlayerAliveStateControlComponent:ReceiveTick(DeltaTime)
    BP_PlayerAliveStateControlComponent.SuperClass.ReceiveTick(self, DeltaTime)
    if self.m_isServer then
        self:OnServerTick()
    end
end


--[[--]]
function BP_PlayerAliveStateControlComponent:ReceiveEndPlay()
    BP_PlayerAliveStateControlComponent.SuperClass.ReceiveEndPlay(self)
    if self.m_isServer then
        self:OnEndPlayerServer()
    end
    self.Owner = nil
    self.m_playerController = nil
end

function BP_PlayerAliveStateControlComponent:GetReplicatedProperties()
    return {"m_selfRescueRemainingTime","Lzay"},{"m_isStartSelfRescueCountDown","Lzay"}
end

function BP_PlayerAliveStateControlComponent:GetAvailableClientRPCs()
    return "RPC_Client_StartSelfRescue","RPC_Client_SelfRescueEnd"
end

function BP_PlayerAliveStateControlComponent:OnBeginPlayServer()
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent.OnBeginPlayServer!")
    self.Owner.DynamicStateEnterHandle:Add(self.OnEnterState, self)
    self.Owner.DynamicStateLeaveHandle:Add(self.OnLeaveState, self)
    self.Owner.DynamicStateInterruptedHandle:Add(self.OnStateInterrupted, self)
end

---@private
function BP_PlayerAliveStateControlComponent:OnServerTick()
    if self.m_isStartSelfRescueCountDown then
        local curTime = UGCGameSystem.GetServerTimeSec()
        local remainingTime = math.max(0,self.m_selfRescueCompleteTime - curTime)
        --
        self.m_selfRescueRemainingTime = remainingTime
        UnrealNetwork.RepLazyProperty(self,"m_selfRescueRemainingTime")
        --
        if remainingTime <= 0 then
            self:ServerSelfRescueCompleted()
        end
    end
end

function BP_PlayerAliveStateControlComponent:OnEndPlayerServer()
    self:ServerInterruptSelfRescue()
end

---@private
function BP_PlayerAliveStateControlComponent:OnEnterState(CurState)
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent.OnEnterState: Player ",self:GetPlayerKey()," enter state",tostring(CurState.TagName))
    if not UGCGameSystem.IsServer() then
        return
    end
    -- 获取状态标签
    local DyingTag = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Dying")
    local DeadTag = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Dead")
    -- 处理倒地状态
    if UGCGameplayTagSystem.IsValidTag(DyingTag) and self:HasDynamicState(DyingTag) then
        self:_ServerTryChangePlayerAliveState(EPlayerAliveState.Dying)
    -- 处理死亡状态
    elseif UGCGameplayTagSystem.IsValidTag(DeadTag) and self:HasDynamicState(DeadTag) then
        self:_ServerTryChangePlayerAliveState(EPlayerAliveState.Dead)
    -- 处理存活状态（既不是倒地也不是死亡）
    elseif not ( self:HasDynamicState(DyingTag) or self:HasDynamicState(DeadTag) ) then
        self:_ServerTryChangePlayerAliveState(EPlayerAliveState.Alive)
    end
end

---@private
---@param state FGameplayTag
function BP_PlayerAliveStateControlComponent:OnLeaveState(state)
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent.OnLeaveState: Player ",self:GetPlayerKey()," leave state ",tostring(state.TagName))
end

---@private
function BP_PlayerAliveStateControlComponent:OnStateInterrupted(InterruptedState)
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent.OnLeaveState: Player ", self:GetPlayerKey(), " state ",tostring(InterruptedState.TagName), " be interrupted !")
end

---@private
function BP_PlayerAliveStateControlComponent:_ServerTryChangePlayerAliveState(newState)
    local playerKey = self:GetPlayerKey()
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent._ServerTryChangePlayerAliveState: 玩家 ",playerKey," 尝试切换状态至 ",newState)
    if self.m_lastState ~= newState then
        -- 可能需要关闭之前的UI或者重置角色状态
        self:_ServerChangePlayerAliveState(playerKey,newState)
    end
    return true
end

---@private
function BP_PlayerAliveStateControlComponent:_ServerChangePlayerAliveState(playerKey,newState)

    local lastState = self.m_lastState
    if newState == EPlayerAliveState.Dying then

    elseif newState == EPlayerAliveState.Alive then
        self:ServerInterruptSelfRescue()
    end
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent._ServerChangePlayerAliveState: 玩家 ",playerKey," 切换状态至 ",newState," 成功！")
    self.m_lastState = newState

    ---@type UGCPlayerController_C
    local playerController = self:GetPlayerController()
    playerController:ServerChangeState(newState)
end

---@public
function BP_PlayerAliveStateControlComponent:HasDynamicState(tag)
    return UGCPersistEffectSystem.HasDynamicState(self.Owner, tag)
end

---@public
---@return Gameplay.EPlayerAliveState
function BP_PlayerAliveStateControlComponent:GetAliveState()
    return self.m_lastState
end

---@public
function BP_PlayerAliveStateControlComponent:GetPlayerKey()
    if self.m_playerKey <= 0 then
        self.m_playerKey = UGCGameSystem.GetPlayerKeyByPlayerPawn(self.Owner)
    end
    return self.m_playerKey
end

---@public
---@return UGCPlayerController_C
function BP_PlayerAliveStateControlComponent:GetPlayerController()
    if not self.m_playerController then
        self.m_playerController = UGCGameSystem.GetPlayerControllerByPlayerKey(self:GetPlayerKey())
    end
    if not self.m_playerController then
        self.m_playerController = UGCGameSystem.GetPlayerControllerByPlayerPawn(self.Owner)
    end
    return self.m_playerController
end

---@protected
function BP_PlayerAliveStateControlComponent:ServerStartSelfRescue()
    local delay = 10
    self.m_selfRescueCompleteTime = UGCGameSystem.GetServerTimeSec() + delay
    self.m_selfRescueRemainingTime = 0
    self.m_isStartSelfRescueCountDown = true
    UnrealNetwork.RepLazyProperty(self,"m_isStartSelfRescueCountDown")
    GameplaySystem.PlayerSystem:UseSelfRescueTimes(self:GetPlayerKey(),1)
    --
    UnrealNetwork.CallUnrealRPC(
            self:GetPlayerController(),
            self,
            "RPC_Client_StartSelfRescue",
            self.m_selfRescueCompleteTime
    )
    --
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent.ServerStartSelfRescue")
end

---@private
function BP_PlayerAliveStateControlComponent:RPC_Client_StartSelfRescue(completeTime)
    local localPlayerKey = UGCGameSystem.GetLocalPlayerKey()
    if self.m_playerKey ~= localPlayerKey then
        return
    end
    --显示复活倒计时界面
    local playerController = self:GetPlayerController()
    playerController:OpenRespawnUI()
    --
    local remainingTime = math.max(0,completeTime - UGCGameSystem.GetServerTimeSec())
    UGCTimerUtility.CreateLuaTimer(remainingTime,function()
        BreakthroughManager:CloseRespawnUI()
    end,false)
    --
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent.RPC_Client_StartSelfRescue")
end

function BP_PlayerAliveStateControlComponent:OnRep_m_selfRescueRemainingTime()
    local localPlayerKey = UGCGameSystem.GetLocalPlayerKey()
    if self.m_playerKey ~= localPlayerKey then
        return
    end
    local remainingTime = self.m_selfRescueRemainingTime
    BreakthroughManager:RefreshRespawnUICountDown(remainingTime)

end

---@protected
function BP_PlayerAliveStateControlComponent:ServerSelfRescueCompleted()
    --手动复活
    GameplaySystem.PlayerSystem:ServerRespawnPlayer(self:GetPlayerKey())
    --
    self.m_isStartSelfRescueCountDown = false
    UnrealNetwork.RepLazyProperty(self,"m_isStartSelfRescueCountDown")
    self.m_selfRescueCompleteTime = 0
    --
    UnrealNetwork.CallUnrealRPC(
            self:GetPlayerController(),
            self,
            "RPC_Client_SelfRescueEnd",
            self.m_selfRescueCompleteTime
    )
    --
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent.ServerSelfRescueCompleted")
end

---@private
function BP_PlayerAliveStateControlComponent:RPC_Client_SelfRescueEnd()
    local localPlayerKey = UGCGameSystem.GetLocalPlayerKey()
    if self.m_playerKey ~= localPlayerKey then
        return
    end
    BreakthroughManager:CloseRespawnUI()
    --
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent.RPC_Client_SelfRescueEnd")
end

---@protected
function BP_PlayerAliveStateControlComponent:ServerInterruptSelfRescue()
    self.m_isStartSelfRescueCountDown = false
    self.m_selfRescueCompleteTime = 0
    UnrealNetwork.RepLazyProperty(self,"m_isStartSelfRescueCountDown")
end

---@public 是否正在自救
---@return boolean
function BP_PlayerAliveStateControlComponent:IsSelfRescuing()
    return self.m_isStartSelfRescueCountDown
end

---@protected
function BP_PlayerAliveStateControlComponent:OnRep_m_isStartSelfRescueCountDown()

end

return BP_PlayerAliveStateControlComponent