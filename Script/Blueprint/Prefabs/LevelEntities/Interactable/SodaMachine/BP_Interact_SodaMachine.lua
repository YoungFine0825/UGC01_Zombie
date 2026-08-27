---@class BP_Interact_SodaMachine_C:BP_InteractableBase_C
---@field PointLight2 UPointLightComponent
---@field PointLight1 UPointLightComponent
---@field InteractBehaviour_PurchaseSoda InteractBehaviour_PurchaseSoda_C
---@field PointLight UPointLightComponent
--Edit Below--

local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_SodaMachine_C
local BP_Interact_SodaMachine = BPExtent({},"Script.Blueprint.InteractEntity.BP_InteractableBase")

 
--[[--]]
function BP_Interact_SodaMachine:ReceiveBeginPlay()
    BP_Interact_SodaMachine.SuperClass.ReceiveBeginPlay(self)
end


--[[--]]
function BP_Interact_SodaMachine:ReceiveTick(DeltaTime)
    BP_Interact_SodaMachine.SuperClass.ReceiveTick(self, DeltaTime)
end


--[[--]]
function BP_Interact_SodaMachine:ReceiveEndPlay()
    BP_Interact_SodaMachine.SuperClass.ReceiveEndPlay(self) 
end


--[[
function BP_Interact_SodaMachine:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_SodaMachine:GetAvailableServerRPCs()
    return
end
--]]


return BP_Interact_SodaMachine
