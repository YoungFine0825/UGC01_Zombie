---@class BP_Interact_LevelObstacle_Prop_C:BP_Interact_LevelObstacle_C
---@field InteractBehaviour_PlayDoTween InteractBehaviour_PlayDoTween_C
---@field DoTween BP_DoTween_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_LevelObstacle_Prop_C
local BP_Interact_LevelObstacle_Prop = BPExtent({},"Script.Blueprint.Prefabs.LevelEntities.Interactable.BP_Interact_LevelObstacle")
 
--[[--]]
function BP_Interact_LevelObstacle_Prop:ReceiveBeginPlay()
    BP_Interact_LevelObstacle_Prop.SuperClass.ReceiveBeginPlay(self)
    self.DoTween.Target = self.Mesh0
end


--[[
function BP_Interact_LevelObstacle_Prop:ReceiveTick(DeltaTime)
    BP_Interact_LevelObstacle_Prop.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Interact_LevelObstacle_Prop:ReceiveEndPlay()
    BP_Interact_LevelObstacle_Prop.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Interact_LevelObstacle_Prop:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_LevelObstacle_Prop:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_LevelObstacle_Prop