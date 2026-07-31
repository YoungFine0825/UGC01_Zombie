---@class Gameplay.ZombieSpawnerHandler
local ZombieSpawnerHandler = LuaClass("Gameplay.ZombieSpawnerHandler")

---@param system Gameplay.ZombieSpawnSystem
---@param id number
---@param spawnerActor BP_ZombieSpawner_C
function ZombieSpawnerHandler:Ctor(system,id,spawnerActor)
    self.m_sys = system
    self.m_instanceId = id
    self.m_spawnerActor = spawnerActor
end

---@public
function ZombieSpawnerHandler:GetInstanceId()
    return self.m_instanceId
end

---@public
---@return BP_ZombieSpawner_C
function ZombieSpawnerHandler:GetSpawnerActor()
    return self.m_spawnerActor
end

---@public
---@return boolean
function ZombieSpawnerHandler:IsValid()
    local ret = self.m_sys ~= nil and self.m_spawnerActor ~= nil and UE.IsValid(self.m_spawnerActor)
    return ret
end

---@private
function ZombieSpawnerHandler:_destroy()
    self.m_sys = nil
    self.m_spawnerActor = nil
end

local ZombieWaveManagerHandler = UGCGameSystem.UGCRequire("Script.Gameplay.Monster.ZombieWaveManagerHandler")

---@class Gameplay.ZombieSpawnSystem
local ZombieSpawnSystem = LuaClass("Gameplay.ZombieSpawnSystem")

function ZombieSpawnSystem:Ctor()
    self.m_waveMgrInstanceId = 1
    ---@type Gameplay.ZombieWaveManagerHandler[]
    self.m_registeredWaveManagers = {}
    
    self.m_spawnerInstanceId = 1
    ---@type Gameplay.ZombieSpawnerHandler[]
    self.m_registeredSpawners = {}
end


---丧尸生成系统尺寸只存在服务端，定义服务端生命周期函数即可
function ZombieSpawnSystem:BeginPlayOnServer()
    GameplayUtils.Print("ZombieSpawnSystem.BeginPlayOnServer")
end

function ZombieSpawnSystem:EndPlayOnServer()
    GameplayUtils.Print("ZombieSpawnSystem.EndPlayOnServer")
end
---

---@private
function ZombieSpawnSystem:_AllocWaveManagerInstanceId()
    local id = self.m_waveMgrInstanceId
    self.m_waveMgrInstanceId = self.m_waveMgrInstanceId + 1
    return id
end

---@public
---@param managerActor BP_ZombieWaveManager_C
---@return Gameplay.ZombieWaveManagerHandler
function ZombieSpawnSystem:RegisterWaveManager(managerActor)
    local instanceId = self:_AllocWaveManagerInstanceId()
    local handler = ZombieWaveManagerHandler.New(self,instanceId,managerActor)
    table.insert(self.m_registeredWaveManagers,handler)
    return handler
end

---@public
---@param handler Gameplay.ZombieWaveManagerHandler
function ZombieSpawnSystem:UnregisterWaveManager(handler)
    if handler == nil or not handler:IsValid() then
        return
    end
    for i = #self.m_registeredWaveManagers,1,-1 do
        if self.m_registeredWaveManagers[i]:GetInstanceId() == handler:GetInstanceId() then
            self.m_registeredWaveManagers[i]:_destroy()
            table.remove(self.m_registeredWaveManagers,i)
        end
    end
end

---@private
function ZombieSpawnSystem:_AllocSpawnerInstanceId()
    local id = self.m_spawnerInstanceId
    self.m_spawnerInstanceId = self.m_spawnerInstanceId + 1
    return id
end

---@public
---@param spawnerActor BP_ZombieSpawner_C
---@return Gameplay.ZombieSpawnerHandler
function ZombieSpawnSystem:RegisterSpawner(spawnerActor)
    local instanceId = self:_AllocSpawnerInstanceId()
    local handle = ZombieSpawnerHandler.New(self,instanceId,spawnerActor)
    table.insert(self.m_registeredSpawners,handle)
    return handle
