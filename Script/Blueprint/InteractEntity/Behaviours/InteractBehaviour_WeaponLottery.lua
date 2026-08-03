---@class InteractBehaviour_WeaponLottery_C:BP_InteractEntityBehaviourComponent_C
---@field WeaponConfigIDList ULuaArrayHelper<FStruct_WeaponLotteryWeight__pf1780872549>
---@field Price float
---@field IntervalTime float
---@field DrawingTime float
---@field DrawnWeaponDisappearTime float
---@field PlayerKey int32
---@field DrawnWeaponConfigID int32
---@field AudioDrawing UAkAudioEvent
---@field AudioReceive UAkAudioEvent
---@field WeaponPool1 Struct_WeaponLotteryPool
---@field WeaponPool2 Struct_WeaponLotteryPool
---@field WeaponPool3 Struct_WeaponLotteryPool
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_WeaponLottery_C
local InteractBehaviour_WeaponLottery = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")

local ELotteryState = {
    None = 0,
    Idle = 1,--空闲状态
    Drawing = 2,--正在抽奖,展示抽奖过程
    ShowingWeapon = 3,--展示抽中的武器
}

---材质中武器图标贴图参数名
local WEAPON_ICON_TEXTURE_PARAM_NAME = "Albedo"

--[[--]]
function InteractBehaviour_WeaponLottery:ReceiveBeginPlay()
    InteractBehaviour_WeaponLottery.SuperClass.ReceiveBeginPlay(self)
    self.m_curState = ELotteryState.Idle
    ---@type BP_Interact_WeaponLottery_C
    self.m_owner = UGCActorComponentUtility.GetOwner(self)
    self.m_owner.Mesh0:SetVisibility(false)
    ---@type table<number,UTexture>
    self.m_preloadedIconTextures = {}
    self.m_weaponIconDynamicMaterial = nil
    self.m_drawingAnimTimer = nil
    self.m_latestDrawingTime = 0
    self.m_lastDrawingWeaponConfigID = 0
    ---@type number[] 全部可用武器的ConfigID（动画纯表现随机用）
    self.m_allWeaponConfigIDs = {}
    if self.m_isClient then
        self:CollectAllWeaponConfigIDs()
        self:PreloadWeaponIconTextures()
    end
end

---@private 从 DT_WeaponConfigs 收集所有配置了弹药的武器ConfigID（去重）
---@return number[] 武器ConfigID列表
function InteractBehaviour_WeaponLottery:CollectAllWeaponConfigIDs()
    self.m_allWeaponConfigIDs = {}
    local cfgTable = GameplaySystem.WeaponConfigMgr:GetDataTableData()
    if not cfgTable then
        return self.m_allWeaponConfigIDs
    end
    local seen = {}
    for _, weaponCfg in pairs(cfgTable) do
        local configID = weaponCfg.Id
        local ammoItemID = weaponCfg.AmmoItemId
        -- 只收集有弹药配置的武器（排除无弹药的特殊条目）
        if configID and configID > 0 and ammoItemID and ammoItemID > 0 and not seen[configID] then
            seen[configID] = true
            table.insert(self.m_allWeaponConfigIDs, configID)
        end
    end
    return self.m_allWeaponConfigIDs
end


--[[--]]
function InteractBehaviour_WeaponLottery:ReceiveTick(DeltaTime)
    InteractBehaviour_WeaponLottery.SuperClass.ReceiveTick(self, DeltaTime)
end


--[[--]]
function InteractBehaviour_WeaponLottery:ReceiveEndPlay()
    InteractBehaviour_WeaponLottery.SuperClass.ReceiveEndPlay(self)
    self:StopDrawingAnim()
    self.m_preloadedIconTextures = nil
    self.m_weaponIconDynamicMaterial = nil
end


function InteractBehaviour_WeaponLottery:GetReplicatedProperties()
    return {"m_curState","Lazy"}
end

--function InteractBehaviour_WeaponLottery:GetAvailableServerRPCs()
--    return
--end

function InteractBehaviour_WeaponLottery:GetAvailableClientRPCs()
    return "RPC_Client_OnPlayerReceiveWeapon"
