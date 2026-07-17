---@class PESkill_Player_Melee_C:PESkillTemplate_Base_C
--Edit Below--
local PESkill_Player_Melee = {}
 
function PESkill_Player_Melee:OnEnableSkill_BP()
    PESkill_Player_Melee.SuperClass.OnEnableSkill_BP(self)
end

function PESkill_Player_Melee:OnDisableSkill_BP()
    PESkill_Player_Melee.SuperClass.OnDisableSkill_BP(self)
end

function PESkill_Player_Melee:OnActivateSkill_BP()
    PESkill_Player_Melee.SuperClass.OnActivateSkill_BP(self)
end

function PESkill_Player_Melee:OnDeActivateSkill_BP()
    PESkill_Player_Melee.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkill_Player_Melee:CanActivateSkill_BP()
    return PESkill_Player_Melee.SuperClass.CanActivateSkill_BP(self)
end

return PESkill_Player_Melee