---@class BP_TeamBuffDropManager_C:AActor
---@field DefaultSceneRoot USceneComponent
---@field TeamBuffs ULuaArrayHelper<FStruct_TeamBuffDropInfo__pf496293838>
---@field BaseDropChance float
---@field DropCooldown float
---@field MaxAliveDropCount int32
---@field MinRoundToDrop int32
---@field bOnlyDropDuringGameplay bool
---@field SpawnRandomRadius float
---@field LifeTime float
---@field bAvoidRepeatLastDrop bool
--Edit Below--
---@type BP_TeamBuffDropManager_C
local BP_TeamBuffDropManager = {}

-- ==================== 运行时成员 ====================
-- m_lastDropTime: number        上次成功掉落的时间戳
-- m_activeDrops: table          当前场上的掉落物列表 [{actor, spawnTime, buffClass}]
-- m_lastDroppedClass: string    上次掉落的BuffClass路径(用于避免重复)
-- m_curRoundNum: number         当前回合数
-- m_isGaming: boolean           是否处于正式战斗阶段

---@protected
function BP_TeamBuffDropManager:ReceiveBeginPlay()
    BP_TeamBuffDropManager.SuperClass.ReceiveBeginPlay(self)

    -- 初始化运行时状态
    self.m_lastDropTime = 0
    self.m_activeDrops = {}
    self.m_lastDroppedClass = ""
    self.m_curRoundNum = 0
    self.m_isGaming = false
    self.m_cleanupTimer = 0

    -- 仅服务端处理掉落逻辑
    if not UGCGameSystem.IsServer() then
        return
    end

    -- 注册事件监听
    GameplayUtils.Print("[TeamBuffDrop] 注册事件监听 (Server=", UGCGameSystem.IsServer(), ")")
    GameplaySystem.EventSystem:Listen(GameplayEvents.Server.OnZombieBeKilled, self, self.OnZombieBeKilled)
    GameplaySystem.EventSystem:Listen(GameplayEvents.Server.OnGameplayStart, self, self.OnGameplayStart)
    GameplaySystem.EventSystem:Listen(GameplayEvents.Server.OnRoundStart, self, self.OnRoundStart)
    GameplaySystem.EventSystem:Listen(GameplayEvents.Server.OnRoundEnd, self, self.OnRoundEnd)
    GameplaySystem.EventSystem:Listen(GameplayEvents.Server.OnGameplayEnd, self, self.OnGameplayEnd)
    GameplaySystem.EventSystem:Listen(GameplayEvents.Server.OnTeamBuffPicked, self, self.OnTeamBuffPicked)

    GameplayUtils.Print("[TeamBuffDrop] 初始化完成，等待僵尸击杀事件")
end

---@protected 定期清理已过期/被销毁的掉落物记录
function BP_TeamBuffDropManager:ReceiveTick(DeltaTime)
    BP_TeamBuffDropManager.SuperClass.ReceiveTick(self, DeltaTime)
    if not UGCGameSystem.IsServer() then
        return
    end
    self.m_cleanupTimer = self.m_cleanupTimer + DeltaTime
    if self.m_cleanupTimer >= 2.0 then
        self.m_cleanupTimer = 0
        self:CleanInvalidDrops()
    end
end

---@protected
function BP_TeamBuffDropManager:ReceiveEndPlay()
    -- 取消事件监听
    if UGCGameSystem.IsServer() then
        GameplaySystem.EventSystem:Unlisten(GameplayEvents.Server.OnZombieBeKilled, self)
        GameplaySystem.EventSystem:Unlisten(GameplayEvents.Server.OnGameplayStart, self)
        GameplaySystem.EventSystem:Unlisten(GameplayEvents.Server.OnRoundStart, self)
        GameplaySystem.EventSystem:Unlisten(GameplayEvents.Server.OnRoundEnd, self)
        GameplaySystem.EventSystem:Unlisten(GameplayEvents.Server.OnGameplayEnd, self)
        GameplaySystem.EventSystem:Unlisten(GameplayEvents.Server.OnTeamBuffPicked, self)
    end

    -- 清理活跃掉落物引用
    self.m_activeDrops = {}

    BP_TeamBuffDropManager.SuperClass.ReceiveEndPlay(self)
end

-- ==================== 事件处理 ====================

