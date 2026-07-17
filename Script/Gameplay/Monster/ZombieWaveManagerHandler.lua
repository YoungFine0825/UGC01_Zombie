---@class Gameplay.ZombieWaveManagerHandler
local ZombieWaveManagerHandler = LuaClass("Gameplay.ZombieWaveManagerHandler")

---@param system Gameplay.ZombieSpawnSystem
---@param id number
---@param waveMgrActor BP_ZombieWaveManager_C
function ZombieWaveManagerHandler:Ctor(system,id,waveMgrActor)
    self.m_sys = system
    self.m_instanceId = id
    self.m_waveMgrActor = waveMgrActor
end

---@public
function ZombieWaveManagerHandler:GetInstanceId()
    return self.m_instanceId
end

---@public
---@return BP_ZombieWaveManager_C
function ZombieWaveManagerHandler:GetWaveManagerActor()
    return self.m_waveMgrActor
end

---@public
---@return boolean
function ZombieWaveManagerHandler:IsValid()
    local ret = self.m_sys ~= nil and self.m_waveMgrActor ~= nil and UE.IsValid(self.m_waveMgrActor)
    return ret
end

---@private
function ZombieWaveManagerHandler:_destroy()
    self.m_sys = nil
    self.m_waveMgrActor = nil
end

return ZombieWaveManagerHandler