end

---@protected 服务端通知当前发起抽奖的玩家
function InteractBehaviour_WeaponLottery:OnRep_PlayerKey()

end

---@protected 服务端通知当前抽中的武器配置表ID
function InteractBehaviour_WeaponLottery:OnRep_DrawnWeaponConfigID()

end

---@public 客户端提前判断是否可以交互
---@param playerKey number 请求交互的玩家的playerKey
---@return boolean
---@return number EInteractEntityErrCode
function InteractBehaviour_WeaponLottery:CanInteract(playerKey)
    local canInteract,errCode = self.BaseClass.CanInteract(self,playerKey)
    if not canInteract then
        return canInteract,errCode
    end
    local weaponList = self:GetActiveWeaponList()
    if not weaponList or weaponList:Num() <= 0 then
        return false,EInteractEntityErrCode.FailUnavailable--未配置武器ID列表，不允许交互
    end
    if self.m_curState == ELotteryState.ShowingWeapon then--正在显示抽中的武器
        if playerKey ~= self.PlayerKey then
            return false,EInteractEntityErrCode.FailUnavailable--不是发起抽奖的玩家，不允许交互
        end
    elseif self.m_curState == ELotteryState.Drawing then--正在抽奖中不允许任何人交互
        if playerKey ~= self.PlayerKey then
            return false,EInteractEntityErrCode.FailUnavailable--不是发起抽奖的玩家，不允许交互
        end
    end
    return true,EInteractEntityErrCode.None
end

---@public 服务端检查交互行为是否符合条件
---@param playerKey number 请求交互的玩家的playerKey
---@return boolean
---@return number EInteractEntityErrCode
function InteractBehaviour_WeaponLottery:CanExecute(playerKey)
    local canExecute,errCode = self.BaseClass.CanExecute(self,playerKey)
    if not canExecute then
        return canExecute,errCode
    end
    if self.m_curState == ELotteryState.Idle then
        if UGCGameSystem.GetServerTimeSec() < (self.m_latestDrawingTime + self.IntervalTime) then
            return false,EInteractEntityErrCode.FailInCooldown
        end
        local curSocre = GameplaySystem.PlayerSystem:GetPlayerCurrentScore(playerKey)
        if curSocre < self.Price then
            return false,EInteractEntityErrCode.FailUnavailable--得分不够
        end
    elseif self.m_curState == ELotteryState.Drawing then
        return false,EInteractEntityErrCode.FailAlreadyDrawing
    end
    return true,EInteractEntityErrCode.None
end

---@public 服务端&客户端执行
---@param playerKey number 请求交互的玩家的playerKey
function InteractBehaviour_WeaponLottery:Execute(playerKey)
    local curState = self.m_curState
    if curState == ELotteryState.Idle then
        self:StartLottery(playerKey)--玩家发起抽奖
    elseif curState == ELotteryState.Drawing then

    elseif curState == ELotteryState.ShowingWeapon then
        if playerKey == self.PlayerKey then
            self:ServerPlayerReceiveWeapon(playerKey)--玩家领取武器
        end
    end
end

function InteractBehaviour_WeaponLottery:StartLottery(playerKey)
    if self.m_isServer then
        self.PlayerKey = playerKey
        --消耗玩家积分
        GameplaySystem.PlayerSystem:ConsumePlayerScore(playerKey,self.Price)
        --抽取武器
        self:ServerDoWeaponLotteryDraw()
        --进入抽奖动画
        self:ServerChangeState(ELotteryState.Drawing)
        UGCTimerUtility.CreateLuaTimer(self.DrawingTime,function()
            self:ShowLotteryResult()
        end,false)
    end
end

function InteractBehaviour_WeaponLottery:ShowLotteryResult()
    if self.m_isServer then
        self:ServerChangeState(ELotteryState.ShowingWeapon)
        self.m_stopLotteryTimer = UGCTimerUtility.CreateLuaTimer(self.DrawnWeaponDisappearTime,function()
            self:StopLottery()
        end,false)
    end
end

