---@class BP_EntryForZombie_Base_C:BP_UGC_DamagableActor_C
---@field BoxBlock UBoxComponent
---@field Plank6 UStaticMeshComponent
---@field Plank5 UStaticMeshComponent
---@field Plank4 UStaticMeshComponent
---@field Plank3 UStaticMeshComponent
---@field Plank2 UStaticMeshComponent
---@field Plank1 UStaticMeshComponent
---@field HitBox UBoxComponent
---@field PosSlot3 USecondCollisionCapsuleComponent
---@field PosSlot2 USecondCollisionCapsuleComponent
---@field PosSlot1 USecondCollisionCapsuleComponent
---@field Spline1 USplineComponent
---@field WallMesh UStaticMeshComponent
---@field bIsRepairing bool
---@field MaxHitCount int32
---@field LeftHitCount int32
---@field bIsBroken bool
---@field bDefaultActive bool
--Edit Below--
---@type BP_EntryForZombie_Base_C:BP_UGC_DamagableActor_C
local BP_EntryForZombie_Base = {
    IsDead = false,
    ---@type USecondCollisionCapsuleComponent[]
    AllPositionSlots = {},
    ---@type number[]
    FreePositionSlotsIndex = {},
    ---@type number[]
    OccupiedPositionsSlotsIndex = {},
    ---@type table<number,BP_Zombie_Base_C>
    PositionSlot2ZombiePawn = {},
    ---@type table<BP_Zombie_Base_C,number>
    ZombiePawn2PositionSlot = {},

    CurPassingOrderNum = 0,
}

---@type BP_Zombie_Base_C[]
BP_EntryForZombie_Base.m_passingQueue = {}

function BP_EntryForZombie_Base:ReceiveBeginPlay()
    BP_EntryForZombie_Base.SuperClass.ReceiveBeginPlay(self)
    --
    self.m_isActived = self.bDefaultActive
    --
    self.AllPositionSlots = {
        self.PosSlot1,
        self.PosSlot2,
        self.PosSlot3,
    }
    self.FreePositionSlotsIndex = {}
    for i = 1,#self.AllPositionSlots do
        table.insert(self.FreePositionSlotsIndex,i)
    end
    self.OccupiedPositionsSlotsIndex = {}
    self.PositionSlot2ZombiePawn = {}
    --
    --self.LeftHitCount = self.MaxHitCount
    --self.bIsBroken = false
    --
    self:RegisterToLevelActor()
    self:UpdatePlanksVisible()
end


function BP_EntryForZombie_Base:ReceiveEndPlay()
    GameplayUtils.Exception(string.format(
        "[Entry ReceiveEndPlay] 被销毁 | Entry=%s | bIsBroken=%s | LeftHitCount=%d/%d",
        tostring(self), tostring(self.bIsBroken), self.LeftHitCount or 0, self.MaxHitCount or 0
    ))
    self.AllPositionSlots = {}
    self.FreePositionSlotsIndex = {}
    self.OccupiedPositionsSlotsIndex = {}
    self.PositionSlot2ZombiePawn = {}
    self:UnregisterFromLevelActor()
end

function BP_EntryForZombie_Base:GetReplicatedProperties()
    return {"m_isActived","Lazy"}
end

---@public
---@return boolean
function BP_EntryForZombie_Base:IsActive()
    return self.m_isActived
end

---@private
function BP_EntryForZombie_Base:OnRep_m_isActived()
    GameplayUtils.Print("BP_EntryForZombie_Base.OnRep_m_isActived: 丧尸入口 ",UGCObjectUtility.GetObjectName(self)," 激活！")
end

---@public 激活入口
function BP_EntryForZombie_Base:ServerActivate()
    if not UGCGameSystem.IsServer() then
        return
    end
    self.m_isActived = true
    UnrealNetwork.RepLazyProperty(self,"m_isActived")
    GameplayUtils.Print("BP_EntryForZombie_Base.ServerActivate: 丧尸入口 ",UGCObjectUtility.GetObjectName(self)," 激活！")
end

