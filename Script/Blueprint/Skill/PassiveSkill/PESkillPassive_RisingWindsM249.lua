---@class PESkillPassive_RisingWindsM249_C:PESkillPassiveSkillTemplate_C
---@field RecoveryItemID int32
---@field RecoveryItemCount int32
---@field ActorDetectFilter TArray<UClass*>
---@field HitCountThreshold int32
--Edit Below--
local PESkillPassive_RisingWindsM249 = {
    HitCount = 0
}
 
function PESkillPassive_RisingWindsM249:OnEnableSkill_BP()
    ugcprint("PESkillPassive_RisingWindsM249:OnEnableSkill_BP()----------------------1")
    self.SuperClass.OnEnableSkill_BP(self)
end

function PESkillPassive_RisingWindsM249:OnDisableSkill_BP()
    self.SuperClass.OnDisableSkill_BP(self)
end

function PESkillPassive_RisingWindsM249:OnActivateSkill_BP()
    self.SuperClass.OnActivateSkill_BP(self)
    ugcprint("PESkillPassive_RisingWindsM249:OnActivateSkill_BP()")

    if UGCGameSystem.IsServer() then
        self.HitCount = self.HitCount + 1
        if self.HitCount == self.HitCountThreshold then
            -- 回复道具
            UGCBackPackSystem.AddItem(self:GetOwnerActor(),self.RecoveryItemID,self.RecoveryItemCount)
            self.HitCount = 0
        end
    end
    
end

function PESkillPassive_RisingWindsM249:OnDeActivateSkill_BP()
    self.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkillPassive_RisingWindsM249:CanActivateSkill_BP()
    if self.SuperClass.CanActivateSkill_BP(self) then
        local TargetActors = self:GetSelectTargetActor(EPESkillSelectTarget.E_PESKILL_PickerType_AllTarget)
        -- 武器命中事件一次塞一个目标进去
        if TargetActors:Num() >= 1 then
            local TargetActor = TargetActors:Get(1)
            ugcprint("PESkillPassive_RisingWindsM249:CanActivateSkill_BP() TargetActor"..tostring(TargetActor))
            if TargetActor ~= nil then
                for _ , ActorClass in pairs(self.ActorDetectFilter) do 
                    if UGCObjectUtility.IsA(TargetActor, ActorClass) then
                        return true
                    end
                end
            end
        else
            ugcprint("PESkillPassive_RisingWindsM249:CanActivateSkill_BP() [TargetActors:Num()<1]")
        end
    end
    return false
    -- return self.SuperClass.CanActivateSkill_BP(self)
end

return PESkillPassive_RisingWindsM249