---@class BP_Zombie_Base_C:BP_UGC_GenericMobPawn_Base_C
---@field HitBox UCapsuleComponent
---@field bIsSpawnedOutside bool
--Edit Below--
---@type BP_Zombie_Base_C
local BP_Zombie_Base = {
    ---@type APawn
    TargetPlayer = nil,
    ---@type BP_EntryForZombie_Base_C
    TargetEntry = nil,
    CapsuleRadius = 0,
    CapsuleHalfHeight = 0,
    HitBoxHalfHeight = 0,
    HitBoxRadius = 0;
    OccupiedEntryPosSlotIndex = 0,
    IsDead = false,
}

BP_Zombie_Base.m_configID = 0

function BP_Zombie_Base:ReceiveBeginPlay()
    BP_Zombie_Base.SuperClass.ReceiveBeginPlay(self)
    ---
    self.HitBoxRadius = self.HitBox:GetUnscaledCapsuleRadius()
    self.HitBoxHalfHeight = self.HitBox:GetUnscaledCapsuleHalfHeight()
    ---@type UCapsuleComponent
    local capsuleComp = self.RootComponent
    self.CapsuleRadius = capsuleComp:GetUnscaledCapsuleRadius()
    self.CapsuleHalfHeight = capsuleComp:GetUnscaledCapsuleHalfHeight()
    ---
    if self:HasAuthority() then
        local gameState = GameplaySystem.GetGameplayStateComponent()
        local curRound = gameState.RoundFlowInfo.CurRoundNum
        local hp = GameplaySystem.ZombieSpawnSystem:CalcuMaxZombieHealth(curRound,100)
        --初始化血量
        --UGCAttributeSystem.SetGameAttributeValue(self, 'BaseHealth', hp)
        --UGCAttributeSystem.SetGameAttributeValue(self, 'HealthMax', hp)
        --UGCAttributeSystem.SetGameAttributeValue(self, 'UGCGeneralMoveSpeedScale', 2.0)
    end
end

---@public
function BP_Zombie_Base:SetConfigID(configID)
    self.m_configID = configID
end

---@public
function BP_Zombie_Base:GetConfigID()
    return self.m_configID
end

-- function BP_Zombie_Base:ReceiveTick(DeltaTime)
--     BP_Zombie_Base.SuperClass.ReceiveTick(self, DeltaTime)
-- end

-- function BP_Zombie_Base:ReceiveEndPlay()
--     BP_Zombie_Base.SuperClass.ReceiveEndPlay(self) 
-- end

-- function BP_Zombie_Base:GetReplicatedProperties()
--     return
-- end

--function BP_Zombie_Base:GetAvailableClientRPCs()
--    return
--end

-- ---受击前置事件
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- function BP_Zombie_Base:PreTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
     
-- end

---受击后置事件
---生效范围：服务器
---@param Damage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param DamageContext FGameMagnitudeContext  伤害上下文
--function BP_Zombie_Base:PostTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
--
--end

---受击前置伤害修改
---生效范围：服务器
---@param Damage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param DamageContext FGameMagnitudeContext  伤害上下文
---@return float 修改后的伤害值
function BP_Zombie_Base:PreOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
    if DamageCauser:ActorHasTag(GameplaySystem.ActorTags.ActorType.Zombie) then
        --丧尸之间不会造成伤害
        return 0
    end
    return Damage
end

-- ---受击后置伤害修改
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- ---@return float 修改后的伤害值
-- function BP_Zombie_Base:PostOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
--     return Damage
-- end

