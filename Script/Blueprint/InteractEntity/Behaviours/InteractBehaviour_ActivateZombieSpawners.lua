---@class InteractBehaviour_ActivateZombieSpawners_C:BP_InteractEntityBehaviourComponent_C
---@field ZombieSpawners ULuaArrayHelper<BP_ZombieSpawner_C>
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_ActivateZombieSpawners_C
local InteractBehaviour_ActivateZombieSpawners = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_ActivateZombieSpawners:ReceiveBeginPlay()
    InteractBehaviour_ActivateZombieSpawners.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_ActivateZombieSpawners:ReceiveTick(DeltaTime)
    InteractBehaviour_ActivateZombieSpawners.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_ActivateZombieSpawners:ReceiveEndPlay()
    InteractBehaviour_ActivateZombieSpawners.SuperClass.ReceiveEndPlay(self) 
end

---@public
---@param playerKey number
function InteractBehaviour_ActivateZombieSpawners:Execute(playerKey)
    self.BaseClass.Execute(self, playerKey)
    if self.m_isClient then
        return self:OnFinish()
    end
    for i = 1,self.ZombieSpawners:Num() do
        ---@type BP_ZombieSpawner_C
        local spawner = self.ZombieSpawners:Get(i)
        if UE.IsValid(spawner) and not spawner:IsActive() then
            spawner:ServerActivate()
        end
    end
    self:OnFinish()
end

return InteractBehaviour_ActivateZombieSpawners