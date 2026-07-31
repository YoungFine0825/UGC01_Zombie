---@class BP_PlayerInteractEntityComponent_C:ActorComponent
local BP_PlayerInteractEntityComponent = {}
 ---玩家侧负责与可交互实体系统的通信的组件，挂在PlayerController上
--[[--]]
function BP_PlayerInteractEntityComponent:ReceiveBeginPlay()
    BP_PlayerInteractEntityComponent.SuperClass.ReceiveBeginPlay(self)
    self.m_isServer = UGCGameSystem.IsServer()
    ---@type UGCPlayerController_C
    self.m_owner = UGCActorComponentUtility.GetOwner(self)
    ---@type table<number,BP_InteractEntityComponent_C>
    self.m_enteredInteractEntities = {}
    ---@type number[] 按照优先级排序后的实体列表
    self.m_sortedEnteredInteractEntitiesIdList = {}
    ---当前优先级最高的可交互实体，仅客户端
    self.m_curFocusedEntityID = 0
    self.m_sentInteractRequestEntities = {}
    self.m_interactUIWeakptr = nil
    ---@type table<number,boolean> 本帧内自动交互实体的去重队列
    self.m_pendingAutoInteractQueue = {}
    --前后端都监听
    GameplaySystem.EventSystem:Listen(GameplayEvents.Global.OnPlayerEnterInteractEntity,self,self.OnPlayerEnterInteractEntity)
    GameplaySystem.EventSystem:Listen(GameplayEvents.Global.OnPlayerLeaveInteractEntity,self,self.OnPlayerLeaveInteractEntity)
    if UGCGameSystem.IsServer() then
        GameplaySystem.EventSystem:Listen(GameplayEvents.Server.OnPlayerAliveStateChanged,self,self.OnServerPlayerAliveStateChanged)
    else
        GameplaySystem.EventSystem:Listen(GameplayEvents.Client.OnLocalPlayerAliveStateChanged,self,self.OnLocalPlayerAliveStateChanged)
        GameplaySystem.EventSystem:Listen(GameplayEvents.Client.OnLocalPlayerInvokeInteraction,self,self.OnLocalPlayerInvokeInteraction)
    end
end


--[[--]]
function BP_PlayerInteractEntityComponent:ReceiveTick(DeltaTime)
    BP_PlayerInteractEntityComponent.SuperClass.ReceiveTick(self, DeltaTime)
    if not self.m_isServer then
        self:_FlushPendingAutoInteractQueue()
    end
end


--[[--]]
function BP_PlayerInteractEntityComponent:ReceiveEndPlay()
    BP_PlayerInteractEntityComponent.SuperClass.ReceiveEndPlay(self)
    GameplaySystem.EventSystem:UnlistenAll(self)
    self.m_pendingAutoInteractQueue = nil
    self.m_owner = nil
    --if not UGCGameSystem.IsServer() then
    --    UGCGenericMessageSystem.UnListenMessage(self,GameplayEvents.Client.OnLocalPlayerInvokeInteraction)
    --end
    self:DestroyInteractionUIWidget()
end

---@private
function BP_PlayerInteractEntityComponent:GetAvailableServerRPCs()
    return "RPC_Server_RequestInteract","RPC_Server_RequestInterruptInteraction"
end

---@private
function BP_PlayerInteractEntityComponent:GetAvailableClientRPCs()
    return "RPC_Client_ResponseInteract","RPC_Client_RequestInterruptInteraction"
end

