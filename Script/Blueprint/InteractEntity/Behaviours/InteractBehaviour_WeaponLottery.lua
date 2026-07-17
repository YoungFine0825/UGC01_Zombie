---@class InteractBehaviour_WeaponLottery_C:BP_InteractEntityBehaviourComponent_C
---@field WeaponConfigIDList ULuaArrayHelper<int32>
---@field Price float
---@field IntervalTime float
---@field DrawingTime float
---@field DrawnWeaponDisappearTime float
---@field PlayerKey int32
---@field DrawnWeaponConfigID int32
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
    if self.m_isClient then
        self:PreloadWeaponIconTextures()
    end
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

function InteractBehaviour_WeaponLottery:GetAvailableServerRPCs()
    return
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
    if self.WeaponConfigIDList:Num() <= 0 then
        return false,EInteractEntityErrCode.FailUnavailable--未配置武器ID列表，不允许交互
    end
    if self.m_curState == ELotteryState.ShowingWeapon then--正在显示抽中的武器
        if playerKey ~= self.PlayerKey then
            return false,EInteractEntityErrCode.FailUnavailable--不是发起抽奖的玩家，不允许交互
        end
    elseif self.m_curState == ELotteryState.Drawing then--正在抽奖中不允许任何人交互
        return false,EInteractEntityErrCode.FailUnavailable
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
        local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
        local playerPropertyName = EPlayerInGameStatKeys.TotalScore
        local propertyValue = UGCAttributeSystem.GetGameAttributeValue(playerPawn,playerPropertyName)
        if propertyValue < self.Price then
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
        self:ServerDoWeaponLotteryDraw()
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

---@protected
function InteractBehaviour_WeaponLottery:ServerDoWeaponLotteryDraw()
    local weaponNum = self.WeaponConfigIDList:Num()
    local weaponIndex = math.random(1, weaponNum)
    local weaponConfigID = self.WeaponConfigIDList:Get(weaponIndex)
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
    GameplaySystem.WeaponSystem:ServerDeliverAndEquipWeaponToPlayer(playerKey,self.DrawnWeaponConfigID)
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
    elseif curState == ELotteryState.ShowingWeapon then
        local weaponName = GameplaySystem.WeaponConfigMgr:GetWeaponName(self.DrawnWeaponConfigID)
        self.m_interactEntityComp:ClientOverrideHUDTipsText(string.format("领取%s",weaponName))
        self.m_interactEntityComp:ClientOverrideHUDInteractionBtnLabel("领取")
        --
        self:ClientPlayWeaponDisappearAnim()
        --
        pc.PlayerInteractEntityComponent:ClientUpdateInteractionUIWidget()
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

---@protected 抽取一帧要显示的潜在武器图标
function InteractBehaviour_WeaponLottery:PlayOneDrawingFrame()
    local weaponNum = self.WeaponConfigIDList:Num()
    if weaponNum <= 0 then
        return
    end
    if weaponNum == 1 then
        local weaponConfigID = self.WeaponConfigIDList:Get(1)
        self.m_lastDrawingWeaponConfigID = weaponConfigID
        self:DisplayWeaponIcon(weaponConfigID)
        return
    end
    local weaponIndex = math.random(1, weaponNum)
    local weaponConfigID = self.WeaponConfigIDList:Get(weaponIndex)
    if weaponConfigID == self.m_lastDrawingWeaponConfigID then
        weaponIndex = weaponIndex % weaponNum + 1
        weaponConfigID = self.WeaponConfigIDList:Get(weaponIndex)
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

---@private
function InteractBehaviour_WeaponLottery:PreloadWeaponIconTextures()
    local weaponNum = self.WeaponConfigIDList:Num()
    for i = 1, weaponNum do
        local weaponConfigID = self.WeaponConfigIDList:Get(i)
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