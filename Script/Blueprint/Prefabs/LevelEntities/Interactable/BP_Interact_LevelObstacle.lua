---@class BP_Interact_LevelObstacle_C:BP_InteractableBase_C
---@field InteractBehaviour_ActivateZombieSpawners InteractBehaviour_ActivateZombieSpawners_C
---@field InteractBehaviour_LinkUnlockObstacle InteractBehaviour_LinkUnlockObstacle_C
---@field InteractBehaviour_ActivateZombieEntries InteractBehaviour_ActivateZombieEntries_C
---@field DynamicObstacleAvoidance UDynamicObstacleAvoidanceComponent
---@field InteractBehaviour_SetVisible InteractBehaviour_SetVisible_C
---@field InteractBehaviour_DeductPropertyValue InteractBehaviour_DeductPropertyValue_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_LevelObstacle_C
local BP_Interact_LevelObstacle = BPExtent({},"Script.Blueprint.InteractEntity.BP_InteractableBase")
 
--[[--]]
function BP_Interact_LevelObstacle:ReceiveBeginPlay()
    BP_Interact_LevelObstacle.SuperClass.ReceiveBeginPlay(self)
    GameplaySystem.EventSystem:Listen(GameplayEvents.Global.OnPlayerInteractCompleted,self,self.OnInteractionCompleted)
end


--[[
function BP_Interact_LevelObstacle:ReceiveTick(DeltaTime)
    BP_Interact_LevelObstacle.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function BP_Interact_LevelObstacle:ReceiveEndPlay()
    BP_Interact_LevelObstacle.SuperClass.ReceiveEndPlay(self)
    GameplaySystem.EventSystem:UnlistenAll(self)
end


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

---@private
function BP_Interact_LevelObstacle:OnInteractionCompleted(playkey,instanceID,errCode)
    if not UGCGameSystem.IsServer() then
        return
    end
    if instanceID ~= self.InteractEntityComponent:GetInstanceID() or errCode ~= EInteractEntityErrCode.None then
        return
    end
    --
    local loc = self:K2_GetActorLocation()
    -- 取 MainCollision 碰撞体 BoxExtent（半尺寸）三轴最大值作为更新范围半径
    local halfSize = 500
    if self.MainCollision then
        local ext = self.MainCollision:GetScaledBoxExtent()
        halfSize = math.max(ext.X, ext.Y, ext.Z)
    end
    local min = UGCMathUtility.MakeVector(loc.X - halfSize, loc.Y - halfSize, loc.Z - halfSize)
    local max = UGCMathUtility.MakeVector(loc.X + halfSize, loc.Y + halfSize, loc.Z + halfSize)
    local Fbox = UGCMathUtility.MakeBox(min,max)
    GameplaySystem.NavigationSystem:AddDynamicNavAffect(Fbox)
end


return BP_Interact_LevelObstacle