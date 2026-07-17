---@class BTService_Zombie_GetTarget_C:BTAttachment_LuaBase
--Edit Below--
local BTService_Zombie_GetTarget = {}

--- Tick函数
-- 当服务处于活动状态时每帧调用
---@param OwnerController AAIController 拥有此服务的AI控制器
---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
---@param DeltaSeconds float 自上一帧以来的时间（秒）
function BTService_Zombie_GetTarget:ReceiveTickAI(OwnerController, ControlledPawn, DeltaSeconds)
    -- 在此实现每帧逻辑
    ---@type BP_Zombie_Base_C
    local zombiePawn = ControlledPawn
    local targetPlayer = zombiePawn:ServerGetCurrentTargetPlayer()
    if targetPlayer then
        local blackboard = OwnerController.Blackboard
        local playerState = GameplaySystem.PlayerSystem:GetPlayerAliveState(targetPlayer)
        if playerState ~= EPlayerAliveState.Alive then
            GameplayUtils.Print("BTService_Zombie_GetTarget.ReceiveTickAI: 目标玩家已死亡，寻找其他目标！")
            local alivePlayer = GameplaySystem.MonsterAISystem:ServerFindNearstPlayerAsTarget(ControlledPawn)
            zombiePawn:ServerTrackingPlayer(alivePlayer)
            if not alivePlayer then
                GameplayUtils.Print("BTService_Zombie_GetTarget.ReceiveTickAI: 未找到目标玩家")
            end
        else
            blackboard:SetValueAsObject("Target", targetPlayer)
        end
    else
        local alivePlayer = GameplaySystem.MonsterAISystem:ServerFindNearstPlayerAsTarget(ControlledPawn)
        if alivePlayer then
            zombiePawn:ServerTrackingPlayer(alivePlayer)
        else
            GameplayUtils.Print("BTService_Zombie_GetTarget.ReceiveTickAI: 未找到目标玩家")
        end
    end
end

--- 服务激活事件
-- 当服务首次附加到行为树节点时调用
---@param OwnerController AAIController 拥有此服务的AI控制器
---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
function BTService_Zombie_GetTarget:ReceiveActivationAI(OwnerController, ControlledPawn)
    -- 在此实现初始化逻辑

end

-- --- 服务停用事件
-- -- 当服务从行为树节点分离时调用
-- ---@param OwnerController AAIController 拥有此服务的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTService_Zombie_GetTarget:ReceiveDeactivationAI(OwnerController, ControlledPawn)
--     -- 在此实现清理逻辑
-- end

-- --- 搜索开始事件
-- -- 当行为树开始搜索当前分支时调用
-- ---@param OwnerController AAIController 拥有此服务的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTService_Zombie_GetTarget:ReceiveSearchStartAI(OwnerController, ControlledPawn)
--     -- 在此实现分支搜索前的准备工作
-- end

return BTService_Zombie_GetTarget