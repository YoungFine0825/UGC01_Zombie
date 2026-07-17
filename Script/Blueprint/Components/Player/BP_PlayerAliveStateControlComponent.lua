---@class BP_PlayerAliveStateControlComponent_C:ActorComponent
---@field BuffDyingProtect UClass
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
    self.m_lastState = EPlayerAliveState.Alive
    --
    if UGCGameSystem.IsServer() then
        self:OnBeginPlayServer()
    end
end


--[[--]]
function BP_PlayerAliveStateControlComponent:ReceiveTick(DeltaTime)
    BP_PlayerAliveStateControlComponent.SuperClass.ReceiveTick(self, DeltaTime)
end


--[[--]]
function BP_PlayerAliveStateControlComponent:ReceiveEndPlay()
    BP_PlayerAliveStateControlComponent.SuperClass.ReceiveEndPlay(self)
    if UGCGameSystem.IsServer() then
        self:OnEndPlayerServer()
    end
    self.Owner = nil
end


function BP_PlayerAliveStateControlComponent:OnBeginPlayServer()
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent.OnBeginPlayServer!")
    self.Owner.DynamicStateEnterHandle:Add(self.OnEnterState, self)
    self.Owner.DynamicStateLeaveHandle:Add(self.OnLeaveState, self)
    self.Owner.DynamicStateInterruptedHandle:Add(self.OnStateInterrupted, self)
end

function BP_PlayerAliveStateControlComponent:OnEndPlayerServer()

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
        --UGCPersistEffectSystem.AddBuffByClass(self.Owner,self.BuffDyingProtect)
    elseif newState == EPlayerAliveState.Alive then
        --UGCPersistEffectSystem.RemoveBuffByClass(self.Owner,self.BuffDyingProtect)
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
    local playerKey = UGCGameSystem.GetPlayerKeyByPlayerPawn(self.Owner)
    return playerKey
end

---@public
---@return UGCPlayerController_C
function BP_PlayerAliveStateControlComponent:GetPlayerController()
    local pc = UGCGameSystem.GetPlayerControllerByPlayerPawn(self.Owner)
    return pc
end

return BP_PlayerAliveStateControlComponent