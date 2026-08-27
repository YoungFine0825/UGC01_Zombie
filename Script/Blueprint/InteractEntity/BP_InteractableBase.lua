---@class BP_InteractableBase_C:AActor
---@field InteractEntityComponent BP_InteractEntityComponent_C
---@field MainCollision UBoxComponent
---@field Mesh0 UStaticMeshComponent
---@field InteractTrigger UCustomBoxCollisionComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
---@type BP_InteractableBase_C
local BP_InteractableBase = {}
 
--[[--]]
function BP_InteractableBase:ReceiveBeginPlay()
    GameplayUtils.Print("BP_InteractableBase ",UGCObjectUtility.GetObjectName(self)," ReceiveBeginPlay！！！")
    BP_InteractableBase.SuperClass.ReceiveBeginPlay(self)
    --if self.InteractEntityComponent then
    --    if self.InteractEntityComponent.InitComponent then
    --        self.InteractEntityComponent:InitComponent()
    --    else
    --        local metatable = getmetatable(self.InteractEntityComponent)
    --        for k,v in pairs(metatable or {})  do
    --            GameplayUtils.Print("BP_InteractableBase.InteractEntityComponent ",k," : ",tostring(v))
    --        end
    --    end
    --else
    --    GameplayUtils.Exception("BP_InteractableBase.ReceiveBeginPlay: InteractEntityComponent is nil!")
    --end
end


--[[--]]
function BP_InteractableBase:ReceiveTick(DeltaTime)
    BP_InteractableBase.SuperClass.ReceiveTick(self, DeltaTime)
end


--[[--]]
function BP_InteractableBase:ReceiveEndPlay()
    BP_InteractableBase.SuperClass.ReceiveEndPlay(self) 
end


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