---角色死亡事件
---生效范围：服务器&客户端
---@param KillingDamage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param DamageEvent FDamageEvent 伤害事件
---@param DamageTypeID int32 伤害类型
function BP_Zombie_Base:BPDie(KillingDamage, EventInstigator, DamageCauser, DamageEvent, DamageTypeID)
    self.IsDead = true
    --死亡后立即关闭胶囊提碰撞
    self:EnableCollision(false)
    --
    local hasAuthority = self:HasAuthority()
    if hasAuthority then
        ---
        UGCGenericCharacterSystem.StopBehavior(self,"Dead")
        UGCGenericCharacterSystem.DisableMovement(self)
        ---
        ---@type AMobAIController
        local aiController = UGCGameSystem.GetControllerByPawn(self)
        if aiController then
            aiController:SwitchCrowdFollowing(false)
        end
        --
        --放弃占用的入口站位
        if self.OccupiedEntryPosSlotIndex > 0 then
            self.TargetEntry:ReturnPositionSlot(self,self.OccupiedEntryPosSlotIndex)
            self.OccupiedEntryPosSlotIndex = 0
        end
    end
    --
    self:OnDead(KillingDamage, EventInstigator, DamageCauser, DamageEvent, DamageTypeID)
    --
    if hasAuthority then
        GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnZombieBeKilled,self)
    end
    --
    if hasAuthority then
        self.TargetPlayer = nil
        self.TargetEntry = nil
    end
end

-- ---状态进入事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 进入的状态
-- function BP_Zombie_Base:OnEnterTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnEnterTagState_BP: ' .. Tag)
-- end

-- ---状态退出事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 退出的状态
-- function BP_Zombie_Base:OnLeaveTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnLeaveTagState_BP: ' .. Tag)
-- end

-- ---状态打断事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 打断的状态
-- function BP_Zombie_Base:OnInterruptTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnInterruptTagState_BP' .. Tag)
-- end

-- ---行为树消息
-- ---生效范围：服务器
-- ---@param NotifyMsg string 消息
-- function BP_Zombie_Base:OnBehaviorNotify_BP(NotifyMsg)
--     ugcprint('OnBehaviorNotify_BP: ' .. NotifyMsg)
-- end

-- ---怪物的目标发生变化事件
-- ---生效范围：服务器&客户端
-- ---@param NewTarget AActor 新目标
-- ---@param OldTarget AActor 旧目标
-- function BP_Zombie_Base:OnTargetChange_BP(NewTarget, OldTarget)
    
-- end

---@protected 角色死亡事件
---生效范围：服务器&客户端
---@param KillingDamage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param DamageEvent FDamageEvent 伤害事件
---@param DamageTypeID int32 伤害类型
function BP_Zombie_Base:OnDead(KillingDamage, EventInstigator, DamageCauser, DamageEvent, DamageTypeID)

end

---@public
---@return boolean
function BP_Zombie_Base:IsDead()
    return self.IsDead
end

---@public
---@param playerPawn UGCPlayerPawn_C|nil
function BP_Zombie_Base:ServerTrackingPlayer(playerPawn)
    local blackboard = UGCGenericCharacterSystem.GetBlackboard(self)
    if not blackboard then
        GameplayUtils.Exception("BP_Zombie_Base.ServerTrackingPlayer: 无法获取黑板组件！追踪玩家失败！")
        return false
    end
    self.TargetPlayer = playerPawn
    if playerPawn then
        blackboard:SetValueAsObject("Target",playerPawn)
    else
        blackboard:ClearValue("Target")
    end
    return true
end

---@public 获取当前正追踪的玩家
---@return UGCPlayerPawn_C
function BP_Zombie_Base:ServerGetCurrentTargetPlayer()
    if not self:HasAuthority() then
        return nil
    end
    if not UE.IsValid(self.TargetPlayer) then
        self.TargetPlayer = nil
        return nil
    end
    return self.TargetPlayer
end

---@public 重新搜索最近的玩家作为目标
---@return UGCPlayerPawn_C
function BP_Zombie_Base:ServerResearchNearstPlayer()
    if not self:HasAuthority() then
        return nil
    end
    self.TargetPlayer = GameplaySystem.MonsterAISystem:ServerFindNearstPlayerAsTarget(self)
    return self.TargetPlayer
end

