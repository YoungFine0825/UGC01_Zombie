---@class BP_InteractableBase_C:AActor
---@field MainCollision UBoxComponent
---@field Mesh0 UStaticMeshComponent
---@field InteractTrigger UCustomBoxCollisionComponent
---@field InteractEntityComponent BP_InteractEntityComponent_C
---@field DefaultSceneRoot USceneComponent
--Edit Below--
---@type BP_InteractableBase_C
local BP_InteractableBase = {}
 
--[[
function BP_InteractableBase:ReceiveBeginPlay()
    BP_InteractableBase.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_InteractableBase:ReceiveTick(DeltaTime)
    BP_InteractableBase.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_InteractableBase:ReceiveEndPlay()
    BP_InteractableBase.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_InteractableBase:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_InteractableBase:GetAvailableServerRPCs()
    return
end
--]]

---@public
---@return BP_InteractEntityComponent_C
function BP_InteractableBase:GetInteractComponent()
    return self.InteractEntityComponent
end

---@public
function BP_InteractableBase:PlayInterpMovement()

end

return BP_InteractableBase