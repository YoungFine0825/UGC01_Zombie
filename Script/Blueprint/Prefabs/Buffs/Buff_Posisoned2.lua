---@class Buff_Posisoned2_C:PersistEffectBuff
--Edit Below--
local Buff_Posisoned2 = {}
 
-- buff启动条件
--[[
function Buff_Posisoned2:CanApply_BP(OwnerActor)
-- return true
end
--]]

-- buff开始
--[[
function Buff_Posisoned2:OnApply_BP(OwnerActor)

end
--]]

-- buff结束
--[[
function Buff_Posisoned2:OnUnApply_BP(OwnerActor, Reason)

end
--]]

-- buff合并条件，A为当前身上已有buff，B为外来buff，当要挂载外来buff时会判断A.CanMerge(B)
--[[
function Buff_Posisoned2:CanMerge_BP(PersistEffect)
-- return true
end
--]]

-- buff合并，A为当前身上已有buff，B为外来buff，调用A.OnMerge(B)
--[[
function Buff_Posisoned2:OnMerge_BP(PersistEffect)

end
--]]

-- 开启Tick需要SetTickEnable(true)，或buff为间隔触发类型会自动开启
--[[
function Buff_Posisoned2:Tick_BP(OwnerActor, DeltaTime)

end
--]]

--[[
function Buff_Posisoned2:OnInterrupted_BP(OwnerActor)

end
--]]

-- buff总持续时长变化，如修改ApplyTime、修改StackNum
--[[
function Buff_Posisoned2:OnTotalDurationChange_BP(PreTime, CurTime)

end
--]]

-- buff堆叠层数变化
--[[
function Buff_Posisoned2:OnStackChange_BP(PreNum, CurNum)

end
--]]

-- buff触发前条件判断
--[[
function Buff_Posisoned2:CanTrigger_BP()
	return true
end
--]]

-- buff触发效果
--[[
function Buff_Posisoned2:OnTrigger_BP(Delta)

end
--]]

return Buff_Posisoned2