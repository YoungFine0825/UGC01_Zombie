local UGCRequire = UGCGameSystem.UGCRequire
UGCRequire("Script.Gameplay.InteractEntity.InteractEntityDefine")

---@class Gameplay.InteractEntitySystem.InteractionRequest
---@field PlayerKey number
---@field EntityInstanceID number
---@field CallbackObj table
---@field CallbackFunc function
---@field IgnoreConditionChecking boolean
---@field skipBehaviours FGameplayTag[]

local EBehaviourExecutionTaskStage = {
    PreExecute = 1,
    Exccute = 2,
    PostExecute = 3,
}

---@class Gameplay.InteractEntitySystem.BehaviourExecutionTask
---@field orderedBehaviours BP_InteractEntityBehaviourComponent_C[]
---@field interactComponent BP_InteractEntityComponent_C
---@field instanceID number
---@field callbackObj
---@field callbackFunc
---@field playerKey number
---@field executingStage number EBehaviourExecutionTaskStage

---@class Gameplay.InteractEntitySystem:Gameplay.IGameplaySystem
local Cls = LuaClass("Gameplay.InteractEntitySystem")

function Cls:Ctor()
    self.m_nextInteractEntityID = 1
    ---@type table<number,BP_InteractableBase_C>
    self.m_instanceID2Entity = {}
    ---@type table<number,BP_InteractEntityComponent_C>
    self.m_instanceID2Comp = {}

    self.m_behaviourHandlers = {}

    ---@type table[] 按到达顺序排列的待处理请求
    self.m_pendingRequests = {}
    ---@type table[] 按到达顺序排列的待处理请求
    self.m_invokingRequests = {}
    ---@type table<string, table> key = PlayerKey .. "_" .. EntityInstanceID
    self.m_requestMap = {}
    ---@type Gameplay.InteractEntitySystem.BehaviourExecutionTask[]
    self.m_executionTasks = {}
    --
    self.m_isServer = UGCGameSystem.IsServer()
end

---@private
function Cls:AllocInstanceID()
    local ret = self.m_nextInteractEntityID
    self.m_nextInteractEntityID = ret + 1
    return ret
end

---@public
---@param entityActor BP_InteractableBase_C
---@param entityComp BP_InteractEntityComponent_C
---@return number
function Cls:ServerRegisterEntity(entityActor,entityComp)
    if not UGCGameSystem.IsServer() then
        GameplayUtils.Exception("InteractEntitySystem.ServerRegisterEntity: Cannot call on client !!!")
        return 0
    end
    local instanceID = self:AllocInstanceID()
    self.m_instanceID2Entity[instanceID] = entityActor
    self.m_instanceID2Comp[instanceID] = entityComp
    return instanceID
end

---@public
function Cls:ServerUnregisterEntity(instanceID)
    self.m_instanceID2Entity[instanceID] = nil
    self.m_instanceID2Comp[instanceID] = nil
end

---@public
---@param entityActor BP_InteractableBase_C
---@param entityComp BP_InteractEntityComponent_C
---@return number
function Cls:ClientRegisterEntity(instanceID,entityActor,entityComp)
    self.m_instanceID2Entity[instanceID] = entityActor
    self.m_instanceID2Comp[instanceID] = entityComp
end

---@public
function Cls:ClientUnregisterEntity(instanceID)
    self.m_instanceID2Entity[instanceID] = nil
    self.m_instanceID2Comp[instanceID] = nil
end

---@public
---@return BP_InteractableBase_C
function Cls:GetInteractActorByInstanceID(instanceID)
    local ret = self.m_instanceID2Entity[instanceID]
    return ret
end

---@public
---@return BP_InteractEntityComponent_C
function Cls:GetInteractComponentByInstanceID(instanceID)
    local ret = self.m_instanceID2Comp[instanceID]
    return ret
end

