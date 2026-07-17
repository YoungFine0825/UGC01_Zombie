---@class BP_Interact_LevelObstacle_C:BP_InteractableBase_C
---@field InteractBehaviour_SetVisible InteractBehaviour_SetVisible_C
---@field InteractBehaviour_DeductPropertyValue InteractBehaviour_DeductPropertyValue_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_LevelObstacle_C
local BP_Interact_LevelObstacle = BPExtent({},"Script.Blueprint.InteractEntity.BP_InteractableBase")
 
--[[
function BP_Interact_LevelObstacle:ReceiveBeginPlay()
    BP_Interact_LevelObstacle.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Interact_LevelObstacle:ReceiveTick(DeltaTime)
    BP_Interact_LevelObstacle.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Interact_LevelObstacle:ReceiveEndPlay()
    BP_Interact_LevelObstacle.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Interact_LevelObstacle:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_LevelObstacle:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_LevelObstacle