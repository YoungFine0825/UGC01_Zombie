---@class PassiveSkill_CounterAttack_C:PESkillPassiveSkillTemplate_C
--Edit Below--
local PassiveSkill_CounterAttack = {}
 
function PassiveSkill_CounterAttack:OnEnableSkill_BP()
    self.SuperClass.OnEnableSkill_BP(self)
end

function PassiveSkill_CounterAttack:OnDisableSkill_BP()
    self.SuperClass.OnDisableSkill_BP(self)
end

function PassiveSkill_CounterAttack:OnActivateSkill_BP()
    self.SuperClass.OnActivateSkill_BP(self)
end

function PassiveSkill_CounterAttack:OnDeActivateSkill_BP()
    self.SuperClass.OnDeActivateSkill_BP(self)
end

function PassiveSkill_CounterAttack:CanActivateSkill_BP()
    return self.SuperClass.CanActivateSkill_BP(self)
end

-- 被动技能开始
function PassiveSkill_CounterAttack:ListenDamageEvent()
    local CurrentCharacter = self:GetOwnerActor()
    if not UGCObjectUtility.IsObjectValid(CurrentCharacter) then
        ugcprint("[PassiveSkill_CounterAttack] ListenDamageEvent: Skill Owner is invalid.")
        return
    end

    UGCGenericMessageSystem.ListenObjectMessage(CurrentCharacter, "UGC.MobPawn.PreTakeDamage", self, self.BeAttactedBy)
    UGCGenericMessageSystem.ListenObjectMessage(CurrentCharacter, "UGC.PlayerPawn.PreTakeDamage", self, self.BeAttactedBy)
end

function PassiveSkill_CounterAttack:BeAttactedBy(Victim, DamageCauser, EventInstigator, Damage, DamageContext)
    local CurrentCharacter = self:GetOwnerActor()
    if not UGCObjectUtility.IsObjectValid(CurrentCharacter) then
        ugcprint("[PassiveSkill_CounterAttack] BeAttactedBy: Skill Owner is invalid.")
        return
    end

    -- 检查是否是反伤类型的伤害，反伤类型的伤害不要继续反伤！
    local CounterAttack = false
    for _, Tag in pairs(DamageContext.DamageTypeTags) do
        if Tag.TagName == "UGC.Damage.Type.CounterAttack" then
            CounterAttack = true
            break
        end
    end

    ugcprint("[PassiveSkill_CounterAttack] damage is: "..tostring(Damage)..', CounterAttack: '..tostring(CounterAttack)..", VictimPlayer:"..tostring(Victim)..", Context: "..tostring(#DamageContext.ResultTags))

    if CounterAttack then
        return
    end

    -- 非敌对阵营不反伤
    local CampRelation = UGCCampSystem.GetCampRelationWithActor(CurrentCharacter, EventInstigator:K2_GetPawn())
    if CampRelation ~= ECampRelation.Enemy then
        return
    end

    local CounterAttackTag = UGCGameplayTagSystem.RequestGameplayTag("UGC.Damage.Type.CounterAttack")
    ugcprint("[PassiveSkill_CounterAttack] CounterAttackTag is: "..tostring(CounterAttackTag))
    if CounterAttackTag then
        if EventInstigator and (Damage > 0) then
            local CounterAttackRatio = UGCAttributeSystem.GetGameAttributeValue(CurrentCharacter, 'CounterAttackRatio')
            local AttackBoost = UGCAttributeSystem.GetGameAttributeValue(CurrentCharacter, 'SkillDamageRatio') --角色攻击力加成
            ugcprint("[PassiveSkill_CounterAttack] CounterAttackRatio is: "..tostring(CounterAttackRatio)..', Boost: '..tostring(AttackBoost))
            if CounterAttackRatio > 0 then
                local CounterDamage = Damage * CounterAttackRatio * (1 + AttackBoost)                            
                local DamageTypeTags = {CounterAttackTag}
                UGCGameSystem.ApplyDamage(EventInstigator:K2_GetPawn(), CounterDamage, UGCGameSystem.GetControllerByPawn(CurrentCharacter), CurrentCharacter, DamageTypeTags)
                -- UGCAttributeSystem.AddGameAttributeValue(DamageCauser, 'Health', HealthStealRatio * Damage)
            end       
        end
    end
end


-- 被动技能结束
function PassiveSkill_CounterAttack:UnListenDamageEvent()
    UGCGenericMessageSystem.UnListenMessage(self, self.MonsterBeAttacted)
    UGCGenericMessageSystem.UnListenMessage(self, self.PlayerBeAttacted)

end

return PassiveSkill_CounterAttack