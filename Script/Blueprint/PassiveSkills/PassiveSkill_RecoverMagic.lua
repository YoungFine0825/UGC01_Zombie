---@class PassiveSkill_RecoverMagic_C:PESkillPassiveSkillTemplate_C
--Edit Below--
local PassiveSkill_RecoverMagic = {}
 
function PassiveSkill_RecoverMagic:OnEnableSkill_BP()
    self.SuperClass.OnEnableSkill_BP(self)
end

function PassiveSkill_RecoverMagic:OnDisableSkill_BP()
    self.SuperClass.OnDisableSkill_BP(self)
end

function PassiveSkill_RecoverMagic:OnActivateSkill_BP()
    self.SuperClass.OnActivateSkill_BP(self)
end

function PassiveSkill_RecoverMagic:OnDeActivateSkill_BP()
    self.SuperClass.OnDeActivateSkill_BP(self)
end

function PassiveSkill_RecoverMagic:CanActivateSkill_BP()
    return self.SuperClass.CanActivateSkill_BP(self)
end

-- 每秒回蓝
function PassiveSkill_RecoverMagic:RecoverMagic()
	if UGCGameSystem.IsServer() then
        local PlayerCharacter = self:GetOwnerActor()
        if not UGCObjectUtility.IsObjectValid(PlayerCharacter) then
            ugcprint("[PassiveSkill_RecoverMagic] Skill Owner is invalid.")
            return
        end

        local MagicRecoverSpeed = UGCAttributeSystem.GetGameAttributeValue(PlayerCharacter, 'MagicRecoverSpeed')
        if MagicRecoverSpeed > 0 then
            local Magic = UGCAttributeSystem.GetGameAttributeValue(PlayerCharacter, 'Magic')
            local MaxMagic = UGCAttributeSystem.GetGameAttributeValue(PlayerCharacter, 'MaxMagic')
            if Magic < MaxMagic then
                local NewMagic = math.min(MaxMagic, Magic + MagicRecoverSpeed)
                ugcprint("[PassiveSkill_RecoverMagic] New Magic is: "..tostring(NewMagic)..', max: '..tostring(MaxMagic))
                UGCAttributeSystem.SetGameAttributeValue(PlayerCharacter, 'Magic', NewMagic)
            end
        end
        
    end

end



return PassiveSkill_RecoverMagic