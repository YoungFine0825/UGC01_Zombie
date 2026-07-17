---@class BTTask_Zombie_Base_C:BTTask_LuaBase
--Edit Below--
local BTTask_Zombie_Base = {
    ---@type AAIController
    OwnerController = nil,
    ---@type BP_Zombie_Base_C
    ControlledPawn = nil,
}

--- 任务执行入口点
-- 当任务被行为树激活时调用，任务将保持活动状态直到调用 FinishExecute()
---@param OwnerController AAIController 拥有此任务节点的AI控制器
---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
function BTTask_Zombie_Base:ReceiveExecuteAI(OwnerController, ControlledPawn)
    self.OwnerController = OwnerController
    self.ControlledPawn = ControlledPawn
end

-- --- 任务Tick函数
-- -- 当任务处于活动状态时每帧调用
-- ---@param OwnerController AAIController 拥有此任务节点的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- ---@param DeltaSeconds float 自上一帧以来的时间（秒）
-- function BTTask_Zombie_Base:ReceiveTickAI(OwnerController, ControlledPawn, DeltaSeconds)
--     -- 在此实现每帧逻辑
--     -- 注意：任务需保持活动状态才会触发Tick
-- end

-- --- 任务中止事件
-- -- 当任务被外部中断时调用（如装饰器条件失败）
-- ---@param OwnerController AAIController 拥有此任务节点的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTTask_Zombie_Base:ReceiveAbortAI(OwnerController, ControlledPawn)
--     -- 完成中止流程
-- 	self:FinishAbort()
-- end

---@public
---@return UBlackboardComponent
function BTTask_Zombie_Base:GetBlackboard(OwnerController)
    local aiController = OwnerController or self.OwnerController
    local blackboard = UGCGenericCharacterSystem.GetBlackboard(aiController)
    return blackboard
end

---@public
---@return BP_EntryForZombie_Base_C
function BTTask_Zombie_Base:GetEntryActor(OwnerController)
    local blackboard = self:GetBlackboard(OwnerController)
    if blackboard then
        ---@type BP_EntryForZombie_Base_C
        local entryActor = blackboard:GetValueAsObject("EntryActor")
        if UE.IsValid(entryActor) then
            return entryActor
        else
            GameplayUtils.Exception("BTTask_Zombie_Base.GetEntryActor: EntryActor已经失效！")
        end
    else
        GameplayUtils.Exception("BTTask_Zombie_Base.GetEntryActor: 获取Blackboard失败！")
    end
    return nil
end

return BTTask_Zombie_Base