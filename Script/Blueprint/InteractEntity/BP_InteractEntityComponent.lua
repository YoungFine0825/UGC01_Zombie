---@class BP_InteractEntityComponent_C:ActorComponent
---@field TriggerComponentName FString
---@field bNeedPlayerConfirm bool
---@field ClientPriority int32
---@field CooldownTime float
---@field TotalInteractTimes int32
---@field PlayerInteractTimes int32
---@field UIButtonLabel FString
---@field UITipText FString
---@field InstanceID int32
--Edit Below--
---@type BP_InteractEntityComponent_C
local BP_InteractEntityComponent = {}

--BP_InteractEntityComponent.InstanceID = 0
 
--[[--]]
function BP_InteractEntityComponent:ReceiveBeginPlay()
    GameplayUtils.Print("BP_InteractEntityComponent.ReceiveBeginPlay！！！")
    --
    if BP_InteractEntityComponent.SuperClass then
        BP_InteractEntityComponent.SuperClass.ReceiveBeginPlay(self)
    end
    --
    ---@type table<number,boolean> 当前进入的玩家，前后端都有
    self.m_overlappedPlayerKeys = {}
    ---@type table<number,number> 当前实体玩家分别交互成功的次数。服务端记录通过RPC更新给客户端
    self.m_playerInteractedTimes = {}
    ---@type table<number,number> 当前实体玩家分别最近一次交互成功的时间。服务端记录通过RPC更新给客户端
    self.m_playerInteractedTime = {}
    ---@type boolean
    self.m_interactable = true
    ---@type BP_InteractEntityBehaviourComponent_C[]
    self.m_behaviours = {}
    --
    self.m_isInited = false
    --
    ---@type BP_InteractableBase_C
    self.m_owner = nil
    --
    self:InitComponent()
end

---@public
function BP_InteractEntityComponent:InitComponent()
    if self.m_isInited then
        return
    end
    ---@type BP_InteractableBase_C
    local owner = UGCActorComponentUtility.GetOwner(self)
    if owner == nil then
        GameplayUtils.Exception("BP_InteractEntityComponent.InitComponent: 获取Owner失败，退出初始化！！！")
        return
    end
    --
    self.m_owner = owner
    --
    local primCompClass = UGCObjectUtility.FindClass("/Script/Engine.PrimitiveComponent")
    ---@type UPrimitiveComponent
    local triggerComp = GameplayUtils.GetComponentByName(owner,self.TriggerComponentName,primCompClass)
    if triggerComp then
        triggerComp.OnComponentBeginOverlap:Add(self.OnComponentBeginOverlap, self)
        triggerComp.OnComponentEndOverlap:Add(self.OnComponentEndOverlap, self)
    else
        GameplayUtils.Exception("BP_InteractEntityComponent.InitComponent: 当前Owner不存在名为",self.TriggerComponentName,"的PrimitiveComponent组件！")
    end
    self.m_triggerComp = triggerComp
    --
    self:CollectBehaviourComponents()
    --
    local isServer = owner:HasAuthority()
    self.m_isServer = isServer
    if isServer then
        self:OnBeginPlayOnServer()
    else
        self:OnBeginPlayOnClient()
    end
    --
    GameplaySystem.EventSystem:Listen(GameplayEvents.Server.OnPlayerInteractionCompleted, self, self.OnServerPlayerInteractionCompleted)
    GameplaySystem.EventSystem:Listen(GameplayEvents.Client.OnLocalPlayerReceiveInteractionResult, self, self.OnLocalPlayerReceiveInteractionResult)
    --
    self.m_isInited = true
end

---@return BP_Interact_SodaMachine_C
function BP_InteractEntityComponent:GetOwnerActor()
    if self.m_owner == nil then
        self.m_owner = UGCActorComponentUtility.GetOwner(self)
    end
    return self.m_owner
end

