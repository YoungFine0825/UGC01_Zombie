---@class PlayerStaminaComponent_C:ActorComponent
---@field ConsumeSpeed float
---@field ConsumeSpeedScalar float
---@field RecoverSpeed float
---@field RecoverDelay float
---@field MinimalRequired float
--Edit Below--
---玩家体力组件，体力将限制疾跑。
local PlayerStaminaComponent = {
    bIsSprinting = false,
    fTimeStaminaOff = 0,
    OwnerActor = nil,
    MaxStamina = 100,
    bIsServer = false,
}
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
 
function PlayerStaminaComponent:ReceiveBeginPlay()
    PlayerStaminaComponent.SuperClass.ReceiveBeginPlay(self)
    if UGCGameSystem.IsServer() then
        self.bIsServer = true
        self:InitInServer()
    end
end

function PlayerStaminaComponent:InitInServer()
    if UE.IsValid(self) then
        self.OwnerActor = UGCActorComponentUtility.GetOwner(self)
        if self.OwnerActor then
            self.MaxStamina = UGCAttributeSystem.GetGameAttributeValue(self.OwnerActor,"Stamina")
        end
    end
end

function PlayerStaminaComponent:ReceiveTick(DeltaTime)
    PlayerStaminaComponent.SuperClass.ReceiveTick(self, DeltaTime)
    if self.bIsServer and self.OwnerActor then
        local hasSprintState = UGCPlayerPawnSystem.HasPawnState(self.OwnerActor,EPawnState.Sprint)
        if hasSprintState and not self.bIsSprinting then
            self:OnSprintStart()
        elseif not hasSprintState and self.bIsSprinting then
            self:OnSprintEnd()
        end
        self:UpdateStamina(DeltaTime)
    end
end

--[[
function PlayerStaminaComponent:ReceiveEndPlay()
    PlayerStaminaComponent.SuperClass.ReceiveEndPlay(self) 
end
--]]

---疾跑开始
function PlayerStaminaComponent:OnSprintStart()
    ugcprint("[PlayerStaminaComponent:OnSprintStart] 玩家触发疾跑")
    if self:GetCurStamina() < self.ConsumeSpeed then
        return self:ForceStopSprinting()
    end
    self.bIsSprinting = true
end

--疾跑结束
function PlayerStaminaComponent:OnSprintEnd()
    ugcprint("[PlayerStaminaComponent:OnSprintStart] 玩家停止疾跑")
    self.bIsSprinting = false
    self.fTimeStaminaOff = UGCGameSystem.GetServerTimeSec()
end

function PlayerStaminaComponent:UpdateStamina(DeltaTime)
    if self.OwnerActor then
        if self:ShouldRecover() then
            self:RecoverStamina(DeltaTime)
        elseif self.bIsSprinting then
            if not self:TryConsumeStamina(DeltaTime) then
                self:ForceStopSprinting()
                self:OnSprintEnd()
            end
        end
    end
end

function PlayerStaminaComponent:ShouldRecover()
    if self.bIsSprinting then
        return false
    end
    if self:GetCurStamina() >= self:GetMaxStamina() then
        return false
    end
    local curTime = UGCGameSystem.GetServerTimeSec()
    if curTime < (self.fTimeStaminaOff + self.RecoverDelay) then
        return false
    end
    return true
end

function PlayerStaminaComponent:TryConsumeStamina(DeltaTime)
    local curStamina = self:GetCurStamina()
    local newCurStamina = curStamina - self.ConsumeSpeed * DeltaTime
    if newCurStamina < 0 then
       newCurStamina = 0 
    end
    self:SetStamina(newCurStamina)
    return newCurStamina > 0
end

--随时间恢复体力
function PlayerStaminaComponent:RecoverStamina(DeltaTime)
    local curStamina = self:GetCurStamina()
    local maxStamina = self:GetMaxStamina()
    local newStamina = curStamina + self.RecoverSpeed * DeltaTime
    newStamina = math.max(0,math.min(newStamina,maxStamina))
    self:SetStamina(newStamina)
    if newStamina > self.MinimalRequired then--体力达到最小所需值后启用疾跑状态
        UGCPlayerPawnSystem.DisabledPawnState(self.OwnerActor,EPawnState.Sprint,false)
    end
end

---体力用尽后强制停止疾跑
function PlayerStaminaComponent:ForceStopSprinting()
    --退出疾跑状态
    UGCPlayerPawnSystem.LeavePawnState(self.OwnerActor,EPawnState.Sprint)
    --暂时禁用疾跑状态，直到体力恢复到达最小所需体力值
    UGCPlayerPawnSystem.DisabledPawnState(self.OwnerActor,EPawnState.Sprint,true)
end

---@return number
function PlayerStaminaComponent:GetCurStamina()
    if not self.OwnerActor then
        return 0
    end
    local ret = UGCAttributeSystem.GetGameAttributeValue(self.OwnerActor,"Stamina")
    return ret
end

---@return number
function PlayerStaminaComponent:GetMaxStamina()
    return self.MaxStamina
end

---@return boolean
function PlayerStaminaComponent:SetStamina(Stamina)
    if not self.OwnerActor then
        return false
    end
    UGCAttributeSystem.SetGameAttributeValue(self.OwnerActor,"Stamina",Stamina)
    --模板自带HUD上有一个魔法值条，同时设置Magic值,用魔法值对应的UI进度条来验证体力消耗和恢复
    --UGCAttributeSystem.SetGameAttributeValue(self.OwnerActor,"Magic",Stamina)
    return true
end

return PlayerStaminaComponent