---受击前置事件
---生效范围：服务器
---@param Damage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param DamageContext FGameMagnitudeContext  伤害上下文
function BP_EntryForZombie_Base:PreTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
    -- local Type = UGCAttributeSystem.GetDamageTypeFromContext(DamageContext)
end

---受击前置伤害修改
---生效范围：服务器
---@param Damage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param DamageContext FGameMagnitudeContext  伤害上下文
---@return float 修改后的伤害值
function BP_EntryForZombie_Base:PreOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
    if not DamageCauser:ActorHasTag(GameplaySystem.ActorTags.ActorType.Zombie) then
        return 0 --入口只能被丧尸伤害
    end
    if self.LeftHitCount <= 0 then--LeftHitCount等于0代表已死亡（假死）
        return 0
    end
    self.LeftHitCount = self.LeftHitCount - 1
    return 0
end

---角色死亡事件
---生效范围：服务器&客户端
---@param Damage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param FDamageEvent DamageEvent 伤害事件
---@param DamageTypeID int32 伤害类型
function BP_EntryForZombie_Base:BPDie(KillingDamage, EventInstigator, DamageCauser, DamageEvent, DamageTypeID)
    GameplayUtils.Exception(string.format(
        "[Entry BPDie] Damage=%.1f | Causer=%s | DamageTypeID=%d | bIsBroken=%s | LeftHitCount=%d",
        KillingDamage or 0,
        DamageCauser and GameplayUtils.GetUEObjClassName(DamageCauser) or "nil",
        DamageTypeID or -1,
        tostring(self.bIsBroken),
        self.LeftHitCount or 0
    ))
end

---受击后置事件
---生效范围：服务器
---@param Damage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param DamageContext FGameMagnitudeContext  伤害上下文
function BP_EntryForZombie_Base:PostTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
    if not self.bIsBroken and self.LeftHitCount <= 0  and self:HasAuthority() then
        self.LeftHitCount = 0
        self:OnDead()
    end
end

---@protected
function BP_EntryForZombie_Base:OnDead()
    GameplayUtils.Exception(string.format(
        "[Entry Broken] bIsBroken=%s | LeftHitCount=%d",
        tostring(self.bIsBroken), self.LeftHitCount or 0
    ))
    self.bIsBroken = true
    -- self.WallMesh:SetVisibility(false,true)
    self.HitBox:SetVisibility(false)
    self.HitBox:SetCollisionEnabled(0)
    GameplayUtils.Print("BP_EntryForZombie_Base.OnDead: 被摧毁！！ ")
end

function BP_EntryForZombie_Base:OnRep_bIsRepairing()

end

---@private
function BP_EntryForZombie_Base:OnRep_LeftHitCount()
    self:UpdatePlanksVisible()
end

function BP_EntryForZombie_Base:OnRep_bIsBroken()
    self:UpdatePlanksVisible()
end

function BP_EntryForZombie_Base:RegisterToLevelActor()
    if UGCGameSystem.IsServer() then
        if GameplaySystem.MonsterAISystem:RegisterZombieEntry(self) then
            --GameplayUtils.Print("BP_EntryForZombie_Base.RegisterToLevelActor: 注册入口成功！")
        else
            GameplayUtils.Exception("BP_EntryForZombie_Base.RegisterToLevelActor: 注册入口失败！")
        end
    end    
end

function BP_EntryForZombie_Base:UnregisterFromLevelActor()
    if UGCGameSystem.IsServer() then
        GameplaySystem.MonsterAISystem:UnregisterZombieEntry(self)
    end
end

---@public
---@return number
function BP_EntryForZombie_Base:IsBroken()
    return self.LeftHitCount <= 0
end

---@public
---@return USplineComponent
function BP_EntryForZombie_Base:GetSpline()
    return self.Spline1
end