---@protected 玩家进入可交互实体
---@param playerController UGCPlayerController_C
---@param interactEntityComp BP_InteractEntityComponent_C
---@param interactEntityInstanceID number
function BP_PlayerInteractEntityComponent:OnPlayerEnterInteractEntity(playerController,interactEntityComp,interactEntityInstanceID)
    if playerController ~= self.m_owner then
        GameplayUtils.Exception("[InteractEntity] OnPlayerEnterInteractEntity return: playerController不是自身, instanceID=",tostring(interactEntityInstanceID))
        return
    end


    if self.m_enteredInteractEntities[interactEntityInstanceID] then
        GameplayUtils.Exception("[InteractEntity] OnPlayerEnterInteractEntity return: 实体已在列表内, instanceID=",tostring(interactEntityInstanceID))
        return
    end
    local isServer = UGCGameSystem.IsServer()
    if isServer then
        self.m_enteredInteractEntities[interactEntityInstanceID] = interactEntityComp
        GameplayUtils.Print("[InteractEntity] OnPlayerEnterInteractEntity 服务端记录成功, instanceID=",tostring(interactEntityInstanceID))
        if not interactEntityComp.bNeedPlayerConfirm then--对于不需要玩家的交互，服务器直接处理了
            GameplayUtils.Print("[InteractEntity] OnPlayerEnterInteractEntity 不需要玩家确认，加入自动交互队列, instanceID=",tostring(interactEntityInstanceID))
            --self.m_pendingAutoInteractQueue[interactEntityInstanceID] = true
            self:RPC_Server_RequestInteract(
                    UGCGameSystem.GetPlayerKeyByPlayerController(playerController),
                    interactEntityInstanceID,
                    0
            )
        end
    else
        if interactEntityComp.bNeedPlayerConfirm then--客户端处理需要玩家确认的交互
            self.m_enteredInteractEntities[interactEntityInstanceID] = interactEntityComp
            self:ClientResortEnteredEntities()
            GameplayUtils.Print("[InteractEntity] OnPlayerEnterInteractEntity 客户端手动交互, instanceID=",tostring(interactEntityInstanceID))
            if self:ClientShouldChangeFocusedInteractEntity() then
                self:ClientChangeFocusedInteractEntity(self.m_sortedEnteredInteractEntitiesIdList[1])
                self:ClientUpdateInteractionUIWidget()
                GameplayUtils.Print("[InteractEntity] OnPlayerEnterInteractEntity 切换焦点并创建UI, newFocusID=",tostring(self.m_curFocusedEntityID))
            end
        end
    end
end

---@protected  玩家离开可交互实体
---@param playerController UGCPlayerController_C
---@param interactEntityComp BP_InteractEntityComponent_C
---@param interactEntityInstanceID number
function BP_PlayerInteractEntityComponent:OnPlayerLeaveInteractEntity(playerController,interactEntityComp,interactEntityInstanceID)
    if playerController ~= self.m_owner then
        GameplayUtils.Exception("[InteractEntity] OnPlayerLeaveInteractEntity return: playerController不是自身, instanceID=" .. tostring(interactEntityInstanceID))
        return
    end
    if not self.m_enteredInteractEntities[interactEntityInstanceID] then
        GameplayUtils.Exception("[InteractEntity] OnPlayerLeaveInteractEntity return: 实体不在列表内, instanceID=" .. tostring(interactEntityInstanceID))
        return
    end
    self.m_enteredInteractEntities[interactEntityInstanceID] = nil
    local isClient = not UGCGameSystem.IsServer()
    if isClient then
        self:ClientResortEnteredEntities()
        GameplayUtils.Print("[InteractEntity] OnPlayerLeaveInteractEntity 客户端重新排序, instanceID=" .. tostring(interactEntityInstanceID))
        if self:ClientShouldChangeFocusedInteractEntity() then
            self:ClientChangeFocusedInteractEntity(self.m_sortedEnteredInteractEntitiesIdList[1])
            self:ClientUpdateInteractionUIWidget()
            GameplayUtils.Print("[InteractEntity] OnPlayerLeaveInteractEntity 切换焦点并更新UI, newFocusID=" .. tostring(self.m_curFocusedEntityID))
        end
    end
end

---@private
function BP_PlayerInteractEntityComponent:OnServerPlayerAliveStateChanged(playerController,newState,previousState)
    if self.m_owner ~= playerController then
        return
    end
end

---@private
function BP_PlayerInteractEntityComponent:OnLocalPlayerAliveStateChanged(newState)
    local playerController = self.m_owner
    if newState == EPlayerAliveState.Alive then
        --复活后尝试恢复客户端交互界面
        self:ClientUpdateInteractionUIWidget()
    elseif newState == EPlayerAliveState.Dying or newState == EPlayerAliveState.Dead then
        --死亡后隐藏交互界面
        self:ClientShowInteractionUIWidget(false)
    end
end

