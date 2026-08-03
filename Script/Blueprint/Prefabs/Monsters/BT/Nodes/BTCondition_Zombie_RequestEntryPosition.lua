---@class BTCondition_Zombie_RequestEntryPosition_C:BTCondition_Zombie_Base_C
--Edit Below--
local BTCondition_Zombie_RequestEntryPosition = {}

--- 执行条件检查
-- 当行为树需要测试装饰器条件是否满足时调用
---@param OwnerController AAIController 拥有此装饰器的AI控制器
---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
---@return boolean 条件检查结果：true表示条件满足，false表示条件不满足
function BTCondition_Zombie_RequestEntryPosition:PerformConditionCheckAI(OwnerController, ControlledPawn)
    BTCondition_Zombie_RequestEntryPosition.SuperClass.PerformConditionCheckAI(self,OwnerController,ControlledPawn)

    ---@type BP_Zombie_Base_C
    local zombiePawn = ControlledPawn
    local oldPosSlot = zombiePawn:GetEntryPositionSlotIndex()
    local posSlotIndex,worldPos = GameplaySystem.MonsterAISystem:ServerRequestZombieEntryPositionSlot(ControlledPawn)
    if posSlotIndex > 0 then
        local blackboard = GameplaySystem.MonsterAISystem:GetBlackboard(OwnerController)
        blackboard:SetValueAsInt("EntryPosSlotIndex",posSlotIndex)
        blackboard:SetValueAsVector("EntryPosition",worldPos)
        --GameplayUtils.Print("BTCondition_Zombie_RequestEntryPosition.PerformConditionCheckAI: 请求入口站位成功！位置索引=",posSlotIndex)
        return true
    else
        --GameplayUtils.Print("BTCondition_Zombie_RequestEntryPosition.PerformConditionCheckAI: 请求入口站位失败！")
    end  

    return false
end

-- --- Tick函数
-- -- 当装饰器处于活动状态时每帧调用
-- ---@param OwnerController AAIController 拥有此装饰器的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- ---@param DeltaSeconds float 自上一帧以来的时间（秒）
-- function BTCondition_Zombie_RequestEntryPosition:ReceiveTickAI(OwnerController, ControlledPawn, DeltaSeconds)
--     ugcprint("BTCondition_Zombie_RequestEntryPosition:ReceiveTickAI")
-- end

-- --- 执行开始事件
-- -- 当装饰器附加的底层节点开始执行时调用
-- ---@param OwnerController AAIController 拥有此装饰器的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTCondition_Zombie_RequestEntryPosition:ReceiveExecutionStartAI(OwnerController, ControlledPawn)
--     ugcprint("BTCondition_Zombie_RequestEntryPosition:ReceiveExecutionStartAI")
-- end

-- --- 执行结束事件
-- -- 当装饰器附加的底层节点执行结束时调用
-- ---@param OwnerController AAIController 拥有此装饰器的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- ---@param NodeResult EBTNodeResult 底层节点的执行结果（成功/失败/中止）
-- function BTCondition_Zombie_RequestEntryPosition:ReceiveExecutionFinishAI(OwnerController, ControlledPawn, NodeResult)
--     ugcprint("BTCondition_Zombie_RequestEntryPosition:ReceiveExecutionFinishAI")
-- end

-- --- 观察者激活事件
-- -- 当装饰器作为观察者被激活时调用（条件从false变为true）
-- ---@param OwnerController AAIController 拥有此装饰器的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTCondition_Zombie_RequestEntryPosition:ReceiveObserverActivatedAI(OwnerController, ControlledPawn)
--     ugcprint("BTCondition_Zombie_RequestEntryPosition:ReceiveObserverActivatedAI")
-- end

-- --- 观察者停用事件
-- -- 当装饰器作为观察者被停用时调用（条件从true变为false或行为树终止观察）
-- ---@param OwnerController AAIController 拥有此装饰器的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTCondition_Zombie_RequestEntryPosition:ReceiveObserverDeactivatedAI(OwnerController, ControlledPawn)
--     ugcprint("BTCondition_Zombie_RequestEntryPosition:ReceiveObserverDeactivatedAI")
-- end

return BTCondition_Zombie_RequestEntryPosition