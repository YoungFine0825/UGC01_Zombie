---@class skillAlevel2_C:PESkillTemplate_Indicate_C
--Edit Below--
local skillAlevel2 = {}
 
function skillAlevel2:OnEnableSkill_BP()
    skillAlevel2.SuperClass.OnEnableSkill_BP(self)
end

function skillAlevel2:OnDisableSkill_BP()
    skillAlevel2.SuperClass.OnDisableSkill_BP(self)
end

function skillAlevel2:OnActivateSkill_BP()
    --UGCWeaponManagerSystem.CurrentWeaponAttachToBack(self.Owner.Owner)
    skillAlevel2.SuperClass.OnActivateSkill_BP(self)
end

function skillAlevel2:OnDeActivateSkill_BP()
    skillAlevel2.SuperClass.OnDeActivateSkill_BP(self)
end

function skillAlevel2:CanActivateSkill_BP()
    return skillAlevel2.SuperClass.CanActivateSkill_BP(self)
end

return skillAlevel2