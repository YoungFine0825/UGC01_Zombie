---@class BTTask_Zombie_OnVaultEntry_C:UBTTask_LuaBase
---@--Edit Below--
local BTTask_Zombie_OnVaultEntry = {
    ---@type BP_Zombie_Base_C
    ControlledPawn = nil,
    ---@type USplineComponent
    SplineComp = nil,
    ---@type number
    Time = 0,
    
    Duration = 1.15,
}

--- 任务执行入口点
-- 当任务被行为树激活时调用，任务将保持活动状态直到调用 FinishExecute()
---@param OwnerController AAIController 拥有此任务节点的AI控制器
---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
function BTTask_Zombie_OnVaultEntry:ReceiveExecuteAI(OwnerController, ControlledPawn)
    -- TODO: 任务逻辑实现
    --接收Tick
    self.bNotifyTick = true
    --
    local blackboard = UGCGenericCharacterSystem.GetBlackboard(OwnerController)
    if blackboard then
        ---@type USplineComponent
        local splineComp = blackboard:GetValueAsObject("EntrySpline")
        if UE.IsValid(splineComp) then
            self.SplineComp = splineComp
            self.ControlledPawn = ControlledPawn
            ---@type BP_Zombie_Base_C
            local zombiePawn = ControlledPawn
            --关闭碰撞
            zombiePawn:EnableCollision(false)
            --暂停移动能力
            zombiePawn:EnableMovement(false)
            --
            GameplayUtils.Exception("BTTask_Zombie_OnVaultEntry.ReceiveExecuteAI: 准备完毕！")
        else
            GameplayUtils.Exception("BTTask_Zombie_OnVaultEntry.ReceiveExecuteAI: EntrySpline已经失效！")
            self:FinishExecute(false)
        end
    else
        GameplayUtils.Exception("BTTask_Zombie_OnVaultEntry.ReceiveExecuteAI: 获取Blackboard失败！")
        self:FinishExecute(false)
    end
end

--- 任务Tick函数
-- 当任务处于活动状态时每帧调用
---@param OwnerController AAIController 拥有此任务节点的AI控制器
---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
---@param DeltaSeconds float 自上一帧以来的时间（秒）
function BTTask_Zombie_OnVaultEntry:ReceiveTickAI(OwnerController, ControlledPawn, DeltaSeconds)
    -- 在此实现每帧逻辑
    -- 注意：任务需保持活动状态才会触发Tick
    local passedTime = self.Time + DeltaSeconds
    local t = passedTime / self.Duration
    self.Time = passedTime
    local location = self.SplineComp:GetWorldLocationAtTime(t)
    local rotation = self.SplineComp:GetWorldDirectionAtTime(t)
    ---@type APawn
    local actor = self.ControlledPawn
    actor:K2_SetActorLocation(location)
    if t >= 1 then
        GameplayUtils.Print("BTTask_Zombie_OnVaultEntry.ReceiveTickAI:翻越动画结束 ")
        --
        self.SplineComp = nil
        self.ControlledPawn = nil
        self:FinishExecute(true)
    end
end

--- 任务中止事件
-- 当任务被外部中断时调用（如装饰器条件失败）
---@param OwnerController AAIController 拥有此任务节点的AI控制器
---@param ControlledPawn APawn AI控制器当前控制的Pawn对象
function BTTask_Zombie_OnVaultEntry:ReceiveAbortAI(OwnerController, ControlledPawn)
    -- 完成中止流程
	self:FinishAbort()
end

return BTTask_Zombie_OnVaultEntry