---@protected
function Cls:OnTick(deltaTime)
    if #self.m_pendingRequests > 0 then
        local requests = self.m_pendingRequests
        self.m_invokingRequests = requests
        self.m_pendingRequests = {}
        for _, request in ipairs(requests) do
            local key = tostring(request.PlayerKey) .. "_" .. tostring(request.EntityInstanceID)
            if self.m_requestMap[key] == request then
                self.m_requestMap[key] = nil
                self:_ProcessInteractRequest(request)
            end
        end
    end
    if #self.m_executionTasks > 0 then
        local taskCnt = #self.m_executionTasks
        for i = 1,taskCnt do
            local task = self.m_executionTasks[i]
            if task.executingStage == EBehaviourExecutionTaskStage.PreExecute then--预执行阶段
                for bIdx = 1,#task.orderedBehaviours do
                    task.orderedBehaviours[bIdx]:PreExecute(task.playerKey)
                end
                task.executingStage = EBehaviourExecutionTaskStage.Exccute
            end
        end
        for i = 1,taskCnt do
            local task = self.m_executionTasks[i]
            if task.executingStage == EBehaviourExecutionTaskStage.Exccute then--正式执行阶段
                if self:_ProcessInteractTask(task) then
                    task.executingStage = EBehaviourExecutionTaskStage.PostExecute
                end
            end
        end
        for i = taskCnt,1,-1 do
            local task = self.m_executionTasks[i]
            if task.executingStage == EBehaviourExecutionTaskStage.PostExecute then--结束执行
                table.remove(self.m_executionTasks,i)
                --
                for bIdx = 1,#task.orderedBehaviours do
                    task.orderedBehaviours[bIdx]:PostExecute(task.playerKey)
                end
                --执行回调
                local cbObj = task.callbackObj
                local cbFunc = task.callbackFunc
                cbFunc(cbObj, task.playerKey, task.instanceID, EInteractEntityErrCode.None, nil)
                --
            end
        end
    end
end

---@public 服务端处理交互请求
---@param request Gameplay.InteractEntitySystem.InteractionRequest
function Cls:ServerHandleInteractRequest(request)
    if not request then
        return
    end

    if not request.PlayerKey or not request.EntityInstanceID or not request.CallbackObj or not request.CallbackFunc then
        self:Exception("InteractEntitySystem.ServerHandleInteractRequest: 请求数据不完整")
        return
    end

    self:HandleInteractRequest(request)
end

---@public 服务端中止交互
function Cls:ServerInterruptInteractRequest(playerKey,entityInstanceID)
    local interruptSuccessful = false
    local key = tostring(playerKey) .. "_" .. tostring(entityInstanceID)
    self.m_requestMap[key] = nil
    for i = #self.m_pendingRequests,1,-1 do
        if self.m_pendingRequests[i].EntityInstanceID == entityInstanceID
                and self.m_pendingRequests[i].PlayerKey == playerKey
        then
            table.remove(self.m_pendingRequests,i)
            interruptSuccessful = true
        end
    end
    for i = #self.m_invokingRequests,1,-1 do
        if self.m_invokingRequests[i].EntityInstanceID == entityInstanceID
                and self.m_invokingRequests[i].PlayerKey == playerKey
        then
            table.remove(self.m_invokingRequests,i)
            interruptSuccessful = true
        end
    end
    for i = #self.m_executionTasks,1,-1 do
        local task = self.m_executionTasks[i]
        if task.playerKey == playerKey and task.instanceID == entityInstanceID then
            if task.waitingTaskIndex > 0 then
                local waitingBehaviour = task.orderedBehaviours[task.waitingTaskIndex]
                if waitingBehaviour then
                    waitingBehaviour:OnInterrupt(playerKey)
                end
            end
            interruptSuccessful = true
            table.remove(self.m_executionTasks,i)
        end
    end
    return interruptSuccessful
end

---@private 处理交互请求
function Cls:HandleInteractRequest(request)
    local key = tostring(request.PlayerKey) .. "_" .. tostring(request.EntityInstanceID)
    self.m_requestMap[key] = request
    table.insert(self.m_pendingRequests, request)
