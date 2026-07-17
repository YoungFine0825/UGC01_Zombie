---@class BP_ZombieWaveManager_C:AActor
---@field DefaultSceneRoot USceneComponent
---@field ZombieClass FSoftClassPath
---@field MaxZombieNumAtOneTime int32
---@field ExtraZombieNumPerPlayer int32
---@field RageStartRound int32
---@field RageStartRatio float
---@field RageRatioStep float
---@field RageMaxRatio float
---@field SpawnSchemeID int32
--Edit Below--

---@type BP_ZombieWaveManager_C
local BP_ZombieWaveManager = {
    m_bIsServer = false,
    ---@type Gameplay.ZombieWaveManagerHandler
    m_waveMgrHandler = nil,
    ---@type BP_GameplayStateComponent
    m_gameplayStateComp = nil,
    m_bStartSpawning = false,
    m_loadedZombieClass = nil
}

BP_ZombieWaveManager.m_nextSpawnTime = 0
BP_ZombieWaveManager.m_curRoundZombieSpawnPlan = {
    totalNumber = 0,--当前回合最大丧尸数量
    maxZombieNumAtOneTime = 0,--当前回合，场上同一时间最大丧尸数量
    spawnedNumber = 0,--当前回合已生成的数量
    alivingNumber = 0,--当前回合场上生存的数量
    deadNum = 0,--当前回合死亡的数量
    totalRageNumber = 0,--当前回合狂暴状态数量的丧尸总数
    spawnedRageNumber = 0,
    zombieHp = 0,--当前回合丧尸血量
}
BP_ZombieWaveManager.m_curRoundNum = 0
BP_ZombieWaveManager.m_spawnZombieCounter = 0
---@type Gameplay.Struct.MonsterSpawnScheme
BP_ZombieWaveManager.m_spawnSchemeConfig = nil
--[[
   局内每回合丧尸刷新管理器
--]]

--[[--]]
function BP_ZombieWaveManager:ReceiveBeginPlay()
    BP_ZombieWaveManager.SuperClass.ReceiveBeginPlay(self)
    self.m_bIsServer = UGCGameSystem.IsServer()
    if self.m_bIsServer then
        self:OnBeginPlay()
    end
end


--[[--]]
function BP_ZombieWaveManager:ReceiveTick(DeltaTime)
    BP_ZombieWaveManager.SuperClass.ReceiveTick(self, DeltaTime)
    if self.m_bIsServer then
        self:OnTick(DeltaTime)
    end
end


--[[--]]
function BP_ZombieWaveManager:ReceiveEndPlay()
    BP_ZombieWaveManager.SuperClass.ReceiveEndPlay(self)
    if self.m_bIsServer then
        self:OnEndPlay()
    end
end


--[[
function BP_ZombieWaveManager:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_ZombieWaveManager:GetAvailableServerRPCs()
    return
end
--]]


---@protected
function BP_ZombieWaveManager:OnBeginPlay()
    self.m_spawnSchemeConfig = GameplaySystem.ZombieSpawnSystem:GetSpawnSchemeConfig(self.SpawnSchemeID)
    if not self.m_spawnSchemeConfig then
        GameplayUtils.Exception("BP_ZombieWaveManager:OnBeginPlay: 无法获取丧尸生成组配置 ",self.SpawnSchemeID)
    end
    self.m_gameplayStateComp = GameplaySystem.GetGameplayStateComponent()
    self.m_waveMgrHandler = GameplaySystem.ZombieSpawnSystem:RegisterWaveManager(self)
    UGCObjectUtility.AsyncLoadObjectBySoftPath(self.ZombieClass,function(class)
        self.m_loadedZombieClass = class
    end)
    UGCGenericMessageSystem.ListenGlobalMessage(self,GameplayEvents.Server.OnGameplayStart,self,self.OnGameplayStart)
    UGCGenericMessageSystem.ListenGlobalMessage(self,GameplayEvents.Server.OnRoundStart,self,self.OnRoundStart)
    UGCGenericMessageSystem.ListenGlobalMessage(self,GameplayEvents.Server.OnZombieBeKilled,self,self.OnZombieBeKilled)
end

