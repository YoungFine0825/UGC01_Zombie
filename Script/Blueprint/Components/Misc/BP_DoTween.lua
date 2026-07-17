---@class BP_DoTween_C:ActorComponent
---@field StartTransform FTransform
---@field EndTransform FTransform
---@field Duration float
---@field Target USceneComponent
---@field bTransition bool
---@field bRotating bool
---@field bScaling bool
--Edit Below--
---@type BP_DoTween_C
local BP_DoTween = {}

--[[--]]
function BP_DoTween:ReceiveBeginPlay()
    BP_DoTween.SuperClass.ReceiveBeginPlay(self)
    self.m_playing = false
    self.m_playTime = 0
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
    local curLoc, curRot, curScale = UGCMathUtility.BreakTransform(self.Target:GetRelativeTransform())

    local loc = self.bTransition and UGCMathUtility.VLerp(startLoc, endLoc, t) or curLoc
    local rot = self.bRotating and UGCMathUtility.RLerp(startRot, endRot, t, true) or curRot
    local scale = self.bScaling and UGCMathUtility.VLerp(startScale, endScale, t) or curScale

    local newTransform = UGCMathUtility.MakeTransform(loc, rot, scale)
    self.Target:K2_SetRelativeTransform(newTransform)
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
