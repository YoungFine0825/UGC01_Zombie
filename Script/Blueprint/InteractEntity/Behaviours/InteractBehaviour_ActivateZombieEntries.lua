---@class InteractBehaviour_ActivateZombieEntries_C:BP_InteractEntityBehaviourComponent_C
---@field ZombieEntries ULuaArrayHelper<BP_EntryForZombie_Base_C>
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_ActivateZombieEntries_C
local InteractBehaviour_ActivateZombieEntries = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_ActivateZombieEntries:ReceiveBeginPlay()
    InteractBehaviour_ActivateZombieEntries.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_ActivateZombieEntries:ReceiveTick(DeltaTime)
    InteractBehaviour_ActivateZombieEntries.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_ActivateZombieEntries:ReceiveEndPlay()
    InteractBehaviour_ActivateZombieEntries.SuperClass.ReceiveEndPlay(self) 
end

---@public
---@param playerKey number
function InteractBehaviour_ActivateZombieEntries:Execute(playerKey)
    self.BaseClass.Execute(self, playerKey)
    if self.m_isClient then
        return self:OnFinish()
    end
    for i = 1,self.ZombieEntries:Num() do
        ---@type BP_EntryForZombie_Base_C
        local entry = self.ZombieEntries:Get(i)
        if UE.IsValid(entry) and not entry:IsActive() then
            entry:ServerActivate()
        end
    end
    self:OnFinish()
end

return InteractBehaviour_ActivateZombieEntries