---@private 客户端发来交互请求
function BP_PlayerInteractEntityComponent:RPC_Server_RequestInteract(playerKey,entityInstanceID,clientSendTime)
    GameplayUtils.Print("BP_PlayerInteractEntityComponent.RPC_Server_RequestInteract: 收到玩家",playerKey,"与实体",entityInstanceID,"交互的请求！")

    if not self.m_owner then
        GameplayUtils.Print("BP_PlayerInteractEntityComponent.RPC_Server_RequestInteract: 玩家",playerKey,"未拥有有效PlayerController!")
        self:ResponseToClient(playerKey,entityInstanceID,EInteractEntityErrCode.FailInvalid,"玩家未拥有有效PlayerController！")
        return
    end

    local playerAliveState = GameplaySystem.PlayerSystem:GetPlayerAliveStateByPlayerKey(playerKey)
    if playerAliveState ~= EPlayerAliveState.Alive then
        GameplayUtils.Print("BP_PlayerInteractEntityComponent.RPC_Server_RequestInteract: 玩家",playerKey,"已死亡！!")
        self:ResponseToClient(playerKey,entityInstanceID,EInteractEntityErrCode.FailPlayerInvalid,"玩家已死亡！")
        return--玩家已死亡
    end

    -- 查表：玩家是否已进入该实体的触发区域
    if not self.m_enteredInteractEntities[entityInstanceID] then
        GameplayUtils.Print("BP_PlayerInteractEntityComponent.RPC_Server_RequestInteract: 实体",entityInstanceID,"不在进入列表内，尝试重校验...")
        -- 二次校验：直接检测玩家是否与实体发生重叠
        if not self:_ServerVerifyPlayerOverlapWithEntity(playerKey, entityInstanceID) then
            self:ResponseToClient(playerKey,entityInstanceID,EInteractEntityErrCode.FailNotOverlapped,"玩家未发生与交互实体发生碰撞！")
            return
        end
        -- 重校验通过，补登记进列表
        local entityComp = GameplaySystem.InteractEntitySystem:GetInteractComponentByInstanceID(entityInstanceID)
        self.m_enteredInteractEntities[entityInstanceID] = entityComp
        GameplayUtils.Print("BP_PlayerInteractEntityComponent.RPC_Server_RequestInteract: 重校验通过，补登记实体",entityInstanceID)
    end

    ---@type Gameplay.InteractEntitySystem.InteractionRequest
    local request = {
        PlayerKey        = playerKey,
        EntityInstanceID = entityInstanceID,
        CallbackObj      = self,
        CallbackFunc     = self.OnServerInteractCompleted,
    }
    GameplaySystem.InteractEntitySystem:ServerHandleInteractRequest(request)
end

---@private 服务端二次校验玩家是否与实体发生重叠
---@param playerKey number
---@param entityInstanceID number
---@return boolean
function BP_PlayerInteractEntityComponent:_ServerVerifyPlayerOverlapWithEntity(playerKey, entityInstanceID)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    if not playerPawn or not UE.IsValid(playerPawn) then
        GameplayUtils.Print("BP_PlayerInteractEntityComponent._ServerVerifyPlayerOverlapWithEntity: 玩家",playerKey,"的Pawn无效")
        return false
    end

    local entityComp = GameplaySystem.InteractEntitySystem:GetInteractComponentByInstanceID(entityInstanceID)
    if not entityComp or not UE.IsValid(entityComp) then
        GameplayUtils.Print("BP_PlayerInteractEntityComponent._ServerVerifyPlayerOverlapWithEntity: 实体",entityInstanceID,"的组件无效")
        return false
    end

    local triggerComp = entityComp:GetInteractTriggerComponent()
    if not triggerComp or not UE.IsValid(triggerComp) then
        GameplayUtils.Print("BP_PlayerInteractEntityComponent._ServerVerifyPlayerOverlapWithEntity: 实体",entityInstanceID,"的Trigger组件无效")
        return false
    end

    -- 用玩家胶囊体做实时物理重叠查询，不依赖事件缓存
    local playerCapsule = playerPawn:GetRootComponent()
    if not playerCapsule or not UE.IsValid(playerCapsule) then
        GameplayUtils.Print("BP_PlayerInteractEntityComponent._ServerVerifyPlayerOverlapWithEntity: 玩家",playerKey,"的根组件无效")
        return false
    end

    local OutActors = {}
    local bOverlapped = UKismetSystemLibrary.ComponentOverlapActors(
        playerCapsule,
        playerCapsule:K2_GetComponentTransform(),
        { EObjectTypeQuery.ObjectTypeQuery3 },  -- Pawn
        nil,
        {},
        OutActors
    )

    local triggerOwner = entityComp:GetOwnerActor()
    local bOverlapping = false
    if bOverlapped then
        for _, actor in ipairs(OutActors) do
            if actor == triggerOwner then
                bOverlapping = true
                break
            end
        end
    end

    GameplayUtils.Print("BP_PlayerInteractEntityComponent._ServerVerifyPlayerOverlapWithEntity: 重校验结果=",tostring(bOverlapping)," | playerKey=",playerKey," | entityID=",entityInstanceID)
    return bOverlapping
