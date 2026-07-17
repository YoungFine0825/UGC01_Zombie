---@class InteractBehaviour_PlayDoTween_C:BP_InteractEntityBehaviourComponent_C
---@field PlaySelf bool
---@field ExtraTargets ULuaArrayHelper<BP_InteractableBase_C>
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_PlayDoTween_C
local InteractBehaviour_PlayDoTween = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")

--[[--]]
function InteractBehaviour_PlayDoTween:ReceiveBeginPlay()
    InteractBehaviour_PlayDoTween.SuperClass.ReceiveBeginPlay(self)
    local classPath = UGCGameSystem.GetUGCResourcesFullPath("Asset/Blueprint/Components/Misc/BP_DoTween.BP_DoTween_C")
    self.m_doTweenClass = UGCObjectUtility.LoadClass(classPath)
end

--[[
function InteractBehaviour_PlayDoTween:ReceiveTick(DeltaTime)
    InteractBehaviour_PlayDoTween.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_PlayDoTween:ReceiveEndPlay()
    InteractBehaviour_PlayDoTween.SuperClass.ReceiveEndPlay(self)
end


---@public
---@param playerKey number
function InteractBehaviour_PlayDoTween:Execute(playerKey)
    self.BaseClass.Execute(self, playerKey)
    --
    if self.m_isServer then
        self:OnFinish()
        return
    end
    --
    if not self.m_doTweenClass then
        self:OnFinish()
        return
    end
    --
    local maxDuration = 0
    local playedAny = false
    --
    local function PlayDoTweensOnActor(actor, trackDuration)
        if not UE.IsValid(actor) then
            return
        end
        local comps = UGCActorComponentUtility.GetComponentsByClass(actor, self.m_doTweenClass)
        for _, comp in ipairs(comps) do
            if UE.IsValid(comp) and comp.Play then
                comp:Play()
                playedAny = true
                if trackDuration then
                    local duration = comp.Duration or 0
                    if duration > maxDuration then
                        maxDuration = duration
                    end
                end
            end
        end
    end
    --
    if self.PlaySelf then
        local owner = UGCActorComponentUtility.GetOwner(self)
        PlayDoTweensOnActor(owner, true)
    end
    if self.ExtraTargets then
        for i = 1, self.ExtraTargets:Num() do
            local target = self.ExtraTargets:Get(i)
            PlayDoTweensOnActor(target, false)
        end
    end
    --
    if playedAny and maxDuration > 0 then
        UGCTimerUtility.CreateLuaTimer(maxDuration, function()
            if UE.IsValid(self) then
                self:OnFinish()
            end
        end, false)
    else
        self:OnFinish()
    end
end

return InteractBehaviour_PlayDoTween