function InteractBehaviour_WeaponLottery:StopLottery()
    if self.m_isServer then
        self.DrawnWeaponConfigID = 0
        self.PlayerKey = 0
        if self.m_stopLotteryTimer then
            UGCTimerUtility.RemoveLuaTimer(self.m_stopLotteryTimer)
            self.m_stopLotteryTimer = nil
        end
        self:ServerChangeState(ELotteryState.Idle)
        self.m_latestDrawingTime = UGCGameSystem.GetServerTimeSec()
    end
end

---@protected 获取当前回合数
---@return number
function InteractBehaviour_WeaponLottery:GetCurRound()
    local stateComp = GameplaySystem.GetGameplayStateComponent()
    if stateComp then
        return stateComp:GetCurRound() or 0
    end
    return 0
end

---@protected 获取当前回合对应的奖池（按 StartRound/EndRound 匹配；无命中回退第一个有武器的池）
---@return Struct_WeaponLotteryPool|nil
function InteractBehaviour_WeaponLottery:GetActivePool()
    local curRound = self:GetCurRound()
    local pools = { self.WeaponPool1, self.WeaponPool2, self.WeaponPool3 }
    local fallbackPool = nil
    for _, pool in ipairs(pools) do
        if pool then
            if fallbackPool == nil then
                fallbackPool = pool
            end
            local startRound = tonumber(pool.StartRound) or 0
            local endRound = tonumber(pool.EndRound) or 0
            -- EndRound<=0 表示无上限（持续到游戏结束）
            if curRound >= startRound and (endRound <= 0 or curRound <= endRound) then
                return pool
            end
        end
    end
    return fallbackPool
end

---@protected 获取当前生效的武器权重列表（优先池子，池子为空回退 WeaponConfigIDList）
---@return ULuaArrayHelper|nil
function InteractBehaviour_WeaponLottery:GetActiveWeaponList()
    local pool = self:GetActivePool()
    if pool and pool.WeaponsWeight and pool.WeaponsWeight:Num() > 0 then
        return pool.WeaponsWeight
    end
    return self.WeaponConfigIDList
end

---@protected 按权重随机抽取一个武器ConfigID（依据当前波次动态选池）
---@return number weaponConfigID 抽中的武器配置ID；池子为空返回0
function InteractBehaviour_WeaponLottery:DrawRandomWeapon()
    local weaponList = self:GetActiveWeaponList()
    if not weaponList then
        return 0
    end
    local weaponNum = weaponList:Num()
    if weaponNum <= 0 then
        return 0
    end

    -- 汇总各元素权重（Weight<=0 时兜底为 1，避免权重配置不全导致抽不到）
    local totalWeight = 0
    local weights = {}
    for i = 1, weaponNum do
        local item = weaponList:Get(i)
        local w = tonumber(item.Weight) or 0
        if w <= 0 then
            w = 1
        end
        weights[i] = w
        totalWeight = totalWeight + w
    end

    -- 加权随机命中（与 BP_TeamBuffDropManager.PickRandomBuff 同款累积算法）
    local roll = math.random() * totalWeight
    local cumulative = 0
    for i = 1, weaponNum do
        cumulative = cumulative + weights[i]
        if roll <= cumulative then
            return weaponList:Get(i).WeaponConfigID
        end
    end
    -- 浮点误差兜底
    return weaponList:Get(weaponNum).WeaponConfigID
end

---@protected
function InteractBehaviour_WeaponLottery:ServerDoWeaponLotteryDraw()
    local weaponConfigID = self:DrawRandomWeapon()
    self.DrawnWeaponConfigID = weaponConfigID
    GameplayUtils.Print("InteractBehaviour_WeaponLottery.ServerDoWeaponLotteryDraw: 抽中武器",weaponConfigID)
end

---@protected
function InteractBehaviour_WeaponLottery:ServerPlayerReceiveWeapon(playerKey)
    if self.m_isClient then
        return
    end
    self:ServerDeliverWeaponToPlayer(playerKey)
    self:StopLottery()
end

