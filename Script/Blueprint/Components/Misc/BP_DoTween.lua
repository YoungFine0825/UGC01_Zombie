---@class BP_DoTween_C:ActorComponent
---@field StartTransform FTransform
---@field EndTransform FTransform
---@field Duration float
---@field Target USceneComponent
---@field bTransition bool
---@field bRotating bool
---@field bScaling bool
---@field bAdditive bool
--Edit Below--
---@type BP_DoTween_C
local BP_DoTween = {
    m_playing = false,
}

--[[--]]
function BP_DoTween:ReceiveBeginPlay()
    BP_DoTween.SuperClass.ReceiveBeginPlay(self)
    self.m_playing = false
    self.m_playTime = 0
    self.m_initTransform = nil
    self:SetComponentTickEnabled(false)
end

--[[--]]
function BP_DoTween:ReceiveTick(DeltaTime)
    BP_DoTween.SuperClass.ReceiveTick(self, DeltaTime)
    if not self.m_playing then
        return
    end
    if not UE.IsValid(self.Target) then
        self.m_playing = false
        self:SetComponentTickEnabled(false)
        return
    end

    local time = self.m_playTime + DeltaTime
    self.m_playTime = time

    local duration = self.Duration or 0
    local t = 1
    if duration > 0 then
        t = time / duration
        if t > 1 then
            t = 1
        end
    end

    self:_ApplyTween(t)

    if t >= 1 then
        self.m_playing = false
        self:SetComponentTickEnabled(false)
    end
end

---@private
function BP_DoTween:_ApplyTween(t)
    local startLoc, startRot, startScale = UGCMathUtility.BreakTransform(self.StartTransform)
    local endLoc, endRot, endScale = UGCMathUtility.BreakTransform(self.EndTransform)

    -- 组件计算出的插值结果（Start -> End）
    local calcLoc = UGCMathUtility.VLerp(startLoc, endLoc, t)
    local calcRot = UGCMathUtility.RLerp(startRot, endRot, t, true)
    local calcScale = UGCMathUtility.VLerp(startScale, endScale, t)

    local loc, rot, scale
    if self.bAdditive then
        -- 叠加模式：在 Target 初始化 Transform 基础上叠加组件计算结果
        if not self.m_initTransform then
            local bLoc, bRot, bScale = UGCMathUtility.BreakTransform(self.Target:GetRelativeTransform())
            self.m_initTransform = UGCMathUtility.MakeTransform(bLoc, bRot, bScale)
        end
        local initLoc, initRot, initScale = UGCMathUtility.BreakTransform(self.m_initTransform)
        loc = self.bTransition and UGCMathUtility.AddVector(initLoc, calcLoc) or initLoc
        rot = self.bRotating and UGCMathUtility.ComposeRotators(initRot, calcRot) or initRot
        scale = self.bScaling and self:_MulScale(initScale, calcScale) or initScale
    else
        -- 直接应用模式：组件计算结果直接覆盖 Target Transform
        local curLoc, curRot, curScale = UGCMathUtility.BreakTransform(self.Target:GetRelativeTransform())
        loc = self.bTransition and calcLoc or curLoc
        rot = self.bRotating and calcRot or curRot
        scale = self.bScaling and calcScale or curScale
    end

    local newTransform = UGCMathUtility.MakeTransform(loc, rot, scale)
    self.Target:K2_SetRelativeTransform(newTransform)
end

---@private
---@param a FVector
---@param b FVector
---@return FVector
function BP_DoTween:_MulScale(a, b)
    local ax, ay, az = UGCMathUtility.BreakVector(a)
    local bx, by, bz = UGCMathUtility.BreakVector(b)
    return UGCMathUtility.MakeVector(ax * bx, ay * by, az * bz)
end

---@public
function BP_DoTween:Play()
    if not UE.IsValid(self.Target) then
        return
    end
    self.m_playing = true
    self.m_playTime = 0
    self:SetComponentTickEnabled(true)
    self:_ApplyTween(0)
end

---@public
function BP_DoTween:Pause()
    self.m_playing = false
    self:SetComponentTickEnabled(false)
end

---@public
function BP_DoTween:Resume()
    if not UE.IsValid(self.Target) then
        return
    end
    local duration = self.Duration or 0
    if self.m_playTime >= duration then
        self.m_playTime = 0
    end
    self.m_playing = true
    self:SetComponentTickEnabled(true)
end

---@public
function BP_DoTween:Reset()
    self.m_playing = false
    self.m_playTime = 0
    self:SetComponentTickEnabled(false)
    if UE.IsValid(self.Target) then
        self:_ApplyTween(0)
    end
end

return BP_DoTween
