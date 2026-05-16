---@class skillAlevel1_C:PESkillTemplate_Indicate_C
--Edit Below--
local skillAlevel1 = {}
 
function skillAlevel1:OnEnableSkill_BP()
    skillAlevel1.SuperClass.OnEnableSkill_BP(self)
end

function skillAlevel1:OnDisableSkill_BP()
    skillAlevel1.SuperClass.OnDisableSkill_BP(self)
end

function skillAlevel1:OnActivateSkill_BP()
    --UGCWeaponManagerSystem.CurrentWeaponAttachToBack(self.Owner.Owner)
    skillAlevel1.SuperClass.OnActivateSkill_BP(self)
end

function skillAlevel1:OnDeActivateSkill_BP()
    skillAlevel1.SuperClass.OnDeActivateSkill_BP(self)
end

function skillAlevel1:CanActivateSkill_BP()
    return skillAlevel1.SuperClass.CanActivateSkill_BP(self)
end

return skillAlevel1