---@class InteractBehaviour_DeductPropertyValue_C:BP_InteractEntityBehaviourComponent_C
---@field Target TEnumAsByte<EInteractBehaviourDeductPropertyValueTarget>
---@field PropertyName FString
---@field DeductValue float
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_DeductPropertyValue_C
local InteractBehaviour_DeductPropertyValue = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_DeductPropertyValue:ReceiveBeginPlay()
    InteractBehaviour_DeductPropertyValue.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_DeductPropertyValue:ReceiveTick(DeltaTime)
    InteractBehaviour_DeductPropertyValue.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_DeductPropertyValue:ReceiveEndPlay()
    InteractBehaviour_DeductPropertyValue.SuperClass.ReceiveEndPlay(self)
end


---@public 执行行为前，检查行为是否符合条件
function InteractBehaviour_DeductPropertyValue:CanExecute(playerKey)
    if self.m_isClient then
        return true,EInteractEntityErrCode.None
    end
    local parentRet,parentErr = self.BaseClass.CanExecute(self,playerKey)
    if not parentRet then
        return parentRet,parentErr
    end
    if self.Target == EInteractBehaviourDeductPropertyValueTarget.Player then
        local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
        local propertyValue = UGCAttributeSystem.GetGameAttributeValue(playerPawn,self.PropertyName)
        GameplayUtils.Print("InteractBehaviour_DeductPropertyValue.CanExecute: ",self.PropertyName," cur =",propertyValue," need = ",self.DeductValue)
        if propertyValue < self.DeductValue then
            return false,EInteractEntityErrCode.FailUnavailable
        end
    end
    return true,EInteractEntityErrCode.None
end

---@public
---@param playerKey number
function InteractBehaviour_DeductPropertyValue:Execute(playerKey)
    --
    self.BaseClass.Execute(self,playerKey)
    --
    if self.m_isClient then
        self:OnFinish()
        return
    end
    --
    if self.Target == EInteractBehaviourDeductPropertyValueTarget.Player then
        local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
        local propertyValue = UGCAttributeSystem.GetGameAttributeValue(playerPawn,self.PropertyName)
        local newValue = math.max(0,propertyValue - self.DeductValue)
        UGCAttributeSystem.SetGameAttributeValue(playerPawn,self.PropertyName,newValue)
    end
    --
    self:OnFinish()
end

return InteractBehaviour_DeductPropertyValue