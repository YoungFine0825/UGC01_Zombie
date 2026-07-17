---@class BTService_Zombie_FindNearestEntry_C:BTService_Zombie_Base_C
--Edit Below--
local BTService_Zombie_FindNearestEntry = {}

--- Tick函数
-- 当服务处于活动状态时每帧调用
---@param OwnerController AAIController 拥有此服务的AI控制器
---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
---@param DeltaSeconds float 自上一帧以来的时间（秒）
function BTService_Zombie_FindNearestEntry:ReceiveTickAI(OwnerController, ControlledPawn, DeltaSeconds)
    -- 在此实现每帧逻辑
    ---@type BP_Zombie_Base_C
    local zombiePawn = ControlledPawn
    local blackboard = OwnerController.Blackboard
    ---@type BP_EntryForZombie_Base_C
    local entryActor = GameplaySystem.MonsterAISystem:ServerFindNearstEntry(ControlledPawn)
    if entryActor then
        zombiePawn:ServerSetTargetEntry(entryActor)
    else
        GameplayUtils.Print("BTService_Zombie_FindNearestEntry.ReceiveTickAI : 找不到最近的入口")
    end
end

-- --- 服务激活事件
-- -- 当服务首次附加到行为树节点时调用
-- ---@param OwnerController AAIController 拥有此服务的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTService_Zombie_FindNearestEntry:ReceiveActivationAI(OwnerController, ControlledPawn)
--     -- 在此实现初始化逻辑
-- end

-- --- 服务停用事件
-- -- 当服务从行为树节点分离时调用
-- ---@param OwnerController AAIController 拥有此服务的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTService_Zombie_FindNearestEntry:ReceiveDeactivationAI(OwnerController, ControlledPawn)
--     -- 在此实现清理逻辑
-- end

-- --- 搜索开始事件
-- -- 当行为树开始搜索当前分支时调用
-- ---@param OwnerController AAIController 拥有此服务的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTService_Zombie_FindNearestEntry:ReceiveSearchStartAI(OwnerController, ControlledPawn)
--     -- 在此实现分支搜索前的准备工作
-- end

return BTService_Zombie_FindNearestEntry