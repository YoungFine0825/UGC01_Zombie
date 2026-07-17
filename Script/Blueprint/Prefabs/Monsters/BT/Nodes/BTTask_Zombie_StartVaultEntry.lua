---@class BTTask_Zombie_StartVaultEntry_C:UBTTask_LuaBase
---@--Edit Below--
local BTTask_Zombie_StartVaultEntry = {}

--- 任务执行入口点
-- 当任务被行为树激活时调用，任务将保持活动状态直到调用 FinishExecute()
---@param OwnerController AAIController 拥有此任务节点的AI控制器
---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
function BTTask_Zombie_StartVaultEntry:ReceiveExecuteAI(OwnerController, ControlledPawn)
    -- TODO: 任务逻辑实现
    local blackboard = UGCGenericCharacterSystem.GetBlackboard(OwnerController)
    if blackboard then
        ---@type BP_EntryForZombie_Base_C
        local entryActor = blackboard:GetValueAsObject("EntryActor")
        if UE.IsValid(entryActor) then
            local spline = entryActor:GetSpline()
            if spline then
                blackboard:SetValueAsObject("EntrySpline",spline)
                blackboard:SetValueAsBool("bIsVaultingEntry",true)
                -- GameplayUtils.Print("BTTask_Zombie_StartVaultEntry.ReceiveExecuteAI: 准备完毕！")
                return self:FinishExecute(true)
            else
                GameplayUtils.Print("BTTask_Zombie_StartVaultEntry.ReceiveExecuteAI: 无法获取EntryActor中的Spline！")
            end
        else
            GameplayUtils.Print("BTTask_Zombie_StartVaultEntry.ReceiveExecuteAI: EntryActor已经失效！")
        end
    else
        GameplayUtils.Print("BTTask_Zombie_StartVaultEntry.ReceiveExecuteAI: 获取Blackboard失败！")
    end
    self:FinishExecute(false)
end

-- --- 任务Tick函数
-- -- 当任务处于活动状态时每帧调用
-- ---@param OwnerController AAIController 拥有此任务节点的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- ---@param DeltaSeconds float 自上一帧以来的时间（秒）
-- function BTTask_Zombie_StartVaultEntry:ReceiveTickAI(OwnerController, ControlledPawn, DeltaSeconds)
--     -- 在此实现每帧逻辑
--     -- 注意：任务需保持活动状态才会触发Tick
-- end

-- --- 任务中止事件
-- -- 当任务被外部中断时调用（如装饰器条件失败）
-- ---@param OwnerController AAIController 拥有此任务节点的AI控制器
-- ---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
-- function BTTask_Zombie_StartVaultEntry:ReceiveAbortAI(OwnerController, ControlledPawn)
--     -- 完成中止流程
-- 	self:FinishAbort()
-- end

return BTTask_Zombie_StartVaultEntry