end

---@public
---@param request Gameplay.InteractEntitySystem.InteractionRequest
function BP_PlayerInteractEntityComponent:ServerHandleInteractRequest(request)
    if not UGCGameSystem.IsServer() then
        return
    end
    if request.CallbackFunc == nil then
        request.CallbackObj = self
        request.CallbackFunc = self.OnServerInteractCompleted
    end
    GameplaySystem.InteractEntitySystem:ServerHandleInteractRequest(request)
end

---@private 交互系统执行交互请求完毕
function BP_PlayerInteractEntityComponent:OnServerInteractCompleted(playerKey, entityInstanceID, errCode, errMessage)
    --
    GameplayUtils.Print("BP_PlayerInteractEntityComponent.OnServerInteractCompleted: 收到交互结果 | playerKey=", tostring(playerKey), " | entityInstanceID=", tostring(entityInstanceID), " | errCode=", tostring(errCode), " | errMessage=", tostring(errMessage))
    --服务端广播交互完成的事件
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnPlayerInteractionCompleted, playerKey, entityInstanceID, errCode, errMessage)
    --
    if errCode == EInteractEntityErrCode.None then
        --交互成功通知所有客户端
        self:ResponseToAllClients(playerKey, entityInstanceID, errCode, errMessage)
    else
        --交互失败只通知发起交互的客户端
        self:ResponseToClient(playerKey, entityInstanceID, errCode, errMessage)
    end
end

---@private
function BP_PlayerInteractEntityComponent:ResponseToClient(playerKey,entityInstanceID,errCode,errMessage)
    if not UGCGameSystem.IsServer() then
        return
    end
    --发送交互结果给客户端
    UnrealNetwork.CallUnrealRPC(
        self.m_owner,
        self,
        "RPC_Client_ResponseInteract",
        playerKey,
        entityInstanceID,
        errCode,
        errMessage
    )
end

---@private
function BP_PlayerInteractEntityComponent:ResponseToAllClients(playerKey,entityInstanceID,errCode,errMessage)
    if not UGCGameSystem.IsServer() then
        return
    end
    --逐个发送消息给客户端
    for k,pc in pairs(UGCGameSystem.GetAllPlayerController()) do
        UnrealNetwork.CallUnrealRPC(
                pc,
                pc.PlayerInteractEntityComponent,
                "RPC_Client_ResponseInteract",
                playerKey,
                entityInstanceID,
                errCode,
                errMessage
        )
    end
end

---@private 客户端收到服务端处理交互的结果
function BP_PlayerInteractEntityComponent:RPC_Client_ResponseInteract(playerKey,entityInstanceID,errCode,errMessage)
    --清除记录
    self.m_sentInteractRequestEntities[entityInstanceID] = nil
    --广播客户端事件，通知交互实体结果
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Client.OnLocalPlayerReceiveInteractionResult, playerKey, entityInstanceID, errCode,errMessage)
    --
    if errCode == EInteractEntityErrCode.None then
        GameplayUtils.Print("[InteractEntity] 交互成功 | playerKey=", tostring(playerKey), " | entityInstanceID=", tostring(entityInstanceID))
    else
        GameplayUtils.Print("[InteractEntity] 交互失败 | playerKey=", tostring(playerKey), " | entityInstanceID=", tostring(entityInstanceID), " | errCode=", tostring(errCode), " | errMessage=", tostring(errMessage))
    end
end

---@protected 玩家确认执行交互
function BP_PlayerInteractEntityComponent:OnLocalPlayerInvokeInteraction(interactEntityInstanceID)
    if interactEntityInstanceID ~= self.m_curFocusedEntityID then
        GameplayUtils.Exception("BP_PlayerInteractEntityComponent.OnLocalPlayerInvokeInteraction: 玩家企图交互的实体",interactEntityInstanceID,"不是当下优先级最高的实体！")
        return--实体ID无法匹配上
    end
    GameplayUtils.Exception("BP_PlayerInteractEntityComponent.OnLocalPlayerInvokeInteraction: 玩家请求与实体",interactEntityInstanceID,"交互！")
    self:ClientSendInteractMessage(interactEntityInstanceID)