---@protected
function BP_ZombieWaveManager:OnTick(DeltaTime)
    if self.m_bStartSpawning then
        local curTime = UGCGameSystem.GetServerTimeSec()
        if curTime >= self.m_nextSpawnTime then
            self.m_nextSpawnTime = curTime + 2
            local planInfo = self.m_curRoundZombieSpawnPlan
            local remainingZombiesNum = planInfo.totalNumber - planInfo.spawnedNumber
            if remainingZombiesNum > 0 then--丧尸生成完了没有？
                local curAliveNum = planInfo.alivingNumber--当前场上存在的丧尸数量
                local maxAliveNumAtOneTime = math.min(planInfo.totalNumber,planInfo.maxZombieNumAtOneTime)--场上最多同时存在多少丧尸
                if curAliveNum < maxAliveNumAtOneTime then--是否需要补充丧尸？
                    local spawnedNum = 0--本次生成了多少丧尸
                    local spawnedRageNum = 0--其中狂暴丧尸是多少个
                    local allSpawners = GameplaySystem.ZombieSpawnSystem:GetAllSpawners()
                    for k,v in pairs(allSpawners) do
                        local spawner = v:GetSpawnerActor()
                        if spawner:CanSpawnZombie() then
                            --是否是狂暴丧尸
                            local zombieType = self:DetermineZombieTypeWhenSpawn(
                                    planInfo.spawnedNumber + spawnedNum + 1,
                                    planInfo.spawnedRageNumber + spawnedRageNum + 1
                            )
                            if self:SpawnZombie(spawner,zombieType) then
                                spawnedNum = spawnedNum + 1
                                if zombieType == EZombieType.RageZombie then
                                    spawnedRageNum = spawnedRageNum + 1
                                end
                                if remainingZombiesNum - spawnedNum <= 0 then
                                    break--丧尸数量达到最大
                                end
                                if curAliveNum + spawnedNum >= maxAliveNumAtOneTime then
                                    break--丧尸数量达到场上能存在的最大数量
                                end
                            end
                        end
                    end
                    planInfo.spawnedNumber = planInfo.spawnedNumber + spawnedNum
                    planInfo.spawnedRageNumber = planInfo.spawnedRageNumber + spawnedRageNum
                    planInfo.alivingNumber = planInfo.alivingNumber + spawnedNum
                end
            end
        end
    end
end

---@protected
function BP_ZombieWaveManager:OnEndPlay()
    self.m_spawnSchemeConfig = nil
    self.m_gameplayStateComp = nil
    self.m_loadedZombieClass = nil
    GameplaySystem.ZombieSpawnSystem:UnregisterWaveManager(self.m_waveMgrHandler)
    UGCGenericMessageSystem.UnListenMessage(self,GameplayEvents.Server.OnGameplayStart)
    UGCGenericMessageSystem.UnListenMessage(self,GameplayEvents.Server.OnRoundStart)
    UGCGenericMessageSystem.UnListenMessage(self,GameplayEvents.Server.OnZombieBeKilled)
end

---@private
function BP_ZombieWaveManager:OnGameplayStart()

end

---@protected
function BP_ZombieWaveManager:OnRoundStart(roundNum)
    self.m_curRoundNum = roundNum
    self.m_spawnZombieCounter = 0
    self:BuildZombieSpawnPlan(roundNum)
    --
    self.m_bStartSpawning = true
    self.m_nextSpawnTime = UGCGameSystem.GetServerTimeSec() + 5
end

---@protected
function BP_ZombieWaveManager:OnRoundEnd(roundNum)

end

---@protected
---@param zombiePawn BP_Zombie_Base_C
function BP_ZombieWaveManager:OnZombieBeKilled(zombiePawn)
    local planInfo = self.m_curRoundZombieSpawnPlan
    planInfo.deadNum = planInfo.deadNum + 1
    planInfo.alivingNumber = math.max(0,planInfo.alivingNumber - 1)
    if planInfo.deadNum >= planInfo.totalNumber then
        GameplayUtils.Print("BP_ZombieWaveManager.OnZombieBeKilled: 第",self.m_curRoundNum,"回合丧尸全部被消灭！")
        for k,v in pairs(self.m_curRoundZombieSpawnPlan) do
            GameplayUtils.Print("BP_ZombieWaveManager.OnZombieBeKilled: ",k,"=",v)
        end
        --丧尸全部消灭，回合结束
        self.m_bStartSpawning = false
        --
        GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnAllZombiesBeEliminated,self)
    end
