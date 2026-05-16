---@class PESkillPassive_BreakerScar_C:PESkillPassiveSkillTemplate_C
---@field ShotEnhanceInterval int32
---@field BulletDamageEnhance FString
--Edit Below--
local PESkillPassive_BreakerScar = {
    FiredShotsCount = 0,
    TargetWeapon = nil
}
 
function PESkillPassive_BreakerScar:OnEnableSkill_BP()
    self.SuperClass.OnEnableSkill_BP(self)
end



function PESkillPassive_BreakerScar:OnDisableSkill_BP()
    self.SuperClass.OnDisableSkill_BP(self)
end



function PESkillPassive_BreakerScar:OnActivateSkill_BP()
    ugcprint("PESkillPassive_BreakerScar:OnActivateSkill_BP()")
    self.SuperClass.OnActivateSkill_BP(self)

    if UGCGameSystem.IsServer() then
        if self.TargetWeapon == nil then
            self.TargetWeapon = UGCWeaponManagerSystem.GetCurrentWeapon(UGCActorComponentUtility.GetOwner(UGCActorComponentUtility.GetOwner(self)))
        end
        
        self.FiredShotsCount = self.FiredShotsCount + 1
        
        if self.FiredShotsCount == self.ShotEnhanceInterval then
            -- 子弹伤害加成
            UGCAttributeSystem.AddGameAttributeValue(self.TargetWeapon, 'WeaponAttackRatio', self.BulletDamageEnhance)
        elseif self.FiredShotsCount == self.ShotEnhanceInterval + 1 then
            -- 恢复子弹伤害加成
            self.FiredShotsCount = 1
            UGCAttributeSystem.AddGameAttributeValue(self.TargetWeapon, 'WeaponAttackRatio', - self.BulletDamageEnhance)
        end
    end

    
end

function PESkillPassive_BreakerScar:OnDeActivateSkill_BP()
    self.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkillPassive_BreakerScar:CanActivateSkill_BP()
    return self.SuperClass.CanActivateSkill_BP(self)
end

return PESkillPassive_BreakerScar