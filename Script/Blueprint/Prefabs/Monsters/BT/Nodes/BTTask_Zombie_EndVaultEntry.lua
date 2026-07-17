---@class BTTask_Zombie_EndVaultEntry_C:BTTask_Zombie_Base_C
--Edit Below--
local BTTask_Zombie_EndVaultEntry = {}

--- 任务执行入口点
-- 当任务被行为树激活时调用，任务将保持活动状态直到调用 FinishExecute()
---@param OwnerController AAIController 拥有此任务节点的AI控制器
---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
function BTTask_Zombie_EndVaultEntry:ReceiveExecuteAI(OwnerController, ControlledPawn)
    BTTask_Zombie_EndVaultEntry.SuperClass.ReceiveExecuteAI(self,OwnerController,ControlledPawn)
    --
    -- GameplayUtils.Print("BTTask_Zombie_EndVaultEntry.ReceiveExecuteAI: 穿过入口结束！")
    --
    ---@type UBlackboardComponent
    local blackboard = UGCGenericCharacterSystem.GetBlackboard(OwnerController)
    if blackboard then
        ---@type BP_Zombie_Base_C
        local zombieActor = ControlledPawn
        --放弃站位
        GameplaySystem.MonsterAISystem:ServerGiveupZombieEntryPositionSlot(zombieActor)
        --丧尸穿过入口后，就不再需要寻找入口
        zombieActor:ServerShouldFindEntry(false)
        zombieActor:ServerSetTargetEntry(nil)
        --
        ---@type USplineComponent
        local splineComp = blackboard:GetValueAsObject("EntrySpline")
        local finalLocation = splineComp:GetWorldLocationAtTime(1)
        --重新映射导航网格坐标
        zombieActor:ModifyNavLocation(finalLocation)
        --
        zombieActor:EnableCollision(true)
        --
        UGCTimerUtility.CreateLuaTimer(0.2, function()
            if not UE.IsValid(zombieActor) then
                return
            end
            zombieActor:EnableMovement(true)
            --重新映射导航网格坐标
            --zombieActor:ModifyNavLocation(finalLocation)
            --zombieActor:SetCanAffectNavigationGeneration(true,true)
            --重新选择目标
            local targetPlayer = GameplaySystem.MonsterAISystem:ServerFindNearstPlayerAsTarget(zombieActor)
            zombieActor:ServerTrackingPlayer(targetPlayer)
            zombieActor:MoveToActor(targetPlayer)
            --zombieActor:RunBehaviourTree()

        end, false)

        --清理入口相关黑板值
        blackboard:ClearValue("bShouldThroughEntry")
        blackboard:ClearValue("EntryActor")
        blackboard:ClearValue("EntrySpline")
        blackboard:ClearValue("EntryPosition")
        blackboard:ClearValue("EntryPosSlotIndex")
        blackboard:ClearValue("OrderNumOfThroughEntry")
        blackboard:ClearValue("bIsVaultingEntry")
    else
        GameplayUtils.Print("BTTask_Zombie_EndVaultEntry.ReceiveExecuteAI: 获取Blackboard失败！")
    end
    -- 立即完成任务并返回成功状态
    self:FinishExecute(true)
end

-- --- 任务Tick函数
-- -- 当任务处于活动状态时每帧调用
-- ---@param OwnerController AAIController 拥有此任务节点的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- ---@param DeltaSeconds float 自上一帧以来的时间（秒）
-- function BTTask_Zombie_EndVaultEntry:ReceiveTickAI(OwnerController, ControlledPawn, DeltaSeconds)
--     -- 在此实现每帧逻辑
--     -- 注意：任务需保持活动状态才会触发Tick
-- end

-- --- 任务中止事件
-- -- 当任务被外部中断时调用（如装饰器条件失败）
-- ---@param OwnerController AAIController 拥有此任务节点的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTTask_Zombie_EndVaultEntry:ReceiveAbortAI(OwnerController, ControlledPawn)
--     -- 完成中止流程
-- 	self:FinishAbort()
-- end

return BTTask_Zombie_EndVaultEntry