end

---@public
---@param handle Gameplay.ZombieSpawnerHandler
function ZombieSpawnSystem:UnregisterSpawner(handle)
    if handle == nil or not handle:IsValid() then
        return
    end
    for i = #self.m_registeredSpawners,1,-1 do
        if self.m_registeredSpawners[i]:GetInstanceId() == handle:GetInstanceId() then
            self.m_registeredSpawners[i]:_destroy()
            table.remove(self.m_registeredSpawners,i)
        end
    end
end

---@public
---@return Gameplay.ZombieSpawnerHandler[]
function ZombieSpawnSystem:GetAllSpawners()
    return self.m_registeredSpawners
end

---@public 同一时间场上最大丧尸数量
function ZombieSpawnSystem:CalcuMaxZombiesNumberAtOneTime(playerCount,minNumber,extraNumPerPlayer)
    local extraNum = math.max(0,playerCount - 1) * extraNumPerPlayer--每多一名玩家，增加extraNumPerPlayer
    local ret = minNumber + extraNum
    return ret
end

---@public 计算指定回合丧尸数量
---@param waveMgr BP_ZombieWaveManager_C
function ZombieSpawnSystem:CalcuMaxZombiesNumber(round,playerCount,waveMgr)
    local maxNumAtOneTime = self:CalcuMaxZombiesNumberAtOneTime(playerCount,waveMgr.MaxZombieNumAtOneTime,waveMgr.ExtraZombieNumPerPlayer)
    local zombiesNum = 0
    if round >= 1 and round <= 4 then
        zombiesNum = math.floor(maxNumAtOneTime * (round * 0.2))
    elseif round >= 5 and round <= 10 then
        zombiesNum = maxNumAtOneTime
    else
        zombiesNum = round * 0.15 * maxNumAtOneTime
    end
    return zombiesNum
end

---@public
function ZombieSpawnSystem:CalcuMaxZombieHealth(round,baseHealth)
    local zombieHp = baseHealth
    if round >= 1 and round <= 10 then
        --1~10回合单调递增
        zombieHp = math.max(0,round - 1) * 100 + baseHealth
    else
        --10回合以后，按1.1倍指数递增
        local previousRoundHp = 10 * 100 + baseHealth
        zombieHp = previousRoundHp * (1.1^(round - 10))
    end
    return zombieHp
end

---@public
---@return Gameplay.Struct.MonsterSpawnScheme
function ZombieSpawnSystem:GetSpawnSchemeConfig(schemeID)
    if not self.m_spawnSchemeCfgTable then
        ---@type Gameplay.Struct.MonsterSpawnScheme[]
        self.m_spawnSchemeCfgTable = UGCGameSystem.GetTableData("Data/Table/DT_MonsterSpawnScheme")
    end
    local schemeConfig = nil
    for _, value in pairs(self.m_spawnSchemeCfgTable) do
        if value.SchemeID == tonumber(schemeID) then
            schemeConfig = value
            break
        end
    end
    return schemeConfig
end

---@public
---@return Gameplay.Struct.MonsterDetails
function ZombieSpawnSystem:GetZombieDetailsConfig(id)
    if not self.m_detailsCfgTable then
        ---@type Gameplay.Struct.MonsterDetails[]
        self.m_detailsCfgTable = UGCGameSystem.GetTableData("Data/Table/DT_MonsterDetails")
    end
    for _, value in pairs(self.m_detailsCfgTable) do
        if value.MonsterID == id then
            return value
        end
    end
    return nil
end

---@public
function ZombieSpawnSystem:SetZombieCanBeInstaKill(zombiePawn,enabled)
    UGCAttributeSystem.SetGameAttributeValue(zombiePawn,'CanInstaKill',enabled and 1 or 0)
end

return ZombieSpawnSystem