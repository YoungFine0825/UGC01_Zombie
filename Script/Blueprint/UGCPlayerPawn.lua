---@class UGCPlayerPawn_C:BP_UGCPlayerPawn_C
---@field PlayerLevel int32
--Edit Below--
local UGCPlayerPawn = {}
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
 
function UGCPlayerPawn:ReceiveBeginPlay()

    UGCPlayerPawn.SuperClass.ReceiveBeginPlay(self)
    
    if UGCGameSystem.IsServer() then
        self:InitInServer()
    else
        self:OnRep_CoverAllAvatarMeshInfo()
    end

    if UGCGameData.GetGameModeName(UGCMultiMode.GetModeID()) == UGCGameData.ModeName.Lobby then
        UAEClosure_PlayerStaticFunction.SetCharacterMovementEnable(self, false)
    end
end

function UGCPlayerPawn:InitInServer()
    -- 玩家死亡不生成死亡盒子
    UGCPawnSystem.SkipSpawnDeadTombBox(self, true)

    -- 玩家每次出生或者复活后无敌一段时间
    UGCGenericMessageSystem.ListenGlobalMessage(self, UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnRespawn, self, self.SetIsInvincible_Lua)

    self.DynamicStateEnterHandle:Add(self.ChangeState, self)
end

function UGCPlayerPawn:SetIsInvincible_Lua(_, PlayerKey)
    UGCPawnSystem.SetIsInvincible(UGCGameSystem.GetPlayerPawnByPlayerKey(PlayerKey), true)
    self.InvincibleTimer = UGCTimerUtility.CreateLuaTimer(
        5, function()
            UGCPawnSystem.SetIsInvincible(UGCGameSystem.GetPlayerPawnByPlayerKey(PlayerKey), false)
        end, false
    )
end

function UGCPlayerPawn:ChangeState(CurState)
    ugcprint("[UGCPlayerPawn:ChangeState]")
    -- 获取状态标签
    local DyingTag = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Dying")
    local DeadTag = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Dead")
    
    if not UGCGameSystem.IsServer() then 
        return 
    end
    ugcprint("[UGCPlayerPawn:ChangeState] : IsServer")
    -- 处理倒地状态
    if UGCGameplayTagSystem.IsValidTag(DyingTag) and UGCPersistEffectSystem.HasDynamicState(self, DyingTag) then
        ugcprint("[UGCPlayerPawn:EnterDyingState] Already in Dying State.")
        --弹出复活UI
        local PC = UGCGameSystem.GetPlayerControllerByPlayerPawn(self)
        if PC and self.LastState ~= UGCGameData.AliveState.Dying then
            PC:ChangeState(UGCGameData.AliveState.Dying)
            self.LastState = UGCGameData.AliveState.Dying
        else
            ugcprint("[UGCPlayerPawn:EnterDyingState] PlayerController not found.")
        end
    -- 处理死亡状态
    elseif UGCGameplayTagSystem.IsValidTag(DeadTag) and UGCPersistEffectSystem.HasDynamicState(self, DeadTag) then
        ugcprint("[UGCPlayerPawn:EnterDeadState] Entering Dead State." .. tostring(self))
        -- 处理死亡状态逻辑
        local PC = UGCGameSystem.GetPlayerControllerByPlayerPawn(self)
        if PC and self.LastState ~= UGCGameData.AliveState.Dead then
            -- 可能需要显示游戏结束UI或者重生选项UI
            PC:ChangeState(UGCGameData.AliveState.Dead)
            self.LastState = UGCGameData.AliveState.Dead
        else
            ugcprint("[UGCPlayerPawn:EnterDeadState] PlayerController not found.")
        end
    -- 处理存活状态（既不是倒地也不是死亡）
    elseif not (UGCPersistEffectSystem.HasDynamicState(self, DyingTag) or UGCPersistEffectSystem.HasDynamicState(self, DeadTag)) then
        ugcprint("[UGCPlayerPawn:EnterAliveState] Entering Alive State." .. tostring(self))
        -- 处理存活状态逻辑
        local PC = UGCGameSystem.GetPlayerControllerByPlayerPawn(self)
        if PC and self.LastState ~= UGCGameData.AliveState.Alive then
            -- 可能需要关闭之前的UI或者重置角色状态
            PC:ChangeState(UGCGameData.AliveState.Alive)
            self.LastState = UGCGameData.AliveState.Alive
        else
            ugcprint("[UGCPlayerPawn:EnterAliveState] PlayerController not found.")
        end
    end
end

--[[
function UGCPlayerPawn:ReceiveTick(DeltaTime)
    UGCPlayerPawn.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

-- function UGCPlayerPawn:ReceiveEndPlay()
--     UGCPlayerPawn.SuperClass.ReceiveEndPlay(self) 
-- end

function UGCPlayerPawn:GetReplicatedProperties()
    return { "__SubObjectRepList", "Lazy"}
end

--[[
function UGCPlayerPawn:GetAvailableServerRPCs()
    return
end
--]]

return UGCPlayerPawn