end

---@protected
function BP_PlayerInteractEntityComponent:ClientSendInteractMessage(interactEntityInstanceID)
    local sentTime = self.m_sentInteractRequestEntities[interactEntityInstanceID] or 0
    local curTime = UGCGameSystem.GetServerTimeSec()
    if sentTime > 0 and curTime - sentTime < 5 then
        return
    end
    local playerAliveState = GameplaySystem.PlayerSystem:GetPlayerAliveStateByController(self.m_owner)
    if playerAliveState ~= EPlayerAliveState.Alive then
        return--玩家已死亡
    end
    self.m_sentInteractRequestEntities[interactEntityInstanceID] = curTime
    UnrealNetwork.CallUnrealRPC(
            self.m_owner,
            self,
            "RPC_Server_RequestInteract",
            UGCGameSystem.GetPlayerKeyByPlayerController(self.m_owner),
            interactEntityInstanceID,
            UGCGameSystem.GetServerTimeSec()
    )
end

---@private 服务端收到中断交互请求
function BP_PlayerInteractEntityComponent:RPC_Server_RequestInterruptInteraction(playerKey,entityInstanceID)
    GameplayUtils.Print("BP_PlayerInteractEntityComponent.RPC_Server_RequestInterruptInteraction: 收到玩家",playerKey,"请求中止与实体",entityInstanceID,"交互的请求！")
    if not self.m_owner then
        GameplayUtils.Print("BP_PlayerInteractEntityComponent.RPC_Server_RequestInterruptInteraction: 玩家",playerKey,"未拥有有效PlayerController!")
        return
    end
    --执行中断操作
    GameplaySystem.InteractEntitySystem:ServerInterruptInteractRequest(playerKey,entityInstanceID)
    --通知发起交互的客户端中止完成
    UnrealNetwork.CallUnrealRPC(
            self.m_owner,
            self,
            "RPC_Client_RequestInterruptInteraction",
            playerKey,
            entityInstanceID
    )
end

---@private 客户端收到中断交互消息返回
function BP_PlayerInteractEntityComponent:RPC_Client_RequestInterruptInteraction(playerKey,entityInstanceID)
    --清除记录
    self.m_sentInteractRequestEntities[entityInstanceID] = nil
    --广播客户端事件，通知交互实体，交互中止
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Client.OnLocalPlayerInterruptInteractionFinished, playerKey, entityInstanceID)
end

---@private
function BP_PlayerInteractEntityComponent:ClientShouldChangeFocusedInteractEntity()
    local firstEntityID = ( self.m_sortedEnteredInteractEntitiesIdList[1] or 0 )
    return firstEntityID ~= self.m_curFocusedEntityID
end

---@private
function BP_PlayerInteractEntityComponent:ClientChangeFocusedInteractEntity(entityID)
    local instanceID = entityID or 0
    self.m_curFocusedEntityID = instanceID
end

---@public
function BP_PlayerInteractEntityComponent:ClientUpdateInteractionUIWidget()
    local playerState = GameplaySystem.PlayerSystem:GetPlayerAliveStateByController(self.m_owner)
    if playerState ~= EPlayerAliveState.Alive then--玩家生还时客户端才显示交互界面
        return
    end
    if self:GetInteractionUIWidget() == nil then
        self:CreateInteractionUIWidget()
    else
        --
        self:ClientShowInteractionUIWidget(self.m_curFocusedEntityID > 0)
    end
    --通知UI更新实体按钮
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Client.OnLocalPlayerUpdateInteractEntityWidget,self.m_curFocusedEntityID,self)
end

---@private
---@return UUserWidget
function BP_PlayerInteractEntityComponent:GetInteractionUIWidget()
    if self.m_interactUIWeakptr and UGCObjectUtility.IsWeakObjectPtrValid(self.m_interactUIWeakptr) then
        return UGCObjectUtility.GetObjectFromWeakObjectPtr(self.m_interactUIWeakptr)
    end
    return nil
end

