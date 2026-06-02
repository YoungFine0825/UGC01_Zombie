---@class UGCPlayerPawn_C:BP_UGCPlayerPawn_C
---@field PlayerStaminaComponent PlayerStaminaComponent_C
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

    ugcprint("UGCPlayerPawn:InitInServer "..tostring(self.PlayerName))

    --监听受伤
    UGCGenericMessageSystem.ListenGlobalMessage(self,"UGC.PlayerPawn.PostTakeDamage",self,self.LuaPostTakeDamage)
    local RecoverBuffClass = self:TryLoadRecoverHPBuffClass()
    if RecoverBuffClass then
        ugcprint("UGCPlayerPawn:InitInServer "..tostring(self.PlayerName).." Load RecoverBuff Class Successful!")
    else
        ugcprint("UGCPlayerPawn:InitInServer "..tostring(self.PlayerName).." Load RecoverBuff Class Failed!")
    end
    self.RecoverBuffClass = RecoverBuffClass
end

function UGCPlayerPawn:ReceiveEndPlay()
    UGCPlayerPawn.SuperClass.ReceiveEndPlay(self)
    UGCGenericMessageSystem.UnListenMessage(self, "UGC.PlayerPawn.PostTakeDamage")
    UGCTimerUtility.RemoveLuaTimerByName("RecoverBuffTimer")
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

--判断武器伤害类型
---生效范围：服务器
---@param VictimPlayer ASTExtraBaseCharacter|AUGCMobCharacter @造成伤害的玩家角色|怪物
---@param DamageCauserActor AActor @伤害来源
---@param EventInstigator Controller @伤害来源的玩家控制器
---@param Damage float @伤害值
---@param DamageContext FGameMagnitudeContext @伤害事件上下文
function UGCPlayerPawn:LuaPostTakeDamage(VictimPlayer, DamageCauserActor, EventInstigator, Damage, DamageContext)
    ugcprint("UGCPlayerPawn:LuaPostTakeDamage "..tostring(self.PlayerName))

    if EventInstigator then
        local PlayerKey = EventInstigator.PlayerKey
        if PlayerKey then
            ugcprint("UGCPlayerPawn:LuaPostTakeDamage "..tostring(self.PlayerName).." DamagePlayerKey="..tostring(PlayerKey))
           self.PlayerState.DamagePlayerKeys[PlayerKey] = true 
        end
    end

    --先清理Timer
    UGCTimerUtility.RemoveLuaTimerByName("RecoverBuffTimer")

    if not self.RecoverBuffClass then
        local RecoverBuffClass = self:TryLoadRecoverHPBuffClass()
        if not RecoverBuffClass then
            ugcprint("UGCPlayerPawn:LuaPostTakeDamage: Cannot load RecoverHPBuff class !")
            return
        end
    end

    --清理Buff
    UGCPersistEffectSystem.RemoveBuffByClass(self,self.RecoverBuffClass)

    --受伤若干秒后添加回血Buff
    UGCTimerUtility.CreateLuaTimer(2,function()
        ugcprint("UGCPlayerPawn:LuaPostTakeDamage "..tostring(self.PlayerName).." Add RecoverBuff")
        UGCPersistEffectSystem.AddBuffByClass(self,self.RecoverBuffClass)    
    end,false,"RecoverBuffTimer")
end

function UGCPlayerPawn:TryLoadRecoverHPBuffClass()
    local RecoverBuffPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Buffs/Buff_RecoverHP.Buff_RecoverHP_C')
    local RecoverBuffClass = UE.LoadClass(RecoverBuffPath)
    self.RecoverBuffClass = RecoverBuffClass
    return RecoverBuffClass
end

return UGCPlayerPawn