---@class Buff_DyingProtect_C:PersistEffectBuff
---@field EnableHealth float
--Edit Below--
local Buff_DyingProtect = {
    OwnerActor = nil
}
 


-- function Buff_DyingProtect:CanApply_BP(OwnerActor)
--     -- AttrModifyFunctionLibrary.GetGameAttributeValue()
-- --    AttrModifyFunctionLibrary.GetAttributeValue(OwnerActor,'Health')
-- --    if AttrModifyFunctionLibrary.GetAttributeValuePercentage(OwnerActor,'Health')
--     return true
-- end 





-- buff启动条件
--[[
function Buff_DyingProtect:CanApply_BP(OwnerActor)
-- return true
end
--]]

-- buff开始

function Buff_DyingProtect:OnApply_BP(OwnerActor)
    self.OwnerActor = OwnerActor
end


-- buff结束
--[[
function Buff_DyingProtect:OnUnApply_BP(OwnerActor, Reason)

end
--]]

-- buff合并条件，A为当前身上已有buff，B为外来buff，当要挂载外来buff时会判断A.CanMerge(B)
--[[
function Buff_DyingProtect:CanMerge_BP(PersistEffect)
-- return true
end
--]]

-- buff合并，A为当前身上已有buff，B为外来buff，调用A.OnMerge(B)
--[[
function Buff_DyingProtect:OnMerge_BP(PersistEffect)

end
--]]

-- 开启Tick需要SetTickEnable(true)，或buff为间隔触发类型会自动开启
--[[
function Buff_DyingProtect:Tick_BP(OwnerActor, DeltaTime)

end
--]]

--[[
function Buff_DyingProtect:OnInterrupted_BP(OwnerActor)

end
--]]

-- buff总持续时长变化，如修改ApplyTime、修改StackNum
--[[
function Buff_DyingProtect:OnTotalDurationChange_BP(PreTime, CurTime)

end
--]]

-- buff堆叠层数变化
--[[
function Buff_DyingProtect:OnStackChange_BP(PreNum, CurNum)

end
--]]

-- buff触发前条件判断

function Buff_DyingProtect:CanTrigger_BP()
    return AttrModifyFunctionLibrary.GetAttributeValuePercentage(self.OwnerActor,'Health') < self.EnableHealth
end


-- buff触发效果
--[[
function Buff_DyingProtect:OnTrigger_BP(Delta)
 
end

]]

return Buff_DyingProtect