---@protected
function InteractBehaviour_WeaponLottery:ServerDeliverWeaponToPlayer(playerKey)
    if self.m_isClient then
        return
    end
    GameplaySystem.WeaponSystem:ServerDeliverAndEquipWeaponToPlayer(playerKey,self.DrawnWeaponConfigID,true)
    local playerController = UGCGameSystem.GetPlayerControllerByPlayerKey(playerKey)
    UnrealNetwork.CallUnrealRPC(playerController,self,"RPC_Client_OnPlayerReceiveWeapon",playerKey,self.DrawnWeaponConfigID)
end

---@protected
function InteractBehaviour_WeaponLottery:RPC_Client_OnPlayerReceiveWeapon(playerKey,weaponConfigID)
    if playerKey ~= UGCGameSystem.GetLocalPlayerKey() then
        return
    end
    UGCSoundManagerSystem.PlaySound2D(self.AudioReceive)
end

---@protected
function InteractBehaviour_WeaponLottery:ServerChangeState(state)
    self.m_curState = state
    UnrealNetwork.RepLazyProperty(self,"m_curState")
end

---@protected 服务端通知状态改变
function InteractBehaviour_WeaponLottery:OnRep_m_curState()
    ---@type UGCPlayerController_C
    local pc = UGCGameSystem.GetLocalPlayerController()
    local curState = self.m_curState
    if curState == ELotteryState.Idle then
        self:StopDrawingAnim()
        self.m_owner.Mesh0:SetVisibility(false)
        self.m_interactEntityComp:ClientOverrideHUDTipsText(nil)
        self.m_interactEntityComp:ClientOverrideHUDInteractionBtnLabel(nil)
        --
        pc.PlayerInteractEntityComponent:ClientUpdateInteractionUIWidget()
    elseif curState == ELotteryState.Drawing then
        self:ClientPlayDrawingAnim()
        --
        pc.PlayerInteractEntityComponent:ClientShowInteractionUIWidget(false)
        --播放抽奖音效
        if self.m_drawingSoundID then
            UGCSoundManagerSystem.StopSoundByID(self.m_drawingSoundID)
        end
        self.m_drawingSoundID = UGCSoundManagerSystem.PlaySound2D(self.AudioDrawing)
    elseif curState == ELotteryState.ShowingWeapon then
        local weaponName = GameplaySystem.WeaponConfigMgr:GetWeaponName(self.DrawnWeaponConfigID)
        self.m_interactEntityComp:ClientOverrideHUDTipsText(string.format("领取%s",weaponName))
        self.m_interactEntityComp:ClientOverrideHUDInteractionBtnLabel("领取")
        --
        self:ClientPlayWeaponDisappearAnim()
        --
        pc.PlayerInteractEntityComponent:ClientUpdateInteractionUIWidget()
        --停止音效
        if self.m_drawingSoundID then
            UGCSoundManagerSystem.StopSoundByID(self.m_drawingSoundID)
            self.m_drawingSoundID = nil
        end
    end

end

---@protected 客户端播放抽奖过程
function InteractBehaviour_WeaponLottery:ClientPlayDrawingAnim()
    self.m_lastDrawingWeaponConfigID = 0
    self.m_owner.Mesh0:SetVisibility(true)
    self:CreateWeaponIconMaterialInstance()
    self:StopDrawingAnim()
    self.m_drawingAnimTimer = UGCTimerUtility.CreateLuaTimer(0.2, function()
        if not self then
            return
        end
        self:PlayOneDrawingFrame()
    end, true, "WeaponLotteryDrawing")
end

---@protected
function InteractBehaviour_WeaponLottery:ClientPlayWeaponDisappearAnim()
    self:StopDrawingAnim()
    self.m_owner.Mesh0:SetVisibility(true)
    self:CreateWeaponIconMaterialInstance()
    self:DisplayWeaponIcon(self.DrawnWeaponConfigID)
end