end

---@private
---@param entityInstanceID
---@param behavioursList BP_InteractEntityBehaviourComponent_C[]
---@param skipBehaviours FGameplayTag[]
function Cls:_HandleSkippedBehaviours(entityInstanceID,behavioursList,skipBehaviours)
    if type(skipBehaviours) == "table" and #skipBehaviours > 0 then
        local filteredBehaviours = {}
        local skipBehavioursMap = {}
        for k,v in pairs(skipBehaviours) do
            skipBehavioursMap[v.TagName] = true
        end
        for i = 1,#behavioursList do
            if skipBehavioursMap[behavioursList[i].BehaviourTag.TagName]
            then
                GameplayUtils.Print("InteractEntitySystem._HandleSkippedBehaviours: 交互实体",entityInstanceID,"将跳过行为 ",behavioursList[i].BehaviourTag.TagName)
            else
                table.insert(filteredBehaviours,behavioursList[i])
            end
        end
        return filteredBehaviours
    else
        return behavioursList
    end
end

---@private
---@param request Gameplay.InteractEntitySystem.InteractionRequest
function Cls:_ProcessInteractRequest(request)
    local playerKey = request.PlayerKey
    local entityInstanceID = request.EntityInstanceID
    --客户端无法通过GetInteractComponentByInstanceID获取到组件，所以将通过具名参数传进来
    local entityInteractComp = request.EntityInteractComp or self:GetInteractComponentByInstanceID(entityInstanceID)
    local cbObj = request.CallbackObj
    local cbFunc = request.CallbackFunc

    if not entityInteractComp or not UE.IsValid(entityInteractComp) then
        cbFunc(cbObj, playerKey, entityInstanceID, EInteractEntityErrCode.FailInvalid, "交互实体已失效")
        return
    end
    local canPlayerInteract,playerInteractErr = entityInteractComp:CanPlayerInteract(playerKey)
    if not canPlayerInteract then
        cbFunc(cbObj, playerKey, entityInstanceID, playerInteractErr, "交互实体拒绝与当前玩家交互")
        return
    end
    --获取行为合集
    ---@type BP_InteractEntityBehaviourComponent_C[]
    local behaviours = entityInteractComp:GetBehaviours()
    if #behaviours <= 0 then
        cbFunc(cbObj, playerKey, entityInstanceID, EInteractEntityErrCode.None, "未定义任何行为")
        return
    end
    --过滤需要跳过的行为
    behaviours = self:_HandleSkippedBehaviours(entityInstanceID,behaviours,request.skipBehaviours)
    --
    if self.m_isServer and not request.IgnoreConditionChecking then
        --只有服务端需要检查行为的条件是否满足
        for k,v in pairs(behaviours) do
            local valid,errCode,errMsg = v:CanExecute(playerKey)
            if not valid then
                local behaviourTag = v.BehaviourTag.TagName
                local msg = errMsg or table.concat({"行为",behaviourTag,"未满足执行条件！"})
                return cbFunc(cbObj, playerKey, entityInstanceID, EInteractEntityErrCode.FailUnavailable,msg)
            end
        end
    end
    --按照执行顺序排序
    table.sort(behaviours,function(a,b) return a.ExecutionOrder < b.ExecutionOrder end)
    ---@type Gameplay.InteractEntitySystem.BehaviourExecutionTask
    local task = {
        orderedBehaviours = behaviours,
        interactComponent = entityInteractComp,
        playerKey = playerKey,
        instanceID = entityInstanceID,
        callbackObj = cbObj,
        callbackFunc = cbFunc,
        waitingTaskIndex = 0,
        waitingStartTime = 0,
        executingStage = EBehaviourExecutionTaskStage.PreExecute
    }
    GameplayUtils.Print("InteractEntitySystem._ProcessInteractRequest: 为交互实体",entityInstanceID,"创建执行行为任务 ",#behaviours)
    table.insert(self.m_executionTasks,task)
end

---@private
---@param task Gameplay.InteractEntitySystem.BehaviourExecutionTask
function Cls:_ProcessInteractTask(task)
    local playerKey = task.playerKey
    local startIndex = 1
    if task.waitingTaskIndex > 0 then
        local behaviour = task.orderedBehaviours[task.waitingTaskIndex]
        local nextTask = false
        if behaviour:IsFinished() then
            nextTask = true
        else
            if UGCGameSystem.GetServerTimeSec() - task.waitingStartTime > 5 then
                nextTask = true--超时强行完成
            end
        end
        if nextTask then
            startIndex = task.waitingTaskIndex + 1
            task.waitingTaskIndex = 0
        else
            return false--任务继续中断
        end
    end
    local behaviourNum = #task.orderedBehaviours
    if startIndex > behaviourNum then
        return true
    end
    for i = startIndex,behaviourNum do
        local behaviour = task.orderedBehaviours[i]
        behaviour:Execute(playerKey)
        local isFinished = behaviour:IsFinished()
        if isFinished then

        else
            if behaviour.bWaiting then
                task.waitingTaskIndex = i--等待行为完成
                task.waitingStartTime = UGCGameSystem.GetServerTimeSec()
                return false--任务执行中断
            else
                --未完成也不需要等待前一个行为，强制算作执行完成
            end
        end
    end
    return true--任务完成
end


---@public
---@return number EInteractEntityErrCode
function Cls:ClientHandleInteractRequest(request)
    if not request then
        return
    end

    if not request.PlayerKey or not request.EntityInstanceID or not request.CallbackObj or not request.CallbackFunc then
        self:Exception("InteractEntitySystem.ClientHandleInteractRequest: 请求数据不完整")
        return
    end

    local playerKey = request.PlayerKey
    local entityInstanceID = request.EntityInstanceID
    --客户端无法通过GetInteractComponentByInstanceID获取到组件，所以将通过具名参数传进来
    local entityInteractComp = request.EntityInteractComp or self:GetInteractComponentByInstanceID(entityInstanceID)
    local cbObj = request.CallbackObj
    local cbFunc = request.CallbackFunc
    --获取行为合集
    ---@type BP_InteractEntityBehaviourComponent_C[]
    local behaviours = entityInteractComp:GetBehaviours()
    if #behaviours <= 0 then
        cbFunc(cbObj, playerKey, entityInstanceID, EInteractEntityErrCode.None, "未定义任何行为")
        return
    end
    --过滤需要跳过的行为
    behaviours = self:_HandleSkippedBehaviours(entityInstanceID,behaviours,request.skipBehaviours)
    --按照执行顺序排序
    table.sort(behaviours,function(a,b) return a.ExecutionOrder < b.ExecutionOrder end)
    ---@type Gameplay.InteractEntitySystem.BehaviourExecutionTask
    local task = {
        orderedBehaviours = behaviours,
        interactComponent = entityInteractComp,
        playerKey = playerKey,
        instanceID = entityInstanceID,
        callbackObj = cbObj,
        callbackFunc = cbFunc,
        waitingTaskIndex = 0,
        waitingStartTime = 0,
        executingStage = EBehaviourExecutionTaskStage.PreExecute
    }
    GameplayUtils.Print("InteractEntitySystem.ClientHandleInteractRequest: 为交互实体",entityInstanceID,"创建执行行为任务 ",#behaviours)
    table.insert(self.m_executionTasks,task)
end

---@private
function Cls:Log(...)
    if self.m_isServer then
        GameplayUtils.Print("InteractEntitySystem.Server: ",...)
    else
        GameplayUtils.Print("InteractEntitySystem.Client: ",...)
    end
end

---@private
function Cls:Exception(...)
    if self.m_isServer then
        GameplayUtils.Exception("InteractEntitySystem.Server: ",...)
    else
        GameplayUtils.Exception("InteractEntitySystem.Client: ",...)
    end
end

return Cls