end

---@protected
function BP_ZombieWaveManager:BuildZombieSpawnPlan(round)
    local planInfo = self.m_curRoundZombieSpawnPlan
    planInfo.deadNum = 0
    planInfo.spawnedNumber = 0
    planInfo.alivingNumber = 0
    local playerCnt = UGCGameSystem.GetPlayerNum(true)
    local zombiesNum = GameplaySystem.ZombieSpawnSystem:CalcuMaxZombiesNumber(round,playerCnt,self)
    local zombieHp = GameplaySystem.ZombieSpawnSystem:CalcuMaxZombieHealth(round,100)
    planInfo.maxZombieNumAtOneTime = GameplaySystem.ZombieSpawnSystem:CalcuMaxZombiesNumberAtOneTime(playerCnt,self.MaxZombieNumAtOneTime,self.ExtraZombieNumPerPlayer)
    planInfo.totalNumber = zombiesNum
    planInfo.zombieHp = zombieHp
    --计算狂暴丧尸数量占比
    local rageRatio = 0
    if self.m_spawnSchemeConfig then
        local cfg = self.m_spawnSchemeConfig
        rageRatio = math.min(cfg.RageMaxRatio,cfg.RageStartRatio + cfg.RageRatioStep * math.max(0,round - cfg.RageStartRound))
    else
        GameplayUtils.Exception("BP_ZombieWaveManager.BuildZombieSpawnPlan: 丧尸生成组配置为空！")
    end
    local rageZombieNum = math.floor(zombiesNum * rageRatio + 0.5)
    planInfo.totalRageNumber = rageZombieNum
    planInfo.spawnedRageNumber = 0
    GameplayUtils.Print("BP_ZombieWaveManager.BuildZombieSpawnPlan: ",round,"回合丧尸总数：",zombiesNum)
    GameplayUtils.Print("BP_ZombieWaveManager.BuildZombieSpawnPlan: ",round,"回合狂暴丧尸总数：",rageZombieNum)
    GameplayUtils.Print("BP_ZombieWaveManager.BuildZombieSpawnPlan: ",round,"回合丧尸血量：",zombieHp)
end

---@protected
---@return Gameplay.EZombieType
function BP_ZombieWaveManager:DetermineZombieTypeWhenSpawn(spawnedNum,spawnedRageNum)
    local planInfo = self.m_curRoundZombieSpawnPlan
    local remainingZombiesNum = planInfo.totalNumber - spawnedNum
    local remainingRageNum = planInfo.totalRageNumber - spawnedRageNum
    if remainingRageNum <= 0 then
        return EZombieType.NormalZombie
    end
    if remainingRageNum >= remainingZombiesNum then
        return EZombieType.RageZombie
    end
    local prob = remainingRageNum / remainingZombiesNum
    if math.random() < prob then
        return EZombieType.RageZombie
    end
    return EZombieType.NormalZombie
end

---@protected
function BP_ZombieWaveManager:GetRandomZombieForSpawn(zombieType)
    if not self.m_spawnSchemeConfig then
        GameplayUtils.Exception("BP_ZombieWaveManager.GetRandomZombieForSpawn: 丧尸生成组配置为空!")
        return 0
    end
    ---@type Gameplay.Struct.MonsterSpawnerTypeConfig
    local spawnGroup = nil
    for k,v in pairs(self.m_spawnSchemeConfig.SpawnerTypes) do
        if v.SpawnerType == zombieType then
            spawnGroup = v
            break
        end
    end
    if not spawnGroup then
        GameplayUtils.Exception("BP_ZombieWaveManager.GetRandomZombieForSpawn: 未找到对应丧尸分组，zombieType=",zombieType)
        return 0
    end

    local monsters = spawnGroup.Monsters
    if not monsters then
        GameplayUtils.Exception("BP_ZombieWaveManager.GetRandomZombieForSpawn: 丧尸分组为空，zombieType=",zombieType)
        return 0
    end

    local totalWeight = 0
    local fallbackMonsterID = nil
    for _, monsterInfo in pairs(monsters) do
        if fallbackMonsterID == nil and monsterInfo.MonsterID ~= nil then
            fallbackMonsterID = monsterInfo.MonsterID
        end

        local weight = tonumber(monsterInfo.Weight) or 0
        if weight > 0 then
            totalWeight = totalWeight + weight
        end
    end

    if totalWeight <= 0 then
        GameplayUtils.Print("BP_ZombieWaveManager.GetRandomZombieForSpawn: 总权重无效，使用回退MonsterID，zombieType=",zombieType," monsterID=",fallbackMonsterID)
        return fallbackMonsterID
    end

    local randNum = math.random(1, totalWeight)
    for _, monsterInfo in pairs(monsters) do
        local weight = tonumber(monsterInfo.Weight) or 0
        if weight > 0 then
            randNum = randNum - weight
            if randNum <= 0 then
                return monsterInfo.MonsterID
            end
        end
    end

    GameplayUtils.Print("BP_ZombieWaveManager.GetRandomZombieForSpawn: 权重随机未命中，使用回退MonsterID，zombieType=",zombieType," monsterID=",fallbackMonsterID)
    return fallbackMonsterID