---@public
---@param zombiePawn BP_Zombie_Base_C
---@return number,FVector
function BP_EntryForZombie_Base:RequestPositionSlot(zombiePawn)
    local queue = self.m_passingQueue
    local queueLength = #queue
    for i = 1,#queue do
        if queue[i] == zombiePawn then
            GameplayUtils.Print("BP_EntryForZombie_Base:RequestPositionSlot: 已位于队列位置 ",i)
            local worldPos = self.AllPositionSlots[i]:K2_GetComponentLocation()
            return i,worldPos--已在队列中
        end
    end
    if queueLength >= #self.AllPositionSlots then
        GameplayUtils.Print("BP_EntryForZombie_Base:RequestPositionSlot: 无剩余空位！ ")
        return 0--队列已满
    end
    table.insert(queue,zombiePawn)
    self:RefreshQueueAssignments()
    local slotIndex = self.ZombiePawn2PositionSlot[zombiePawn] or 0
    local worldPos = nil
    if slotIndex > 0 then
        worldPos = self.AllPositionSlots[slotIndex]:K2_GetComponentLocation()
    end
    return slotIndex,worldPos
end

---@public
---@param zombiePawn BP_Zombie_Base_C
---@param posSlotIndex number
---@return boolean
function BP_EntryForZombie_Base:ReturnPositionSlot(zombiePawn,posSlotIndex)
    if not UE.IsValid(zombiePawn) then
        GameplayUtils.Print("BP_EntryForZombie_Base:ReturnPositionSlot: 无效参数！ ")
        return false
    end
    local queueIdx = 0
    for i = #self.m_passingQueue,1,-1 do
        if self.m_passingQueue[i] == zombiePawn then
            queueIdx = i
            table.remove(self.m_passingQueue,i)
            break
        end
    end
    if queueIdx <= 0 then
        GameplayUtils.Print("BP_EntryForZombie_Base:ReturnPositionSlot: 丧尸不在队列中！ ")
        return false
    end
    self:RefreshQueueAssignments()
    return true
end

---@private
function BP_EntryForZombie_Base:RefreshQueueAssignments()
    self.PositionSlot2ZombiePawn = {}
    self.ZombiePawn2PositionSlot = {}
    self.OccupiedPositionsSlotsIndex = {}
    self.FreePositionSlotsIndex = {}
    --
    local queue = self.m_passingQueue
    for i = 1,#queue do
        local posSlotIndex = i
        local zombiePawn = queue[i]
        self.PositionSlot2ZombiePawn[posSlotIndex] = zombiePawn
        self.ZombiePawn2PositionSlot[zombiePawn] = posSlotIndex
        table.insert(self.OccupiedPositionsSlotsIndex,posSlotIndex)
    end
    for i = 1,#self.AllPositionSlots do
        local slotIndex = i
        if not self.PositionSlot2ZombiePawn[slotIndex] then
            table.insert(self.FreePositionSlotsIndex,slotIndex)
        end
    end
end

---@public
---@param zombiePawn BP_Zombie_Base_C
---@return number
function BP_EntryForZombie_Base:GetRequestedPositionSlot(zombiePawn)
    local slotIndex = self.ZombiePawn2PositionSlot[zombiePawn] or 0
    return slotIndex
end

---@public
---@return boolean
function BP_EntryForZombie_Base:IsPositionSlotAvailable(slotIndex)
    for i = 1,#self.FreePositionSlotsIndex do
        if self.FreePositionSlotsIndex[i] == slotIndex then
            return true
        end
    end
    return false
end

---@public
---@return boolean
function BP_EntryForZombie_Base:HaveFreePositionSlots()
    return #self.FreePositionSlotsIndex > 0
end

---@public
---@return boolean
function BP_EntryForZombie_Base:GetFreePositionSlotCount()
    return #self.FreePositionSlotsIndex
end


---@private
function BP_EntryForZombie_Base:UpdatePlanksVisible()
    local health = self.LeftHitCount / self.MaxHitCount
    local planksNum = 6
    local visiblePlanksNum = math.floor(health * planksNum)
    for i = 1,planksNum do
        local plankMesh = self["Plank"..i]
        if plankMesh then
            plankMesh:SetVisibility(i > (planksNum - visiblePlanksNum))
        end
    end
end

return BP_EntryForZombie_Base
