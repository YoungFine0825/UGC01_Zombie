---@class InteractBehaviour_SetVisible_C:BP_InteractEntityBehaviourComponent_C
---@field bVisible bool
---@field bCollision bool
---@field ExtraTargets ULuaArrayHelper<BP_InteractableBase_C>
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_SetVisible_C
local InteractBehaviour_SetVisible = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_SetVisible:ReceiveBeginPlay()
    InteractBehaviour_SetVisible.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_SetVisible:ReceiveTick(DeltaTime)
    InteractBehaviour_SetVisible.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_SetVisible:ReceiveEndPlay()
    InteractBehaviour_SetVisible.SuperClass.ReceiveEndPlay(self) 
end


---@public
---@param playerKey number
function InteractBehaviour_SetVisible:Execute(playerKey)
    self.BaseClass.Execute(self,playerKey)
    --
    ---@type BP_InteractableBase_C
    local owner = UGCActorComponentUtility.GetOwner(self)
    owner:SetActorEnableCollision(self.bCollision)
    owner:SetActorHiddenInGame(not self.bVisible)
    GameplayUtils.Print("InteractBehaviour_SetVisible.Execute : 设置实体",self.m_interactEntityComp:GetInstanceID()," 可见性：",tostring(self.bVisible)," 碰撞性：",tostring(self.bCollision))
    --
    for i = 1,self.ExtraTargets:Num() do
        local target = self.ExtraTargets:Get(i)
        if UE.IsValid(target) then
            target:SetActorHiddenInGame(not self.bVisible)
            target:SetActorEnableCollision(self.bCollision)
        end
    end
    self:OnFinish()
end

return InteractBehaviour_SetVisible