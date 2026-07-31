---@class InteractBehaviour_DestroyEntity_C:BP_InteractEntityBehaviourComponent_C
---@field DelayTime float
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_DestroyEntity_C
local InteractBehaviour_DestroyEntity = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_DestroyEntity:ReceiveBeginPlay()
    InteractBehaviour_DestroyEntity.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_DestroyEntity:ReceiveTick(DeltaTime)
    InteractBehaviour_DestroyEntity.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_DestroyEntity:ReceiveEndPlay()
    InteractBehaviour_DestroyEntity.SuperClass.ReceiveEndPlay(self) 
end


---@public
---@param playerKey number
function InteractBehaviour_DestroyEntity:Execute(playerKey)
    --
    self.BaseClass.Execute(self,playerKey)
    --
    if self.m_isClient then
        self:OnFinish()
        return
    end
    --
    local owner = self.m_interactEntityComp:GetOwnerActor()
    if not owner then
        return self:OnFinish()
    end
    --
    if self.DelayTime > 0 then
        owner:SetLifeSpan(self.DelayTime)
    else
        --先隐藏Actor再延迟0.1秒再销毁
        owner:SetActorHiddenInGame(true)
        owner:SetActorEnableCollision(false)
        owner:SetLifeSpan(0.1)
    end
    --
    self:OnFinish()
end

return InteractBehaviour_DestroyEntity