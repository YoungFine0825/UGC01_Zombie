---@class BP_Interact_TeamBuff_C:BP_InteractableBase_C
---@field TeamBuffComponent BP_TeamBuffComponent_C
---@field InteractBehaviour_TeamBuffPickup InteractBehaviour_TeamBuffPickup_C
---@field InteractBehaviour_PlaySound InteractBehaviour_PlaySound_C
---@field InteractBehaviour_DestroyEntity InteractBehaviour_DestroyEntity_C
---@field InteractBehaviour_SetVisible InteractBehaviour_SetVisible_C
---@field ParticleSystem UParticleSystemComponent
---@field Billboard UBillboardComponent
--Edit Below--
---@type BP_Interact_TeamBuff_C
local BP_Interact_TeamBuff = {}
 
--[[
function BP_Interact_TeamBuff:ReceiveBeginPlay()
    BP_Interact_TeamBuff.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Interact_TeamBuff:ReceiveTick(DeltaTime)
    BP_Interact_TeamBuff.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Interact_TeamBuff:ReceiveEndPlay()
    BP_Interact_TeamBuff.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Interact_TeamBuff:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_TeamBuff:GetAvailableServerRPCs()
    return
end
--]]

---@public
---@return BP_TeamBuffComponent_C
function BP_Interact_TeamBuff:GetTeamBuffComponent()
    return self.TeamBuffComponent
end

return BP_Interact_TeamBuff