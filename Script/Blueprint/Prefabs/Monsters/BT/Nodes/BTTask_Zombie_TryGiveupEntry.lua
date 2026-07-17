---@class BTTask_Zombie_TryGiveupEntry_C:BTTask_Zombie_Base_C
--Edit Below--
local BTTask_Zombie_TryGiveupEntry = {}

--- 任务执行入口点
-- 当任务被行为树激活时调用，任务将保持活动状态直到调用 FinishExecute()
---@param OwnerController AAIController 拥有此任务节点的AI控制器
---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
function BTTask_Zombie_TryGiveupEntry:ReceiveExecuteAI(OwnerController, ControlledPawn)

    BTTask_Zombie_TryGiveupEntry.SuperClass.ReceiveExecuteAI(self,OwnerController,ControlledPawn)

    GameplayUtils.Print("BTTask_Zombie_TryGiveupEntry.ReceiveExecuteAI: 放弃丧尸已选定的入口")

    GameplaySystem.MonsterAISystem:ServerGiveupZombieEntryPositionSlot(ControlledPawn)

    local blackboard = GameplaySystem.MonsterAISystem:GetBlackboard(OwnerController)
    blackboard:ClearValue("EntryActor")
    blackboard:ClearValue("EntrySpline")
    blackboard:ClearValue("EntryPosition")
    blackboard:ClearValue("EntryPosSlotIndex")
    blackboard:ClearValue("OrderNumOfThroughEntry")
    --注意bShouldThroughEntry不需要清理，只有当丧尸成功穿过入口后才会清理

    -- 立即完成任务并返回成功状态
    self:FinishExecute(true)
end

-- --- 任务Tick函数
-- -- 当任务处于活动状态时每帧调用
-- ---@param OwnerController AAIController 拥有此任务节点的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- ---@param DeltaSeconds float 自上一帧以来的时间（秒）
-- function BTTask_Zombie_TryGiveupEntry:ReceiveTickAI(OwnerController, ControlledPawn, DeltaSeconds)
--     -- 在此实现每帧逻辑
--     -- 注意：任务需保持活动状态才会触发Tick
-- end

-- --- 任务中止事件
-- -- 当任务被外部中断时调用（如装饰器条件失败）
-- ---@param OwnerController AAIController 拥有此任务节点的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTTask_Zombie_TryGiveupEntry:ReceiveAbortAI(OwnerController, ControlledPawn)
--     -- 完成中止流程
-- 	self:FinishAbort()
-- end

return BTTask_Zombie_TryGiveupEntry