---@public
function BP_Zombie_Base:SetHitboxScale(scale)
    local s = math.max(0.1,scale)
    self.HitBox:SetCapsuleSize(self.HitBoxRadius * scale,self.HitBoxHalfHeight * scale)
    self.RootComponent:SetCapsuleSize(self.CapsuleRadius * scale,self.CapsuleHalfHeight * scale)
end

---@public
function BP_Zombie_Base:ServerShouldFindEntry(yes)
    local blackboard = UGCGenericCharacterSystem.GetBlackboard(self)
    if blackboard then
        if yes then
            blackboard:SetValueAsBool("bShouldThroughEntry",true)
            UGCTimerUtility.CreateLuaTimer(0.5, function()
                if UE.IsValid(self) then
                    local bb = UGCGenericCharacterSystem.GetBlackboard(self)
                    bb:SetValueAsBool("bShouldThroughEntry",true)
                end
            end)
        else
            blackboard:ClearValue("bShouldThroughEntry")
        end
    end
    self.bIsSpawnedOutside = yes
end

---@public
---@param entryActor
function BP_Zombie_Base:ServerSetTargetEntry(entryActor)
    local blackboard = UGCGenericCharacterSystem.GetBlackboard(self)
    if blackboard then
        if entryActor then
            blackboard:SetValueAsObject("EntryActor", entryActor)
        else
            blackboard:ClearValue("EntryActor")
        end
    end
    self.TargetEntry = entryActor
end

---@public
---@return BP_EntryForZombie_Base_C
function BP_Zombie_Base:ServerGetTargetEntry()
    return self.TargetEntry
end

---@public
function BP_Zombie_Base:SetEntryPositionSlotIndex(index)
    self.OccupiedEntryPosSlotIndex = index
end

---@public
function BP_Zombie_Base:GetEntryPositionSlotIndex()
    return self.OccupiedEntryPosSlotIndex
end

---@public
function BP_Zombie_Base:EnableCollision(enabled)
    ---@type UCapsuleComponent
    local capsule = self.RootComponent
    if enabled then
        capsule:SetCollisionEnabled(1)
    else
        capsule:SetCollisionEnabled(0)
    end
    --
    GameplayUtils.Print("BP_Zombie_Base: ",enabled and "启用" or "禁用"," 碰撞能力！")
end

---@public
function BP_Zombie_Base:EnableMovement(enabled,delayTime)
    if type(delayTime) == "number" and delayTime > 0 then
        UGCTimerUtility.CreateLuaTimer(delayTime, function()
            if not UE.IsValid(self) then
                return
            end
            self:EnableMovement(enabled)
        end, false)
        return
    end
    if enabled then
        UGCGenericCharacterSystem.EnableMovement(self)
    else
        UGCGenericCharacterSystem.DisableMovement(self)
    end
    --
    GameplayUtils.Print("BP_Zombie_Base: ",enabled and "启用" or "禁用"," 移动能力！")
end

---@public
---@return boolean
function BP_Zombie_Base:ModifyNavLocation(location)
    local extent = UGCMathUtility.MakeVector(self.CapsuleRadius,self.CapsuleRadius,self.CapsuleHalfHeight / 2)
    local ok,navLocation = UGCNavigationSystem.ProjectPointToNavigation(self,location,extent)
    if ok then
        self:K2_SetActorLocation(navLocation)
    end
    return ok
end

---@public
function BP_Zombie_Base:MoveToActor(actor)
    ---@type AAIController
    local controller = UGCGameSystem.GetControllerByPawn(self)
    if UE.IsValid(controller) and UE.IsValid(actor) then
        controller:MoveToActor(actor)
    end
end

---@public
function BP_Zombie_Base:MoveToLocation(location)
    ---@type AAIController
    local controller = UGCGameSystem.GetControllerByPawn(self)
    controller:MoveToLocation(location)
end

---@public
---@return boolean
function BP_Zombie_Base:RunBehaviourTree(BTAsset)
    ---@type AAIController
    local controller = UGCGameSystem.GetControllerByPawn(self)
    return controller:RunBehaviorTree(BTAsset)
end

return BP_Zombie_Base