function BP_InteractEntityComponent:ReceiveTick(DeltaTime)
    BP_InteractEntityComponent.SuperClass.ReceiveTick(self, DeltaTime)
    --if not UGCGameSystem.IsServer()then
    --    local ownerLoc = self:GetOwnerActor():K2_GetActorLocation()
    --    ownerLoc.Z = ownerLoc.Z + 320
    --    UGCDebugSystem.DrawDebugString(
    --        ownerLoc,
    --        "ID: " .. tostring(self.InstanceID),
    --        nil,
    --        {A = 1, B = 0, G = 1, R = 1},
    --        0
    --    )
    --end
end

--[[--]]
function BP_InteractEntityComponent:ReceiveEndPlay()
    BP_InteractEntityComponent.SuperClass.ReceiveEndPlay(self)
    --
    if self.m_triggerComp then
        self.m_triggerComp.OnComponentBeginOverlap:Remove(self.OnComponentBeginOverlap, self)
        self.m_triggerComp.OnComponentEndOverlap:Remove(self.OnComponentEndOverlap, self)
        self.m_triggerComp = nil
    end
    --
    if self.m_isServer then
        self:OnEndPlayOnServer()
    else
        self:OnEndPlayOnClient()
    end
    GameplaySystem.EventSystem:UnlistenAll(self)
end

---@protected
function BP_InteractEntityComponent:OnBeginPlayOnServer()
    GameplayUtils.Print("BP_InteractEntityComponent.OnBeginPlayOnServer")
    --服务端向系统注册自身并获取唯一ID
    local owner = self:GetOwnerActor()
    local instanceID = GameplaySystem.InteractEntitySystem:ServerRegisterEntity(owner,self)
    self.InstanceID = instanceID
    --UnrealNetwork.RepLazyProperty(self,"InstanceID")
    GameplayUtils.Print("BP_InteractEntityComponent.OnBeginPlayOnServer: 可交互实体 ",UGCObjectUtility.GetObjectName(owner)," 获得实例ID ",instanceID)
end

---@protected
function BP_InteractEntityComponent:OnEndPlayOnServer()
    GameplaySystem.InteractEntitySystem:ServerUnregisterEntity(self.InstanceID)
end


---@protected
function BP_InteractEntityComponent:OnBeginPlayOnClient()
    GameplayUtils.Print("BP_InteractEntityComponent.OnBeginPlayOnClient")
    ---@type table<number,boolean>
    self.m_triggeredPlayers = {}
    self.m_overrideUITipsText = nil
    self.m_overrideUIBtnText = nil
end

---@protected
function BP_InteractEntityComponent:OnEndPlayOnClient()
    GameplaySystem.InteractEntitySystem:ClientUnregisterEntity(self.InstanceID)
end

---@private
function BP_InteractEntityComponent:ClientShowInstanceID()
    local owner = self:GetOwnerActor()
    if owner and owner.TextRender then
        owner.TextRender:SetText("InstanceID: "..tostring(self.InstanceID))
    end
end

---@private
--function BP_InteractEntityComponent:GetAvailableServerRPCs()
--    return
--end

---@private
--function BP_InteractEntityComponent:GetAvailableClientRPCs()
--    return "RPC_Multicast_AllocInstanceID"
--end

---@private
--function BP_InteractEntityComponent:RPC_Multicast_AllocInstanceID(instanceId)
--    self.InstanceID = instanceId
--    GameplayUtils.Print("BP_InteractEntityComponent.RPC_Multicast_AllocInstanceID: 可交互实体 ",GameplayUtils.GetUEObjClassName(self)," 获得实例ID ",instanceId)
--end

function BP_InteractEntityComponent:GetReplicatedProperties()
    --return {"InstanceID","Lazy"},
    return {"m_playerInteractedTimes","Lazy"},
    {"m_playerInteractedTime","Lazy"},
    {"m_interactable","Lazy"}
end