end

---@private
---@param spawner BP_ZombieSpawner_C
---@return boolean
function BP_ZombieWaveManager:SpawnZombie(spawner,zombieType)
    local counter = self.m_spawnZombieCounter + 1
    local zombieID = self:GetRandomZombieForSpawn("Zombie")
    if zombieID <= 0 then
        GameplayUtils.Print("BP_ZombieWaveManager.StartSpawnZombie: 第",self.m_curRoundNum,"回合第",counter,"只丧尸失败！无法获取丧尸配置ID")
        return false
    end
    local zombieCfg = GameplaySystem.ZombieSpawnSystem:GetZombieDetailsConfig(zombieID)
    if zombieCfg == nil then
        GameplayUtils.Print("BP_ZombieWaveManager.StartSpawnZombie: 第",self.m_curRoundNum,"回合第",counter,"只丧尸失败！无法获取丧尸配置！ ID =",zombieID)
        return false
    end
    local zombieClass = UGCObjectUtility.LoadObjectBySoftPath(zombieCfg.MonsterClass)
    local spawnedZombie = spawner:SpawnZombieWithClass(zombieClass)
    if spawnedZombie then
        self.m_spawnZombieCounter = counter
        self:InitSpawnedZombie(zombieID,spawnedZombie,spawner,zombieType)
        --
        --GameplayUtils.Print("BP_ZombieWaveManager.StartSpawnZombie: 第",self.m_curRoundNum,"回合第",counter,"只丧尸成功！！！")
        return true
    else
        GameplayUtils.Print("BP_ZombieWaveManager.StartSpawnZombie: 第",self.m_curRoundNum,"回合第",counter,"只丧尸失败！！！")
        return false
    end
end

---@protected
---@param zombiePawn BP_Zombie_Base_C
---@param spawner BP_ZombieSpawner_C
---@param zombieType Gameplay.EZombieType
function BP_ZombieWaveManager:InitSpawnedZombie(zombieID,zombiePawn,spawner,zombieType)
    zombiePawn:SetConfigID(zombieID)
    ----初始化血量
    local planInfo = self.m_curRoundZombieSpawnPlan
    UGCAttributeSystem.SetGameAttributeValue(zombiePawn, 'BaseHealth', planInfo.zombieHp)
    UGCAttributeSystem.SetGameAttributeValue(zombiePawn, 'HealthMax', planInfo.zombieHp)
    --
    zombiePawn:ServerShouldFindEntry(spawner.bIsOutside)
    --
    if spawner.bIsOutside then
        --为丧尸选择一个最近的入口
        ---@type BP_EntryForZombie_Base_C
        local entryActor = GameplaySystem.MonsterAISystem:ServerFindNearstEntry(zombiePawn,spawner:GetEntryList())
        zombiePawn:ServerSetTargetEntry(entryActor)
    else
        --出生在游戏区域内部，不需要找入口，直接追踪最近的玩家
        local targetPlayer = GameplaySystem.MonsterAISystem:ServerFindNearstPlayerAsTarget(zombiePawn)
        zombiePawn:ServerTrackingPlayer(targetPlayer)
    end
    --
    if zombieType == EZombieType.RageZombie then
        UGCAttributeSystem.SetGameAttributeValue(zombiePawn, 'UGCGeneralMoveSpeedScale', 1.7)
    end
end

return BP_ZombieWaveManager