---@protected 游戏开始
function BP_TeamBuffDropManager:OnGameplayStart()
    self.m_isGaming = true
    self.m_curRoundNum = 0
    GameplayUtils.Print("[TeamBuffDrop] OnGameplayStart: m_isGaming=true")
end

---@protected 回合开始
---@param roundNum number
function BP_TeamBuffDropManager:OnRoundStart(roundNum)
    self.m_curRoundNum = roundNum or 0
    GameplayUtils.Print("[TeamBuffDrop] OnRoundStart: m_curRoundNum=", self.m_curRoundNum)
end

---@protected 回合结束
function BP_TeamBuffDropManager:OnRoundEnd()
    GameplayUtils.Print("[TeamBuffDrop] OnRoundEnd: m_curRoundNum=", self.m_curRoundNum)
end

---@protected 游戏结束
function BP_TeamBuffDropManager:OnGameplayEnd()
    self.m_isGaming = false
    self.m_curRoundNum = 0
    self.m_activeDrops = {}
    self.m_lastDroppedClass = ""
    GameplayUtils.Print("[TeamBuffDrop] OnGameplayEnd: 状态已清理")
end

---@protected 丧尸被击杀
---@param zombiePawn BP_Zombie_Base_C 被击杀的丧尸
function BP_TeamBuffDropManager:OnZombieBeKilled(zombiePawn)
    if not zombiePawn then
        GameplayUtils.Print("[TeamBuffDrop] OnZombieBeKilled: zombiePawn is nil, skip")
        return
    end

    GameplayUtils.Print("[TeamBuffDrop] OnZombieBeKilled: 触发，检查掉落条件...")

    if zombiePawn.bIsSpawnedOutside then
        GameplayUtils.Print("[TeamBuffDrop] zombiePawn.bIsSpawnedOutside=true，丧尸出生在游戏区域外，不能生成！")
       return
    end

    -- 1. 检查是否允许掉落（内部含多层判定）
    if not self:CanDrop() then
        GameplayUtils.Print("[TeamBuffDrop] CanDrop=false，跳过本次掉落")
        return
    end

    -- 2. 概率判定：BaseDropChance=0.15 → 15%概率掉落
    local roll = math.random()
    if roll > self.BaseDropChance then
        GameplayUtils.Print("[TeamBuffDrop] 概率未命中 roll=", roll, " > BaseDropChance=", self.BaseDropChance)
        return
    end

    -- 3. 从掉落池按权重随机选一个Buff
    local buffClass = self:PickRandomBuff()
    if not buffClass then
        GameplayUtils.Print("[TeamBuffDrop] PickRandomBuff 返回 nil，掉落池可能为空")
        return
    end
    GameplayUtils.Print("[TeamBuffDrop] 选中Buff: ", buffClass)

    -- 4. 计算生成位置
    local zombieLoc = zombiePawn:K2_GetActorLocation()
    local spawnLoc = self:CalcSpawnLocation(zombieLoc)

    -- 5. 生成掉落物
    local dropActor = self:SpawnDrop(buffClass, spawnLoc)
    if not dropActor then
        GameplayUtils.Exception("[TeamBuffDrop] SpawnDrop 失败！buffClass=", buffClass)
        return
    end

    -- 6. 记录状态
    self.m_lastDropTime = UGCGameSystem.GetServerTimeSec()
    self.m_lastDroppedClass = buffClass
    table.insert(self.m_activeDrops, {
        actor = dropActor,
        spawnTime = UGCGameSystem.GetServerTimeSec(),
        buffClass = buffClass,
    })

    GameplayUtils.Print(
        "BP_TeamBuffDropManager: 成功掉落 Buff，位置(",
        spawnLoc.X, ",", spawnLoc.Y, ",", spawnLoc.Z, ")"
    )
end

-- ==================== 掉落判定 ====================