---@protected
function BP_InteractEntityComponent:OnRep_InstanceID()
    --客户端像交互系统注册自身
    local owner = self:GetOwnerActor()
    GameplaySystem.InteractEntitySystem:ClientRegisterEntity(self.InstanceID,owner,self)
    GameplayUtils.Print("BP_InteractEntityComponent.OnRep_InstanceID: 可交互实体 ",UGCObjectUtility.GetObjectName(owner)," 获得实例ID ",self.InstanceID)
    --UGCDebugSystem.PrintToScreen(UGCObjectUtility.GetObjectName(owner).." InstanceID: " .. tostring(self.InstanceID),{A=1,B=1,G=1,R=1},30)
    self:ClientShowInstanceID()
end

---@public
function BP_InteractEntityComponent:GetInstanceID()
    return self.InstanceID
end

---@private
function BP_InteractEntityComponent:CollectBehaviourComponents()
    local patToBehaviourBase = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/InteractEntity/Behaviours/BP_interactEntityBehaviourComponent.BP_InteractEntityBehaviourComponent_C')
    local behaviourClass = UGCObjectUtility.LoadClass(patToBehaviourBase)
    ---@type BP_InteractEntityBehaviourComponent_C[]
    local comps = UGCActorComponentUtility.GetComponentsByClass(self:GetOwnerActor(), behaviourClass)
    for k,v in pairs(comps) do
        v:OnAwake(self)
        table.insert(self.m_behaviours,v)
    end
end

---@public
---@return BP_InteractEntityBehaviourComponent_C[]
function BP_InteractEntityComponent:GetBehaviours()
    local ret = {}
    for k,v in pairs(self.m_behaviours) do
        table.insert(ret,v)
    end
    return ret
end

---@protected
function BP_InteractEntityComponent:OnComponentBeginOverlap(OverlappedComp, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if self.InstanceID <= 0 then
        GameplayUtils.Exception("BP_InteractEntityComponent.OnComponentBeginOverlap: ",UGCObjectUtility.GetObjectName(self.m_owner),"还未拿到唯一ID")
        --GameplayUtils.Print("BP_InteractEntityComponent.OnComponentBeginOverlap: ",UGCObjectUtility.GetObjectName(self),"return: 还未分配唯一ID")
        return--还未分配唯一ID
    end
    ---@type UGCPlayerState_C
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerPawn(OtherActor)
    if not PlayerState then
        GameplayUtils.Print("BP_InteractEntityComponent.OnComponentBeginOverlap: ",UGCObjectUtility.GetObjectName(self.m_owner),"return: 重叠对象不是玩家, OtherActor=",UGCObjectUtility.GetObjectName(OtherActor))
        return--不是玩家不管
    end
    if PlayerState:GetAliveState() ~= EPlayerAliveState.Alive then
        return--玩家死亡
    end
    local playerKey = UGCGameSystem.GetPlayerKeyByPlayerState(PlayerState)
    if self.m_overlappedPlayerKeys[playerKey] then
        GameplayUtils.Print("BP_InteractEntityComponent.OnComponentBeginOverlap: ",UGCObjectUtility.GetObjectName(self.m_owner),"return: 玩家",playerKey,"已经进入，不可重复进入")
        return--已经进入，不可重复进入
    end
    --无论是否能交互，都记录进入触发区域的玩家，方便恢复交互时通知玩家
    self.m_overlappedPlayerKeys[playerKey] = true
    --
    if not self.m_interactable then
        GameplayUtils.Print("BP_InteractEntityComponent.OnComponentBeginOverlap: ",UGCObjectUtility.GetObjectName(self.m_owner),"return: 当前不可交互, playerKey=",playerKey)
        return--不可以交互
    end
    --
    if not self.m_isServer then--客户端逻辑还要额外检测逻辑
        --
        if not self:CanPlayerInteract(playerKey) then--该玩家不能继续交互了
            GameplayUtils.Print("BP_InteractEntityComponent.OnComponentBeginOverlap: ",UGCObjectUtility.GetObjectName(self.m_owner),"return: 玩家",playerKey,"不能继续交互（次数、CD或未满足条件）")
            return
        end
        --判断实体是否还能继续交互
        if not self:CanEntityInteract() then--实体无法继续交互
            GameplayUtils.Print("BP_InteractEntityComponent.OnComponentBeginOverlap: ",UGCObjectUtility.GetObjectName(self.m_owner),"return: 实体总交互次数已耗尽")
            return
        end
    end
    --
    self:OnPlayerEnter(playerKey)
end

---@private
function BP_InteractEntityComponent:OnPlayerEnter(playerKey)
    --
    if not self.m_isServer then
        UGCWidgetManagerSystem.ShowTipsUI("进入交互实体：",UGCObjectUtility.GetObjectName(self.m_owner))
    end
    --确认一遍是否记录玩家
    if not self.m_overlappedPlayerKeys[playerKey] then
        self.m_overlappedPlayerKeys[playerKey] = true
    end
    --
    local pc = UGCGameSystem.GetPlayerControllerByPlayerKey(playerKey)
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Global.OnPlayerEnterInteractEntity,pc,self,self.InstanceID)
end

