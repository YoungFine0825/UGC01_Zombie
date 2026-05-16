---@class PESkill_TestAttributes_C:PESkillTemplate_Active_C
--Edit Below--
local PESkill_TestAttributes = {}
 
function PESkill_TestAttributes:OnEnableSkill_BP()
    self.SuperClass.OnEnableSkill_BP(self)
end

function PESkill_TestAttributes:OnDisableSkill_BP()
    self.SuperClass.OnDisableSkill_BP(self)
end

function PESkill_TestAttributes:OnActivateSkill_BP()
    self.SuperClass.OnActivateSkill_BP(self)
end

function PESkill_TestAttributes:OnDeActivateSkill_BP()
    self.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkill_TestAttributes:CanActivateSkill_BP()
    return self.SuperClass.CanActivateSkill_BP(self)
end

function PESkill_TestAttributes:AddSomeExp()
    local actor = self:GetOwnerActor()
    local state = actor:GetPlayerStateSafety()
    if state then
        state:AddExp(25)
        ugcprint("player state AddExp.")
    end
end


return PESkill_TestAttributes