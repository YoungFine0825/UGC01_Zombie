---@class PESkill_Monster_Claw_C:PESkillTemplate_Base_C
---@field SkillAnimationIndex int32
--Edit Below--
local PESkill_Monster_Claw = {}
 
function PESkill_Monster_Claw:OnEnableSkill_BP()
    PESkill_Monster_Claw.SuperClass.OnEnableSkill_BP(self)
end

function PESkill_Monster_Claw:OnDisableSkill_BP()
    PESkill_Monster_Claw.SuperClass.OnDisableSkill_BP(self)
end

function PESkill_Monster_Claw:OnActivateSkill_BP()
    PESkill_Monster_Claw.SuperClass.OnActivateSkill_BP(self)
end

function PESkill_Monster_Claw:OnDeActivateSkill_BP()
    PESkill_Monster_Claw.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkill_Monster_Claw:CanActivateSkill_BP()
    return PESkill_Monster_Claw.SuperClass.CanActivateSkill_BP(self)
end

return PESkill_Monster_Claw