---@protected
function BP_InteractEntityComponent:OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if self.InstanceID <= 0 then
        GameplayUtils.Exception("BP_InteractEntityComponent.OnComponentEndOverlap: ",UGCObjectUtility.GetObjectName(self),"还未拿到唯一ID")
        return--还未分配唯一ID
    end
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerPawn(OtherActor)
    if not PlayerState then
        return--不是玩家不管
    end
    local playerKey = UGCGameSystem.GetPlayerKeyByPlayerState(PlayerState)
    self.m_overlappedPlayerKeys[playerKey] = nil
    --
    if not self.m_interactable then
        return
    end
    --
    self:OnPlayerLeave(playerKey)
end

---@protected 玩家离开
function BP_InteractEntityComponent:OnPlayerLeave(playerKey)
    --
    if not self.m_isServer then
        UGCWidgetManagerSystem.ShowTipsUI("离开交互实体：",UGCObjectUtility.GetObjectName(self.m_owner))
    end
    --
    self.m_overlappedPlayerKeys[playerKey] = nil
    --
    local pc = UGCGameSystem.GetPlayerControllerByPlayerKey(playerKey)
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Global.OnPlayerLeaveInteractEntity,pc,self,self.InstanceID)
end

---@public
function BP_InteractEntityComponent:GetTotalInteractedTimes()
    local ret = 0
    for playerKey,times in pairs(self.m_playerInteractedTimes) do
        ret = ret + times
    end
    return ret
end

---@public
function BP_InteractEntityComponent:GetPlayerInteractedTimes(playerKey)
    local ret = self.m_playerInteractedTimes[playerKey] or 0
    return ret
end

---@public
---@return boolean
function BP_InteractEntityComponent:IsPlayerInteracted(playerKey)
    local ret = self:GetPlayerInteractedTimes(playerKey) > 0
    return ret
end

---@public 获取该实体所有玩家中最近一次交互的时间
---@return number|nil 无交互记录时返回 nil
function BP_InteractEntityComponent:GetLastInteractTime()
    local latest = nil
    for _, t in pairs(self.m_playerInteractedTime) do
        if latest == nil or t > latest then
            latest = t
        end
    end
    return latest
end

---@public 获取指定玩家最近一次交互的时间
---@param playerKey number
---@return number|nil 该玩家无交互记录时返回 nil
function BP_InteractEntityComponent:GetPlayerLastInteractTime(playerKey)
    return self.m_playerInteractedTime[playerKey] or 0
end

---@protected
function BP_InteractEntityComponent:ServerUpdatePlayerInteractionInfo(playerKey)
    local addTimes = 1
    self.m_playerInteractedTimes[playerKey] = (self.m_playerInteractedTimes[playerKey] or 0) + addTimes
    self.m_playerInteractedTime[playerKey] = UGCGameSystem.GetServerTimeSec()
    UnrealNetwork.RepLazyProperty(self,"m_playerInteractedTime")
    UnrealNetwork.RepLazyProperty(self,"m_playerInteractedTimes")
