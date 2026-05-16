---@class PassiveSkill_HealthSteal_C:PESkillPassiveSkillTemplate_C
--Edit Below--
local PassiveSkill_HealthSteal = {}
 
function PassiveSkill_HealthSteal:OnEnableSkill_BP()
    PassiveSkill_HealthSteal.SuperClass.OnEnableSkill_BP(self)
end

function PassiveSkill_HealthSteal:OnDisableSkill_BP()
    PassiveSkill_HealthSteal.SuperClass.OnDisableSkill_BP(self)
end

function PassiveSkill_HealthSteal:OnActivateSkill_BP()
    PassiveSkill_HealthSteal.SuperClass.OnActivateSkill_BP(self)
end

function PassiveSkill_HealthSteal:OnDeActivateSkill_BP()
    PassiveSkill_HealthSteal.SuperClass.OnDeActivateSkill_BP(self)
end

function PassiveSkill_HealthSteal:CanActivateSkill_BP()
    return PassiveSkill_HealthSteal.SuperClass.CanActivateSkill_BP(self)
end


-- 被动技能开始
function PassiveSkill_HealthSteal:ListenDamageEvent()
    local CurrentCharacter = self:GetOwnerActor()
    if not UGCObjectUtility.IsObjectValid(CurrentCharacter) then
        ugcprint("[PassiveSkill_CounterAttack] ListenDamageEvent: Skill Owner is invalid.")
        return
    end
    UGCGenericMessageSystem.ListenGlobalMessage(CurrentCharacter, "UGC.MobPawn.PostTakeDamage", self, self.MonsterBeAttacted)
    UGCGenericMessageSystem.ListenGlobalMessage(CurrentCharacter, "UGC.PlayerPawn.PostTakeDamage", self, self.PlayerBeAttacted)
end

-- 怪物被攻击
function PassiveSkill_HealthSteal:MonsterBeAttacted(MobPawn, DamageCauser, EventInstigator, Damage, DamageContext)
    ugcprint("[PassiveSkill_HealthSteal] damage is: "..tostring(Damage)..", EventInstigator:"..tostring(EventInstigator)..", Context: "..tostring(#DamageContext.ResultTags))

    if EventInstigator and (Damage > 0) then
        local CurrentCharacter = self:GetOwnerActor()
        local CauserPawn = EventInstigator:K2_GetPawn()
        if CauserPawn == CurrentCharacter then
            local HealthStealRatio = UGCAttributeSystem.GetGameAttributeValue(CauserPawn, 'HealthStealRatio')
            if HealthStealRatio > 0 then
                ugcprint("[PassiveSkill_HealthSteal] HealthStealRatio is: "..tostring(HealthStealRatio))
                UGCAttributeSystem.AddGameAttributeValue(CauserPawn, 'Health', HealthStealRatio * Damage)
            end 
        end
    end

end

-- 角色被攻击
---玩家角色受到伤害后（最终伤害计算后)
function PassiveSkill_HealthSteal:PlayerBeAttacted(VictimPlayer, DamageCauser, EventInstigator, Damage, DamageContext)
    ugcprint("[PassiveSkill_HealthSteal]  PlayerBeAttacted  damage is: "..tostring(Damage))
    if EventInstigator and (Damage > 0) then
        local CurrentCharacter = self:GetOwnerActor()
        local CauserPawn = EventInstigator:K2_GetPawn()
        if CauserPawn == CurrentCharacter then
            local HealthStealRatio = UGCAttributeSystem.GetGameAttributeValue(CauserPawn, 'HealthStealRatio')
            if HealthStealRatio > 0 then
                ugcprint("[PassiveSkill_HealthSteal] PlayerBeAttacted HealthStealRatio is: "..tostring(HealthStealRatio))
                UGCAttributeSystem.AddGameAttributeValue(CauserPawn, 'Health', HealthStealRatio * Damage)
            end
        end      
    end
end

-- 被动技能结束
function PassiveSkill_HealthSteal:UnListenDamageEvent()
    UGCGenericMessageSystem.UnListenMessage(self, self.MonsterBeAttacted)
    UGCGenericMessageSystem.UnListenMessage(self, self.PlayerBeAttacted)

end

return PassiveSkill_HealthSteal