---@private
function BP_PlayerInteractEntityComponent:CreateInteractionUIWidget(callback)
    local WidgetPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Game/UIBP/InteractEntity/UGC_InteractMain_UIBP.UGC_InteractMain_UIBP_C')
    UGCWidgetManagerSystem.CreateWidgetAsync(WidgetPath, function(Widget)
        local UISlotName = 'UI.UISlot.MainUISlot_High'
        local ZOrder = 0
        local AnchorData = UGCObjectUtility.NewStruct("AnchorData")
        local Anchors = UGCObjectUtility.NewStruct("Anchors")
        Anchors.Maximum = Vector2D.New(1.0, 1.0)
        Anchors.Minimum = Vector2D.New(0, 0)
        AnchorData.Anchors = Anchors
        UGCWidgetManagerSystem.AddToSlot(Widget,UISlotName, ZOrder, AnchorData)
        UGCWidgetManagerSystem.ShowWidget(Widget)
        self.m_interactUIWeakptr = UGCObjectUtility.MakeWeakObjectPtr(Widget)
        if callback then
            callback()
        end
    end)
end

---@private
function BP_PlayerInteractEntityComponent:DestroyInteractionUIWidget()
    if not self.m_interactUIWeakptr then
        return
    end
    if not UGCObjectUtility.IsWeakObjectPtrValid(self.m_interactUIWeakptr) then
        self.m_interactUIWeakptr = nil
        return
    end
    ---@type UUserWidget
    local widget = UGCObjectUtility.GetObjectFromWeakObjectPtr(self.m_interactUIWeakptr)
    UGCWidgetManagerSystem.RemoveFromSlot(widget)
end

---@public
function BP_PlayerInteractEntityComponent:ClientShowInteractionUIWidget(show)
    local UI = self:GetInteractionUIWidget()
    if UI then
        if show then
            UGCWidgetManagerSystem.ShowWidget(UI)
        else
            UGCWidgetManagerSystem.HideWidget(UI)
        end
    end
end


---@private
function BP_PlayerInteractEntityComponent:ClientResortEnteredEntities()
    local pawn = UGCGameSystem.GetPlayerPawnByPlayerController(self.m_owner)
    local playerLoc = UE.IsValid(pawn) and pawn:K2_GetActorLocation() or nil

    local entries = {}
    for instanceID, comp in pairs(self.m_enteredInteractEntities) do
        local dist = math.huge
        if playerLoc then
            local entityActor = UGCActorComponentUtility.GetOwner(comp)
            if UE.IsValid(entityActor) then
                local entityLoc = entityActor:K2_GetActorLocation()
                dist = UGCMathUtility.VSize(UGCMathUtility.SubtractVector(entityLoc, playerLoc))
            end
        end
        table.insert(entries, {
            InstanceID  = instanceID,
            Priority    = comp.ClientPriority,
            AutoTrigger = not comp.bNeedPlayerConfirm,
            Distance    = dist,
        })
    end

    if #entries <= 0 then
        self.m_sortedEnteredInteractEntitiesIdList = {}
        return
    end

    table.sort(entries, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
        if a.Distance ~= b.Distance then
            return a.Distance < b.Distance
        end
        return a.InstanceID < b.InstanceID
    end)

    self.m_sortedEnteredInteractEntitiesIdList = {}
    for _, entry in ipairs(entries) do
        if not entry.AutoTrigger then
            table.insert(self.m_sortedEnteredInteractEntitiesIdList, entry.InstanceID)
        end
    end
end

---@public
function BP_PlayerInteractEntityComponent:ClientGetCurFocusedEntityID()
    return self.m_curFocusedEntityID
end

---@private 下一帧发送本帧积攒的自动交互请求（去重）
function BP_PlayerInteractEntityComponent:_FlushPendingAutoInteractQueue()
    if not self.m_pendingAutoInteractQueue or next(self.m_pendingAutoInteractQueue) == nil then
        return
    end
    local sendCount = 0
    for instanceID, _ in pairs(self.m_pendingAutoInteractQueue) do
        self:ClientSendInteractMessage(instanceID)
        sendCount = sendCount + 1
    end
    if sendCount > 0 then
        GameplayUtils.Print("BP_PlayerInteractEntityComponent._FlushPendingAutoInteractQueue: 本帧发送了", sendCount, "个自动交互请求")
    end
    self.m_pendingAutoInteractQueue = {}
end

return BP_PlayerInteractEntityComponent