end

---@protected 玩家交互完成 (作用域：服务端)
---@param playerKey number
---@param entityInstanceID number
---@param errCode number EInteractEntityErrCode
---@param errMessage string
function BP_InteractEntityComponent:OnServerPlayerInteractionCompleted(playerKey, entityInstanceID, errCode,errMessage)
    if entityInstanceID ~= self.InstanceID then
        return
    end
    if errCode == EInteractEntityErrCode.None then--交互成功
        --增加玩家交互次数
        self:ServerUpdatePlayerInteractionInfo(playerKey)
        --判断实体是否还能继续交互
        local canInteract = self:CanEntityInteract()
        if not canInteract then--实体无法继续交互
            self:ServerSetInteractable(false)
        end
    end
    --服务端广播交互完成的全局事件
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Global.OnPlayerInteractCompleted, playerKey, entityInstanceID, errCode)
end

---@private
function BP_InteractEntityComponent:OnRep_m_playerInteractedTimes()
    --更新玩家交互数据，判断有没有无法继续交互的玩家
    self:ClientCheckPlayersCanInteract()
end

---@private
function BP_InteractEntityComponent:OnRep_m_playerInteractedTime()
    --更新玩家交互数据，判断有没有无法继续交互的玩家
    self:ClientCheckPlayersCanInteract()
end

---@private
function BP_InteractEntityComponent:ClientCheckPlayersCanInteract()
    for playerKey,v in pairs(self.m_overlappedPlayerKeys or {}) do
        --判断玩家还能不能继续交互
        local canPlayerInteract = self:CanPlayerInteract(playerKey)
        if not canPlayerInteract then--该玩家不能继续交互了
            self:OnPlayerLeave(playerKey)
        end
    end
end

---@private 服务端设置实体是否还能继续交互
function BP_InteractEntityComponent:ServerSetInteractable(canInteract)
    self.m_interactable = canInteract
    if canInteract then
        --通知玩家，交互恢复
        for playerKey,v in pairs(self.m_overlappedPlayerKeys) do
            self:OnPlayerEnter(playerKey)
        end
    else
        --通知玩家，交互停止
        for playerKey,v in pairs(self.m_overlappedPlayerKeys) do
            self:OnPlayerLeave(playerKey)
        end
    end
    UnrealNetwork.RepLazyProperty(self,"m_interactable")
end

---@private
function BP_InteractEntityComponent:OnRep_m_interactable()
    local canInteract = self.m_interactable
    if canInteract then
        --通知玩家，交互恢复
        for playerKey,v in pairs(self.m_overlappedPlayerKeys or {}) do
            self:OnPlayerEnter(playerKey)
        end
    else
        --通知玩家，交互停止
        for playerKey,v in pairs(self.m_overlappedPlayerKeys or {}) do
            self:OnPlayerLeave(playerKey)
        end
    end
end

---@protected 客户端收到玩家交互结果 (作用域：客户端)
---@param playerKey number
---@param entityInstanceID number
---@param errCode number EInteractEntityErrCode
function BP_InteractEntityComponent:OnLocalPlayerReceiveInteractionResult(playerKey, entityInstanceID, errCode,errMessage)
    if entityInstanceID ~= self.InstanceID then
        return
    end
    if errCode == EInteractEntityErrCode.None then--交互成功
        --交互实体客户端侧执行交互行为
        local request = {
            PlayerKey        = playerKey,
            EntityInstanceID = self.InstanceID,
            EntityInteractComp = self,
            CallbackObj      = self,
            CallbackFunc     = self.OnClientInteractCompleted,
        }
        GameplaySystem.InteractEntitySystem:ClientHandleInteractRequest(request)
        --
        UGCWidgetManagerSystem.ShowTipsUI("交互成功！")
    else
        if errMessage and errMessage ~= "" then
            UGCWidgetManagerSystem.ShowTipsUI(tostring(errMessage))
        end
    end
