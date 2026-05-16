---@class Newskill1level1_C:PESkillTemplate_Active_C
--Edit Below--
local ToxicGrenade = {}
 
function ToxicGrenade:OnEnableSkill_BP()
    ToxicGrenade.SuperClass.OnEnableSkill_BP(self)

    ugcprint("ToxicGrenade:OnEnableSkill_BP")
end

function ToxicGrenade:OnDisableSkill_BP()
    ToxicGrenade.SuperClass.OnDisableSkill_BP(self)
end

function ToxicGrenade:OnActivateSkill_BP()
    --UGCWeaponManagerSystem.CurrentWeaponAttachToBack(self.Owner.Owner)
    ToxicGrenade.SuperClass.OnActivateSkill_BP(self)

    ugcprint("ToxicGrenade:OnActivateSkill_BP")
end

function ToxicGrenade:OnDeActivateSkill_BP()
    ToxicGrenade.SuperClass.OnDeActivateSkill_BP(self)
end

function ToxicGrenade:CanActivateSkill_BP()
    return ToxicGrenade.SuperClass.CanActivateSkill_BP(self)
end

return ToxicGrenade