---@protected 抽取一帧要显示的潜在武器图标（纯表现：从全部武器中均匀随机）
function InteractBehaviour_WeaponLottery:PlayOneDrawingFrame()
    local weaponList = self.m_allWeaponConfigIDs
    if not weaponList or #weaponList <= 0 then
        return
    end
    local weaponNum = #weaponList
    if weaponNum == 1 then
        local weaponConfigID = weaponList[1]
        self.m_lastDrawingWeaponConfigID = weaponConfigID
        self:DisplayWeaponIcon(weaponConfigID)
        return
    end
    -- 均匀随机抽取一帧展示（表现层不参与实际抽奖权重）
    local weaponConfigID = weaponList[math.random(weaponNum)]
    if weaponConfigID == self.m_lastDrawingWeaponConfigID then
        -- 抽到与上一帧相同的武器时，随机改抽另一把（轮转），保证滚动感且不引入分布偏差
        local candidates = {}
        for _, cid in ipairs(weaponList) do
            if cid ~= weaponConfigID then
                table.insert(candidates, cid)
            end
        end
        if #candidates > 0 then
            weaponConfigID = candidates[math.random(#candidates)]
        end
    end
    self.m_lastDrawingWeaponConfigID = weaponConfigID
    self:DisplayWeaponIcon(weaponConfigID)
end

---@protected 停止抽奖动画
function InteractBehaviour_WeaponLottery:StopDrawingAnim()
    if self.m_drawingAnimTimer then
        UGCTimerUtility.RemoveLuaTimer(self.m_drawingAnimTimer)
        self.m_drawingAnimTimer = nil
    end
end

---@private 预加载武器图标贴图（优先全部武器；回退奖池+旧配置，去重）
function InteractBehaviour_WeaponLottery:PreloadWeaponIconTextures()
    local seen = {}
    local configIDs = {}
    local function collect(id)
        if id and id > 0 and not seen[id] then
            seen[id] = true
            table.insert(configIDs, id)
        end
    end
    -- 优先：已收集的全部武器（与动画纯表现随机一致）
    if self.m_allWeaponConfigIDs and #self.m_allWeaponConfigIDs > 0 then
        for _, cid in ipairs(self.m_allWeaponConfigIDs) do
            collect(cid)
        end
    else
        -- 回退：三个奖池 + 兼容旧配置 WeaponConfigIDList
        for _, pool in ipairs({ self.WeaponPool1, self.WeaponPool2, self.WeaponPool3 }) do
            if pool and pool.WeaponsWeight then
                local n = pool.WeaponsWeight:Num()
                for i = 1, n do
                    collect(pool.WeaponsWeight:Get(i).WeaponConfigID)
                end
            end
        end
    end

    for _, weaponConfigID in ipairs(configIDs) do
        local iconPathObj = GameplaySystem.WeaponConfigMgr:GetWeaponBackpackIconByConfigID(weaponConfigID)
        if iconPathObj then
            local iconPath = UGCObjectUtility.GetPathBySoftObjectPath(iconPathObj)
            if iconPath and iconPath ~= "" then
                UGCObjectUtility.AsyncLoadObject(iconPath, function(texture)
                    if self and self.m_preloadedIconTextures then
                        self.m_preloadedIconTextures[weaponConfigID] = texture
                    end
                end)
            end
        end
    end
end

---@protected 为 Mesh0 创建动态材质实例
function InteractBehaviour_WeaponLottery:CreateWeaponIconMaterialInstance()
    if self.m_weaponIconDynamicMaterial then
        return
    end
    ---@type UPrimitiveComponent
    local weaponIconMesh = self.m_owner.Mesh0
    self.m_weaponIconDynamicMaterial = weaponIconMesh:CreateDynamicMaterialInstance(0)
end

---@protected 在 Mesh0 上显示指定武器的图标
function InteractBehaviour_WeaponLottery:DisplayWeaponIcon(weaponConfigID)
    if not self.m_weaponIconDynamicMaterial then
        return
    end
    local texture = self.m_preloadedIconTextures[weaponConfigID]
    if not texture then
        return
    end
    self.m_weaponIconDynamicMaterial:SetTextureParameterValue(WEAPON_ICON_TEXTURE_PARAM_NAME, texture)
end

return InteractBehaviour_WeaponLottery