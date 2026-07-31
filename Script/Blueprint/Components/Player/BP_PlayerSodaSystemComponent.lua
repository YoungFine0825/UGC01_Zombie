---@class BP_PlayerSodaSystemComponent_C:ActorComponent
--Edit Below--
---@type BP_PlayerSodaSystemComponent_C
local BP_PlayerSodaSystemComponent = {}
 
--[[--]]
function BP_PlayerSodaSystemComponent:ReceiveBeginPlay()
    BP_PlayerSodaSystemComponent.SuperClass.ReceiveBeginPlay(self)
    ---@type UGCPlayerController_C
    self.m_playerController = UGCActorComponentUtility.GetOwner(self)
    self.m_usedSodaIDList = {}
    ---@type table<string,UClass>
    self.m_cachedBuffClass = {}
    ---@type table<number,UPersistEffectBuff>
    self.m_appliedBuffs = {}
    -- 服务端监听玩家存活状态变化
    if UGCGameSystem.IsServer() then
        GameplaySystem.EventSystem:Listen(GameplayEvents.Server.OnPlayerAliveStateChanged, self, self.OnPlayerAliveStateChanged)
    end
end


--[[
function BP_PlayerSodaSystemComponent:ReceiveTick(DeltaTime)
    BP_PlayerSodaSystemComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function BP_PlayerSodaSystemComponent:ReceiveEndPlay()
    BP_PlayerSodaSystemComponent.SuperClass.ReceiveEndPlay(self)
    -- 取消事件监听
    if UGCGameSystem.IsServer() then
        GameplaySystem.EventSystem:UnlistenAll(self)
    end
    self.m_cachedBuffClass = nil
    self.m_usedSodaIDList = nil
    self.m_appliedBuffs = nil
    self.m_playerController = nil
end



function BP_PlayerSodaSystemComponent:GetAvailableClientRPCs()

end

---@protected
function BP_PlayerSodaSystemComponent:GetReplicatedProperties()
    return {"m_usedSodaIDList","Lzay"}
end

---@private
function BP_PlayerSodaSystemComponent:OnRep_m_usedSodaIDList()
    GameplayUtils.Print("SodaSystemComponent: 客户端玩家 ",UGCObjectUtility.GetObjectName(self.m_playerController)," 更新特效饮料列表！")
end

---@public 检查是否已使用过该饮料
---@return boolean
function BP_PlayerSodaSystemComponent:IsUsed(sodaConfigID)
    for k,v in pairs(self.m_usedSodaIDList) do
        if v == sodaConfigID then
            return true
        end
    end
    return false
end

---@public 获得特效饮料
---@return boolean
function BP_PlayerSodaSystemComponent:ServerGainSoda(sodaConfigID)
    if not UGCGameSystem.IsServer() then
        return false
    end
    local configData = GameplaySystem.SodaConfigMgr:GetSodaConfigData(sodaConfigID)
    if not configData then
        return false
    end
    local buffClassPath = UGCObjectUtility.GetPathBySoftObjectPath(configData.BuffClass)
    local cachedUClass = self.m_cachedBuffClass[buffClassPath]
    if cachedUClass then
        self:ServerAddBuff(sodaConfigID,cachedUClass)
        self:ServerAddSodaItem(sodaConfigID)
    else
        UGCObjectUtility.AsyncLoadClass(buffClassPath,function(uclass)
            if UE.IsValid(self) then
                self:OnLoadBuffClassCompleted(sodaConfigID,buffClassPath,uclass)
            end
        end)
    end
end

---@private
function BP_PlayerSodaSystemComponent:OnLoadBuffClassCompleted(sodaConfigID,buffClassPath,uclass)
    self.m_cachedBuffClass[buffClassPath] = uclass
    self:ServerAddBuff(sodaConfigID,uclass)
    self:ServerAddSodaItem(sodaConfigID)
end

---@protected 添加Buff并记录
function BP_PlayerSodaSystemComponent:ServerAddBuff(sodaConfigID,buffClass)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(self.m_playerController)
    if not playerPawn then
        return
    end
    table.insert(self.m_usedSodaIDList,sodaConfigID)
    UnrealNetwork.RepLazyProperty(self,"m_usedSodaIDList")
    UGCPersistEffectSystem.AddBuffByClass(playerPawn,buffClass,self.m_playerController)
    -- 记录BuffClass，便于后续清除
    self.m_appliedBuffs[sodaConfigID] = buffClass
end

---@protected 添加饮料道具让玩家播放使用的道具的动作，仅作为表现
function BP_PlayerSodaSystemComponent:ServerAddSodaItem(sodaConfigID)
    local configData = GameplaySystem.SodaConfigMgr:GetSodaConfigData(sodaConfigID)
    if not configData then
        return false
    end
    local itemID = configData.ItemID
    local addSuccessfult,sodaDefineID = GameplaySystem.BackpackSystem:DeliverItemToPlayer(self.m_playerController,itemID,1)
    if addSuccessfult then
        ----通知客户端，玩家使用汽水
        UGCBackpackSystemV2.UseItemV2(self.m_playerController,sodaDefineID)
    end
    return addSuccessfult
end

---@public 玩家存活状态变化回调（服务端）
---@param playerController UGCPlayerController_C 状态变化的玩家
---@param newState Gameplay.EPlayerAliveState 新状态
---@param previousState Gameplay.EPlayerAliveState 旧状态
function BP_PlayerSodaSystemComponent:OnPlayerAliveStateChanged(playerController, newState, previousState)
    -- 只处理自己
    if playerController ~= self.m_playerController then
        return
    end
    -- 濒死或死亡时清除soda和buff
    if newState == EPlayerAliveState.Dying or newState == EPlayerAliveState.Dead then
        self:ServerClearAllSoda()
    end
end

---@public 清除所有已使用的soda及对应的buff（服务端）
function BP_PlayerSodaSystemComponent:ServerClearAllSoda()
    if not UGCGameSystem.IsServer() then
        return
    end
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(self.m_playerController)
    if not playerPawn then
        return
    end
    -- 移除所有已应用的buff，但保留SelfRescue相关的buff
    local SelfRescueTag = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Buff.SelfRescue")
    for sodaConfigID, buffClass in pairs(self.m_appliedBuffs) do
        if buffClass then
            UGCPersistEffectSystem.RemoveBuffByClass(playerPawn, buffClass)
        end
    end
    -- 清空记录
    self.m_appliedBuffs = {}
    self.m_usedSodaIDList = {}
    UnrealNetwork.RepLazyProperty(self, "m_usedSodaIDList")
    GameplayUtils.Print("SodaSystemComponent: 玩家 ",UGCObjectUtility.GetObjectName(self.m_playerController)," 濒死/死亡，已清除所有soda和buff")
end

---@private
function BP_PlayerSodaSystemComponent:RPC_Client_OnUseSoda(sodaConfigID)
    local configData = GameplaySystem.SodaConfigMgr:GetSodaConfigData(sodaConfigID)
    if not configData then
        return
    end
end

return BP_PlayerSodaSystemComponent