---@private 检查是否允许掉落
---@return boolean
function BP_TeamBuffDropManager:CanDrop()
    -- 检查掉落池是否为空
    if not self.TeamBuffs or self.TeamBuffs:Num() <= 0 then
        GameplayUtils.Print("[TeamBuffDrop] CanDrop: 掉落池为空")
        return false
    end

    -- 检查是否仅在战斗阶段掉落
    if self.bOnlyDropDuringGameplay and not self.m_isGaming then
        GameplayUtils.Print("[TeamBuffDrop] CanDrop: 非战斗阶段 (m_isGaming=", self.m_isGaming, ")")
        return false
    end

    -- 检查回合数是否达到最低要求
    if self.m_curRoundNum < self.MinRoundToDrop then
        GameplayUtils.Print("[TeamBuffDrop] CanDrop: 回合不足 m_curRoundNum=", self.m_curRoundNum, " < MinRoundToDrop=", self.MinRoundToDrop)
        return false
    end

    -- 检查场上掉落物数量是否已达上限
    --self:CleanInvalidDrops()
    if #self.m_activeDrops >= self.MaxAliveDropCount then
        GameplayUtils.Print("[TeamBuffDrop] CanDrop: 场上掉落物已满 count=", #self.m_activeDrops)
        return false
    end

    -- 检查冷却时间
    local curTime = UGCGameSystem.GetServerTimeSec()
    if curTime - self.m_lastDropTime < self.DropCooldown then
        GameplayUtils.Print("[TeamBuffDrop] CanDrop: 冷却中 elapsed=", curTime - self.m_lastDropTime, " < DropCooldown=", self.DropCooldown)
        return false
    end

    GameplayUtils.Print("[TeamBuffDrop] CanDrop=true")
    return true
end

-- ==================== 掉落池随机 ====================

---@private 从掉落池中按权重随机选择一个Buff
---@return string|nil BuffClass 路径
function BP_TeamBuffDropManager:PickRandomBuff()
    local pool = self.TeamBuffs
    if not pool or pool:Num() <= 0 then
        return nil
    end

    -- 计算总权重
    local totalWeight = 0
    for i = 1, #pool do
        totalWeight = totalWeight + (pool[i].Weight or 1)
    end

    -- 如果开启了避免重复，且池子中有多个选项，尝试排除上次掉落的
    local candidates = pool
    if self.bAvoidRepeatLastDrop and #pool > 1 and self.m_lastDroppedClass ~= "" then
        candidates = {}
        for i = 1, #pool do
            if pool[i].TeamBuffClass ~= self.m_lastDroppedClass then
                table.insert(candidates, pool[i])
            end
        end
        -- 如果过滤后为空（极端情况），回退到全池
        if #candidates <= 0 then
            candidates = pool
        end
    end

    -- 重新计算候选池总权重
    local candTotalWeight = 0
    for i = 1, #candidates do
        candTotalWeight = candTotalWeight + (candidates[i].Weight or 1)
    end

    -- 加权随机
    local roll = math.random() * candTotalWeight
    local cumulative = 0
    for i = 1, #candidates do
        cumulative = cumulative + (candidates[i].Weight or 1)
        if roll <= cumulative then
            -- TeamBuffClass 是 FSoftClassPath 结构体，需转为字符串路径
            return UGCObjectUtility.GetPathBySoftObjectPath(candidates[i].TeamBuffClass)
        end
    end

    -- 兜底：返回最后一个
    return UGCObjectUtility.GetPathBySoftObjectPath(candidates[#candidates].TeamBuffClass)
end

-- ==================== 生成位置 ====================

---@private 计算掉落物生成位置
--- 先在 XY 平面随机偏移，再向下射线检测地面，最终 Z = 地面Z
---@param zombieLoc FVector 僵尸死亡位置
---@return FVector
function BP_TeamBuffDropManager:CalcSpawnLocation(zombieLoc)
    -- 1. XY 平面随机偏移（不随机高度）
    local x, y = zombieLoc.X, zombieLoc.Y
    if self.SpawnRandomRadius > 0 then
        local angle = math.random() * 2 * math.pi
        local dist = math.random() * self.SpawnRandomRadius
        x = x + math.cos(angle) * dist
        y = y + math.sin(angle) * dist
    end

    -- 2. 射线检测地面：从高处向下打一条射线，取碰撞点 Z 作为地面高度
    local traceStart = Vector.New(x, y, zombieLoc.Z)
    local traceEnd = Vector.New(x, y, zombieLoc.Z - 5000)
    local bHit, hitResults = UGCSceneQueryUtility.QueryBlocksByChannel(
        self, traceStart, traceEnd, nil, {}, {ECollisionChannel.ECC_WorldStatic}
    )

    local groundZ = zombieLoc.Z
    if bHit and hitResults then
        for _, hit in pairs(hitResults) do
            if hit.ImpactPoint then
                groundZ = hit.ImpactPoint.Z
                break
            end
        end
    end

    -- 3. 最终位置：地面 + 抬高偏移
    return Vector.New(x, y, groundZ)
end

-- ==================== 生成掉落物 ====================

---@private 生成TeamBuff掉落物
---@param buffClassPath string BuffClass的SoftClassPath
---@param spawnLoc FVector 生成位置
---@return BP_Interact_TeamBuff_C|nil
function BP_TeamBuffDropManager:SpawnDrop(buffClassPath, spawnLoc)
    if not buffClassPath or buffClassPath == "" then
        return nil
    end

    -- 同步加载BuffClass（匹配项目现有模式，如 InteractBehaviour_Grant）
    GameplayUtils.Print("[TeamBuffDrop] SpawnDrop: 加载 ", buffClassPath)
    local buffClass = UGCObjectUtility.LoadClass(buffClassPath)
    if not buffClass then
        GameplayUtils.Exception("[TeamBuffDrop] SpawnDrop: 无法加载BuffClass ", buffClassPath)
        return nil
    end
    GameplayUtils.Print("[TeamBuffDrop] SpawnDrop: 加载成功, class=", buffClass)

    -- 使用 UGCGameSystem.SpawnActor 生成（匹配项目现有模式）
    -- SpawnActor(outer, class, location, rotation, scale, owner)
    ---@type BP_Interact_TeamBuff_C
    local dropActor = UGCGameSystem.SpawnActor(
        self,
        buffClass,
        spawnLoc,
        Rotator.New(0, 0, 0),
        Vector.New(1, 1, 1),
        nil
    )

    if dropActor then
        GameplayUtils.Print("[TeamBuffDrop] SpawnDrop: 生成成功 actor=", dropActor)
        local component = dropActor:GetTeamBuffComponent()
        -- 监听Buff生命周期结束，立即移除记录(不再依赖2秒清理定时器)
        component:RegisterOnLifeSpanEnded(self.OnBuffLifeSpanEnded, self)
        component:Activate(self,self.LifeTime)
    else
        GameplayUtils.Print("[TeamBuffDrop] SpawnDrop: SpawnActor 返回 nil")
    end

    return dropActor
end

-- ==================== 清理 ====================

---@private 清理无效的掉落物引用
function BP_TeamBuffDropManager:CleanInvalidDrops()
    local validDrops = {}
    for i = 1, #self.m_activeDrops do
        local drop = self.m_activeDrops[i]
        if drop.actor and UE.IsValid(drop.actor) then
            table.insert(validDrops, drop)
        end
    end
    self.m_activeDrops = validDrops
end

---@public 掉落物被拾取后调用（由 BP_Interact_TeamBuff 调用）
---@param pickupActor AActor 被拾取的掉落物
function BP_TeamBuffDropManager:OnDropPickup(pickupActor)
    for i = #self.m_activeDrops, 1, -1 do
        if self.m_activeDrops[i].actor == pickupActor then
            table.remove(self.m_activeDrops, i)
            GameplayUtils.Print("BP_TeamBuffDropManager: 掉落物被拾取，移除记录")
            break
        end
    end
end

---@public Buff生命周期结束回调(由BP_TeamBuffComponent委托触发)
---@param buffActor BP_Interact_TeamBuff_C 生命周期结束的Buff组件
function BP_TeamBuffDropManager:OnBuffLifeSpanEnded(buffActor)
    for i = #self.m_activeDrops, 1, -1 do
        if self.m_activeDrops[i].actor == buffActor then
            table.remove(self.m_activeDrops, i)
            GameplayUtils.Print("[TeamBuffDrop] Buff生命周期结束，立即移除记录 actor=", buffActor)
            break
        end
    end
end

---@protected TeamBuff被拾取
---@param manager BP_TeamBuffDropManager_C 掉落管理器
---@param pickupActor AActor 被拾取的掉落物
---@param playerKey number 拾取的玩家
function BP_TeamBuffDropManager:OnTeamBuffPicked(manager, pickupActor, playerKey)
    if manager ~= self then
        return
    end
    self:OnDropPickup(pickupActor)
end

return BP_TeamBuffDropManager
