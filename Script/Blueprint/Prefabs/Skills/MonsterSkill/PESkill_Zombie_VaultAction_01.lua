---@class PESkill_Zombie_VaultAction_01_C:PESkillTemplate_Base_C
--Edit Below--
local PESkill_Zombie_VaultAction_01 = {}
 
function PESkill_Zombie_VaultAction_01:OnEnableSkill_BP()
    PESkill_Zombie_VaultAction_01.SuperClass.OnEnableSkill_BP(self)
end

function PESkill_Zombie_VaultAction_01:OnDisableSkill_BP()
    PESkill_Zombie_VaultAction_01.SuperClass.OnDisableSkill_BP(self)
end

function PESkill_Zombie_VaultAction_01:OnActivateSkill_BP()
    PESkill_Zombie_VaultAction_01.SuperClass.OnActivateSkill_BP(self)
end

function PESkill_Zombie_VaultAction_01:OnDeActivateSkill_BP()
    PESkill_Zombie_VaultAction_01.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkill_Zombie_VaultAction_01:CanActivateSkill_BP()
    return PESkill_Zombie_VaultAction_01.SuperClass.CanActivateSkill_BP(self)
end

return PESkill_Zombie_VaultAction_01