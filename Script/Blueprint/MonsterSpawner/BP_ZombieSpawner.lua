---@class BP_ZombieSpawner_C:BP_UGCMobSpawner_C
---@field bIsOutside bool
---@field Entry ULuaArrayHelper<BP_EntryForZombie_Base_C>
---@field bDefaultActive bool
--Edit Below--

---@type BP_ZombieSpawner_C
local BP_ZombieSpawner = {
    ---@type Gameplay.ZombieSpawnerHandler
    m_spawnerHandler = nil,
    --
    bUseUGCSystemSpawn = false,
    --
    m_lastSpawnTime = 0,
}

--[[--]]
function BP_ZombieSpawner:ReceiveBeginPlay()
    BP_ZombieSpawner.SuperClass.ReceiveBeginPlay(self)
    --
    self.m_isActived = self.bDefaultActive
    --
    if UGCGameSystem.IsServer() then
        self:OnBeginPlay()
    end
end

--[[--]]
function BP_ZombieSpawner:ReceiveEndPlay()
    BP_ZombieSpawner.SuperClass.ReceiveEndPlay(self)
    if UGCGameSystem.IsServer() then
        self:OnEndPlay()
    end
end


function BP_ZombieSpawner:GetReplicatedProperties()
    return {"m_isActived","Lazy"}
end

---@public
---@return boolean
function BP_ZombieSpawner:IsActive()
    return self.m_isActived
end

---@private
function BP_ZombieSpawner:OnRep_m_isActived()
    GameplayUtils.Print("BP_ZombieSpawner.OnRep_m_isActived: 丧尸入口 ",UGCObjectUtility.GetObjectName(self)," 激活！")
end

---@public 激活入口
function BP_ZombieSpawner:ServerActivate()
    if not UGCGameSystem.IsServer() then
        return
    end
    self.m_isActived = true
    UnrealNetwork.RepLazyProperty(self,"m_isActived")
    GameplayUtils.Print("BP_ZombieSpawner.ServerActivate: 丧尸入口 ",UGCObjectUtility.GetObjectName(self)," 激活！")
end

--[[
function BP_ZombieSpawner:OnMobSpawn(MobPawn)
    
end
--]]

--[[
function BP_ZombieSpawner:CustomSpawnMob(InCustomParam)
    
end
--]]

function BP_ZombieSpawner:OnBeginPlay()
    self.m_spawnerHandler = GameplaySystem.ZombieSpawnSystem:RegisterSpawner(self)
end

function BP_ZombieSpawner:OnEndPlay()
    GameplaySystem.ZombieSpawnSystem:UnregisterSpawner(self.m_spawnerHandler)
end

---@public
---@return BP_Zombie_Base_C
function BP_ZombieSpawner:SpawnZombieWithClass(zombieClass)
    if not UE.IsValid(zombieClass) then
        GameplayUtils.Exception("BP_ZombieSpawner.SpawnZombieWithClass: zombieClass is not valid！！！")
        return nil
    end
    local gameMode = UGCGameSystem.GetGameMode()
    ---@type BP_Zombie_Base_C
    local SpawnedZombie = self:_SpawnZombie(zombieClass)
    if SpawnedZombie then
        GameplayUtils.Exception("BP_ZombieSpawner.SpawnZombieWithClass: 生成丧尸完成！！！")
    else
        GameplayUtils.Exception("BP_ZombieSpawner.SpawnZombieWithClass: 生成丧尸失败！！！")
    end
    return SpawnedZombie
end

---@private
---@return BP_Zombie_Base_C
function BP_ZombieSpawner:_SpawnZombie(zombieClass)
    ---@type BP_Zombie_Base_C
    local ret = nil
    if self.bUseUGCSystemSpawn then
        local gameMode = UGCGameSystem.GetGameMode()
        ret = UGCGameSystem.SpawnActor(gameMode,zombieClass,self:K2_GetActorLocation(),self:K2_GetActorRotation(),Vector.New(1, 1, 1),self)
    else
        ret = self:SpawnMob(zombieClass)
    end
    if ret ~= nil then
        self.m_lastSpawnTime = UGCGameSystem.GetServerTimeSec()
    end
    return ret
end

---@private
function BP_ZombieSpawner:CustomSpawnMob(InCustomParam)
    GameplayUtils.Print("BP_ZombieSpawner.CustomSpawnMob")
    return nil
end

---@public
---@return boolean
function BP_ZombieSpawner:CanSpawnZombie()
    if not self.m_isActived then
        return false
    end
    local curTime = UGCGameSystem.GetServerTimeSec()
    if math.max(0,curTime - self.m_lastSpawnTime) < 1 then
        return false
    end
    if self.bIsOutside then
        local freePositionsNum = 0
        local validEntries = 0
        local invalidEntries = 0
        local noFreeSlotEntries = 0
        for i = 1,self.Entry:Num() do
            ---@type BP_EntryForZombie_Base_C
            local entry = self.Entry:Get(i)
            if UE.IsValid(entry) and entry:IsActive() then
                validEntries = validEntries + 1
                if entry:HaveFreePositionSlots() then
                    freePositionsNum = freePositionsNum + 1
                else
                    noFreeSlotEntries = noFreeSlotEntries + 1
                end
            else
                invalidEntries = invalidEntries + 1
            end
        end
        if freePositionsNum <= 0 then
            GameplayUtils.Exception(string.format(
                "[CanSpawnZombie] 阻挡 | %s | bIsOutside=true | Entry总数=%d 有效=%d(有空位=%d/无空位=%d) 无效=%d",
                GameplayUtils.GetUEObjClassName(self), self.Entry:Num(), validEntries, freePositionsNum, noFreeSlotEntries, invalidEntries
            ))
            return false
        end
    end
    return true
end

---@public 直接返回Entry数组引用，不再用Lua table包装
---@return ULuaArrayHelper<BP_EntryForZombie_Base_C>
function BP_ZombieSpawner:GetEntryList()
    return self.Entry
end

return BP_ZombieSpawner---@type BP_ZombieSpawner_C