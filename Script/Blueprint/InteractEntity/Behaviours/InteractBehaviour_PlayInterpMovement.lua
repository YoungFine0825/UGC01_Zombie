---@class InteractBehaviour_PlayInterpMovement_C:BP_InteractEntityBehaviourComponent_C
---@field PlayOnSelf bool
---@field ExtraTargets ULuaArrayHelper<BP_InteractableBase_C>
---@field Duration float
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_PlayInterpMovement_C
local InteractBehaviour_PlayInterpMovement = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_PlayInterpMovement:ReceiveBeginPlay()
    InteractBehaviour_PlayInterpMovement.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_PlayInterpMovement:ReceiveTick(DeltaTime)
    InteractBehaviour_PlayInterpMovement.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_PlayInterpMovement:ReceiveEndPlay()
    InteractBehaviour_PlayInterpMovement.SuperClass.ReceiveEndPlay(self) 
end


---@public
---@param playerKey number
function InteractBehaviour_PlayInterpMovement:Execute(playerKey)
    self.BaseClass.Execute(self,playerKey)
    --
    if self.m_isServer then
        self:OnFinish()
        return
    end
    --
    local totalPlayTargetNum = (self.PlayOnSelf and 1 or 0) + self.ExtraTargets:Num()
    if totalPlayTargetNum <= 0 then
        self:OnFinish()
        return
    end
    --
    local playedTargetNum = 0
    if self.PlayOnSelf then
        ---@type BP_InteractableBase_C
        local owner = UGCActorComponentUtility.GetOwner(self)
        if owner.PlayInterpMovement then
            owner:PlayInterpMovement()
            playedTargetNum = playedTargetNum + 1
        end
    end
    for i = 1,self.ExtraTargets:Num() do
        local target = self.ExtraTargets:Get(i)
        if UE.IsValid(target) then
            target:PlayInterpMovement()
            playedTargetNum = playedTargetNum + 1
        end
    end
    if playedTargetNum > 0 and self.Duration > 0 then
        UGCTimerUtility.CreateLuaTimer(self.Duration,function()
            if UE.IsValid(self) then
                self:OnFinish()
            end
        end,false)
    else
        self:OnFinish()
    end
end

return InteractBehaviour_PlayInterpMovement