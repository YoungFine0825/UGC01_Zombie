---@class BP_InteractEntityBehaviourComponent_C:ActorComponent
---@field BehaviourTag FGameplayTag
---@field ExecutionOrder int32
---@field bWaiting bool
--Edit Below--
---@type BP_InteractEntityBehaviourComponent_C
local BP_InteractEntityBehaviourComponent = {}

BP_InteractEntityBehaviourComponent.m_isExecuting = false
BP_InteractEntityBehaviourComponent.m_isFinished = false
BP_InteractEntityBehaviourComponent.m_awaked = false
---@type BP_InteractEntityComponent_C
BP_InteractEntityBehaviourComponent.m_interactEntityComp = nil
 
--[[--]]
function BP_InteractEntityBehaviourComponent:ReceiveBeginPlay()
    BP_InteractEntityBehaviourComponent.SuperClass.ReceiveBeginPlay(self)
    local owner = UGCActorComponentUtility.GetOwner(self)
    self.m_isServer = owner:HasAuthority()
    self.m_isClient = not self.m_isServer
    --GameplayUtils.Print("BP_InteractEntityBehaviourComponent ",UGCObjectUtility.GetObjectName(owner),"-",UGCObjectUtility.GetObjectName(self)," ReceiveBeginPlay！！！IsClient :",tostring(self.m_isClient))
end


--[[
function BP_InteractEntityBehaviourComponent:ReceiveTick(DeltaTime)
    BP_InteractEntityBehaviourComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function BP_InteractEntityBehaviourComponent:ReceiveEndPlay()
    BP_InteractEntityBehaviourComponent.SuperClass.ReceiveEndPlay(self)
end

---@public
---@param interactEntityComponent BP_InteractEntityComponent_C
function BP_InteractEntityBehaviourComponent:OnAwake(interactEntityComponent)
    self.m_interactEntityComp = interactEntityComponent
    self.m_awaked = true
end

---@public 客户端提前判断是否可以交互
---@param playerKey number 请求交互的玩家的playerKey
---@return boolean
---@return number EInteractEntityErrCode
function BP_InteractEntityBehaviourComponent:CanInteract(playerKey)
    if not self.m_awaked then
        return false,EInteractEntityErrCode.FailBehaviourComponentUnavailable
    end
    return true,EInteractEntityErrCode.None
end

---@public 服务端检查交互行为是否符合条件
---@param playerKey number 请求交互的玩家的playerKey
---@return boolean
---@return number EInteractEntityErrCode
function BP_InteractEntityBehaviourComponent:CanExecute(playerKey)
    return true,EInteractEntityErrCode.None
end

---@public 服务端&客户端执行
---@param playerKey number 请求交互的玩家的playerKey
function BP_InteractEntityBehaviourComponent:PreExecute(playerKey)
    self.m_isExecuting = true
    self.m_isFinished = false
end

---@public 服务端&客户端执行
---@param playerKey number 请求交互的玩家的playerKey
function BP_InteractEntityBehaviourComponent:Execute(playerKey)

end

---@public 仅服务端执行
---@param playerKey number 请求交互的玩家的playerKey
function BP_InteractEntityBehaviourComponent:OnInterrupt(playerKey)

end

---@public 服务端&客户端执行
---@param playerKey number 请求交互的玩家的playerKey
---@param entityComponent BP_InteractEntityComponent_C
function BP_InteractEntityBehaviourComponent:PostExecute(playerKey)
    self.m_isExecuting = false
end

---@protected 行为自身调用
function BP_InteractEntityBehaviourComponent:OnFinish()
    self.m_isFinished = true
end

---@public
function BP_InteractEntityBehaviourComponent:IsExecuting()
    return self.m_isExecuting
end

---@public
function BP_InteractEntityBehaviourComponent:IsFinished()
    return self.m_isFinished
end

---@public
function BP_InteractEntityBehaviourComponent:GetOwnerActor()
    if self.m_owner == nil then
        self.m_owner = UGCActorComponentUtility.GetOwner(self)
    end
    return self.m_owner
end

return BP_InteractEntityBehaviourComponent