---@class InteractBehaviour_PlaySound_C:BP_InteractEntityBehaviourComponent_C
---@field bIs3DSound bool
---@field SoundAsset UAkAudioEvent
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_PlaySound_C
local InteractBehaviour_PlaySound = BPExtent({}, "Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")

--[[--]]
function InteractBehaviour_PlaySound:ReceiveBeginPlay()
    InteractBehaviour_PlaySound.SuperClass.ReceiveBeginPlay(self)
end

--[[
function InteractBehaviour_PlaySound:ReceiveTick(DeltaTime)
    InteractBehaviour_PlaySound.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_PlaySound:ReceiveEndPlay()
    InteractBehaviour_PlaySound.SuperClass.ReceiveEndPlay(self)
end

---@public
---@param playerKey number
function InteractBehaviour_PlaySound:Execute(playerKey)
    self.BaseClass.Execute(self, playerKey)
    --
    if self.m_isServer then
        self:OnFinish()
        return
    end
    --
    if not UE.IsValid(self.SoundAsset) then
        GameplayUtils.Exception("InteractBehaviour_PlaySound.Execute: SoundAsset 未配置")
        self:OnFinish()
        return
    end
    --
    if self.bIs3DSound then
        local owner = UGCActorComponentUtility.GetOwner(self)
        if UE.IsValid(owner) then
            UGCSoundManagerSystem.PlaySoundAtLocation(
                self.SoundAsset,
                owner:K2_GetActorLocation(),
                owner:K2_GetActorRotation()
            )
        end
    else
        UGCSoundManagerSystem.PlaySound2D(self.SoundAsset)
    end
    --
    self:OnFinish()
end

return InteractBehaviour_PlaySound
