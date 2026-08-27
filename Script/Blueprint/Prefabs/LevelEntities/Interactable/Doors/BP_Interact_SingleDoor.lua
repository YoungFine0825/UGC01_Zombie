---@class BP_Interact_SingleDoor_C:BP_Interact_LevelObstacle_C
---@field InteractBehaviour_PlayDoTween InteractBehaviour_PlayDoTween_C
---@field DoTweenDoor BP_DoTween_C
--Edit Below--

local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_SingleDoor_C
local BP_Interact_SingleDoor = BPExtent({},"Script.Blueprint.Prefabs.LevelEntities.Interactable.BP_Interact_LevelObstacle")

 
--[[--]]
function BP_Interact_SingleDoor:ReceiveBeginPlay()
    BP_Interact_SingleDoor.SuperClass.ReceiveBeginPlay(self)
    self.DoTweenDoor.Target = self.Mesh0
end


--[[
function BP_Interact_SingleDoor:ReceiveTick(DeltaTime)
    BP_Interact_SingleDoor.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function BP_Interact_SingleDoor:ReceiveEndPlay()
    BP_Interact_SingleDoor.SuperClass.ReceiveEndPlay(self) 
end


--[[
function BP_Interact_SingleDoor:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_SingleDoor:GetAvailableServerRPCs()
    return
end
--]]


return BP_Interact_SingleDoor
