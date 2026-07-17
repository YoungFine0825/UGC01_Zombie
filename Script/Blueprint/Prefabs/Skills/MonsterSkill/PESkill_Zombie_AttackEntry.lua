---@class PESkill_Zombie_AttackEntry_C:PESkillTemplate_Base_C
--Edit Below--
local PESkill_Zombie_AttackEntry = {}
 
function PESkill_Zombie_AttackEntry:OnEnableSkill_BP()
    PESkill_Zombie_AttackEntry.SuperClass.OnEnableSkill_BP(self)
end

function PESkill_Zombie_AttackEntry:OnDisableSkill_BP()
    PESkill_Zombie_AttackEntry.SuperClass.OnDisableSkill_BP(self)
end

function PESkill_Zombie_AttackEntry:OnActivateSkill_BP()
    PESkill_Zombie_AttackEntry.SuperClass.OnActivateSkill_BP(self)
end

function PESkill_Zombie_AttackEntry:OnDeActivateSkill_BP()
    PESkill_Zombie_AttackEntry.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkill_Zombie_AttackEntry:CanActivateSkill_BP()
    return PESkill_Zombie_AttackEntry.SuperClass.CanActivateSkill_BP(self)
end

function PESkill_Zombie_AttackEntry:DetectEntryACtor()
    GameplayUtils.Print("PESkill_Zombie_AttackEntry.DetectEntryACtor: 检测入口Actor")
    local TargetActors = self:GetSelectTargetActor(EPESkillSelectTarget.E_PESKILL_PickerType_AllTarget)
    local OwnerActor = self:GetOwnerActor()
    if TargetActors then
        local mt = getmetatable(TargetActors)
        if mt then
            GameplayUtils.Print("PESkill_Zombie_AttackEntry.DetectEntryACtor: 探测到Actor ",mt.classname)
        else
            GameplayUtils.Print("PESkill_Zombie_AttackEntry.DetectEntryACtor: 探测到Actor ",tostring(TargetActors))
        end
    end
end

return PESkill_Zombie_AttackEntry