end

---@private
function BP_InteractEntityComponent:OnClientInteractCompleted(playerKey, entityInstanceID, errCode, errMessage)
    if errCode == EInteractEntityErrCode.None then
        GameplayUtils.Print("BP_InteractEntityComponent.OnClientInteractCompleted: 玩家",playerKey,"与",entityInstanceID,"交互成功！")
    else
        GameplayUtils.Print("BP_InteractEntityComponent.OnClientInteractCompleted: 客户端处理玩家",playerKey,"与",entityInstanceID,"交互失败！Error=",errCode," ",errMessage)
    end
    --
    UGCTimerUtility.CreateLuaTimer(0.5,function()
        if UE.IsValid(self) then
            self:ClientCheckPlayersCanInteract()
        end
    end,false)
    --
    --客户端广播交互完成的全局事件
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Global.OnPlayerInteractCompleted, playerKey, entityInstanceID, errCode)
end

---@public 玩家是否还能与指定实体交互(作用域：服务端&客户端)
---@param playerKey number
---@return boolean
---@return number EInteractEntityErrCode
function BP_InteractEntityComponent:CanPlayerInteract(playerKey)
    if self.PlayerInteractTimes > 0 and self:GetPlayerInteractedTimes(playerKey) >= self.PlayerInteractTimes then
        return false,EInteractEntityErrCode.FailExhausted--超过总共可交互次数
    end
    local curTime = UGCGameSystem.GetServerTimeSec()
    if self.CooldownTime > 0 and curTime < self:GetPlayerLastInteractTime(playerKey) + self.CooldownTime then
        return false,EInteractEntityErrCode.FailInCooldown
    end
    if not self.m_isServer then
        --询问行为，当前是否可以进行交互，有一个行为表示不能交互，直接返回。
        local canBehaviourInteract = true
        for k,v in pairs(self.m_behaviours) do
            if not v:CanInteract(playerKey) then
                canBehaviourInteract = false
                break
            end
        end
        if not canBehaviourInteract then
            return false,EInteractEntityErrCode.FailUnavailable
        end
    end
    return true,0
end

---@public 实体是否还能具备交互能力
---@return boolean
---@return number EInteractEntityErrCode
function BP_InteractEntityComponent:CanEntityInteract()
    if self.TotalInteractTimes > 0 and self:GetTotalInteractedTimes() >= self.TotalInteractTimes then
        return false,EInteractEntityErrCode.FailExhausted--超过总共可交互次数
    end
    return true,0
end

---@public
function BP_InteractEntityComponent:SetCollisionEnabled(canInteract)
    if self.m_triggerComp then
        self.m_triggerComp:SetCollisionEnabled(canInteract and ECollisionEnabled.QueryOnly or ECollisionEnabled.NoCollision)
    end
end

---@public
---@return UPrimitiveComponent
function BP_InteractEntityComponent:GetInteractTriggerComponent()
    return self.m_triggerComp
end

---@public
---@return BP_InteractableBase_C
function BP_InteractEntityComponent:GetOwnerActor()
    return self.m_owner
end

---@public
---@return string
function BP_InteractEntityComponent:ClientGetHUDTipsText()
    if type(self.m_overrideUITipsText) == "string" then
        return self.m_overrideUITipsText
    end
    return self.UITipText
end

---@public
---@return string
function BP_InteractEntityComponent:ClientGetHUDInteractionBtnLabel()
    if type(self.m_overrideUIBtnText) == "string" then
        return self.m_overrideUIBtnText
    end
    return self.UIButtonLabel
end

---@public
---@param text string|nil
function BP_InteractEntityComponent:ClientOverrideHUDTipsText(text)
    self.m_overrideUITipsText = text
end

---@public
---@param label string|nil
function BP_InteractEntityComponent:ClientOverrideHUDInteractionBtnLabel(label)
    self.m_overrideUIBtnText = label
end

return BP_InteractEntityComponent