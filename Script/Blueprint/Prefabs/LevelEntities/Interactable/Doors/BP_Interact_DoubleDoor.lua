---@class BP_Interact_DoubleDoor_C:BP_Interact_LevelObstacle_C
---@field InteractBehaviour_PlayDoTween InteractBehaviour_PlayDoTween_C
---@field DoTweenDoor02 BP_DoTween_C
---@field DoTweenDoor01 BP_DoTween_C
---@field Door01 UStaticMeshComponent
---@field Door02 UStaticMeshComponent
--Edit Below--

local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_DoubleDoor_C
local BP_Interact_DoubleDoor = BPExtent({},"Script.Blueprint.Prefabs.LevelEntities.Interactable.BP_Interact_LevelObstacle")

--[[--]]
function BP_Interact_DoubleDoor:ReceiveBeginPlay()
    BP_Interact_DoubleDoor.SuperClass.ReceiveBeginPlay(self)
    self.DoTweenDoor01.Target = self.Door01
    self.DoTweenDoor02.Target = self.Door02
end


--[[
function BP_Interact_DoubleDoor:ReceiveTick(DeltaTime)
    BP_Interact_DoubleDoor.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Interact_DoubleDoor:ReceiveEndPlay()
    BP_Interact_DoubleDoor.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Interact_DoubleDoor:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_DoubleDoor:GetAvailableServerRPCs()
    return
end
--]]


return BP_Interact_DoubleDoor
