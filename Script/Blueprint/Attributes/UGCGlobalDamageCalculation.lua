UGCGameSystem.UGCRequire('Script.GameAttribute.game_attribute_type')

local UGCGlobalDamageCalculation = {}

function UGCGlobalDamageCalculation:GetCalculationResult(Context, ExtraResult)
    -- ugcprint("[UGCGlobalDamageCalculation] Context instigator --->"..tostring(Context.Instigator))
    local RestrictedDamageType = UGCAttributeSystem.GetDamageTypeFromContext(Context)
    local DamageTypeTags = UGCAttributeSystem.GetDamageTagsFromContext(Context)
    local SourceMagnitude  = UGCAttributeSystem.GetSourceMagnitudeFromContext(Context)
    local SourceObject          = UGCAttributeSystem.GetSourceObjectFromContext(Context)
    local VictimActor           = UGCAttributeSystem.GetVictimFromContext(Context)      --受害者
    local Causer                = UGCAttributeSystem.GetCauserFromContext(Context)      --枪等武器或者人(空手情况)
    local InstigatorController  = UGCAttributeSystem.GetInstigatorFromContext(Context)  --攻击者的Controller
    local CauserActor           = InstigatorController:K2_GetPawn()           --攻击者角色
    ugcprint("[UGCGlobalDamageCalculation] Context CauserActor --->"..tostring(CauserActor))
    ugcprint("[UGCGlobalDamageCalculation] Context SrcMagnitude --->"..tostring(SourceMagnitude))
    ugcprint("[UGCGlobalDamageCalculation] Context RestrictedDamageType --->"..tostring(RestrictedDamageType))
    ugcprint("[UGCGlobalDamageCalculation] Context DamageTypeTags --->"..tostring(DamageTypeTags))
    for _, Tag in pairs(DamageTypeTags) do
        if Tag then
            ugcprint("[UGCGlobalDamageCalculation] Context Tag: --->"..Tag)
        end
    end

    if not VictimActor or not CauserActor then
        ugcprint("[UGCGlobalDamageCalculation] VictimActor or CauserActor is null.")
        return 0
    end

    -- 直接伤害
    if self:HasTag(Context, "UGC.Damage.Type.Direct") then
        ugcprint("[UGCGlobalDamageCalculation] Direct damage:"..tostring(SourceMagnitude))
        return SourceMagnitude, ExtraResult
    end

    -- 反伤伤害
    if self:HasTag(Context, "UGC.Damage.Type.CounterAttack") then
        ugcprint("[UGCGlobalDamageCalculation] CounterAttack damage:"..tostring(SourceMagnitude))
        return SourceMagnitude, ExtraResult
    end
    
    
    -- A = Caster, B = Target
    -- SkillAttack = Skill.技能等级伤害 * A.玩家等级 + Skill.技能固定伤害
    -- B.防御减伤比 =（B.防御*（1+B.防御加成比例））*（1-A.防御穿透百分比））/（B.防御*（1+B.防御加成比例）+K*B.Lv+C）
    -- A.技能最终伤害 = SkillAttack *（1+A.∑某类型百分比增伤-B.∑某类型百分比减免+A.某伤害来源增伤）*（暴击 ？A.暴击伤害 : 1）*（1-B.防御减伤)
    local CauserBreakDefenceRatio = UGCAttributeSystem.GetGameAttributeValue(CauserActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_BreakDefenceRatio) --防御穿透百分比
    local CauserCriticalChance = UGCAttributeSystem.GetGameAttributeValue(CauserActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_CritChance) --暴击几率
    local CauserCriticalRatio = UGCAttributeSystem.GetGameAttributeValue(CauserActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_CritRatio) --暴击伤害加成
    local CauserHeadDamageRatio = UGCAttributeSystem.GetGameAttributeValue(CauserActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_HeadDamageBoost) --爆头伤害加成
    local CauserFireDamageRatio = UGCAttributeSystem.GetGameAttributeValue(CauserActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_FireDamageBoost) --火属性伤害加成
    local CauserAttackRatio = UGCAttributeSystem.GetGameAttributeValue(CauserActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_SkillDamageRatio) --角色攻击力加成
    local CauserRifleAttackRatio = UGCAttributeSystem.GetGameAttributeValue(CauserActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_RifleDamageRatio) --步枪攻击力加成
    local CauserMachineAttackRatio = UGCAttributeSystem.GetGameAttributeValue(CauserActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_MachineDamageRatio) --机枪攻击力加成
    local CauserShotgunAttackRatio = UGCAttributeSystem.GetGameAttributeValue(CauserActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_ShotgunDamageRatio) --霰弹枪攻击力加成
    local CauserDMRAttackRatio = UGCAttributeSystem.GetGameAttributeValue(CauserActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_DMRDamageRatio) --射手步枪枪械攻击力加成
    local CauserLv =  UGCAttributeSystem.GetGameAttributeValue(CauserActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_Level) or 1
    
    local causer_TestOne =  UGCAttributeSystem.GetGameAttributeValue(CauserActor, 'TestOne') or 1
    ugcprint("[UGCGlobalDamageCalculation] TestOne:"..tostring(causer_TestOne))

    local TargetDefence = UGCAttributeSystem.GetGameAttributeValue(VictimActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_Defence) --防御
    local TargetDefenceBoost = UGCAttributeSystem.GetGameAttributeValue(VictimActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_ExtraDefenseBoost) --防御加成比例
    local TargetHeadDefenceRatio = UGCAttributeSystem.GetGameAttributeValue(VictimActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_HeadDamageResist) --爆头伤害减少
    local TargetFireDefenceRatio = UGCAttributeSystem.GetGameAttributeValue(VictimActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_FireDamageResist) --火属性伤害减少
    local TargetCritDefenceRatio = UGCAttributeSystem.GetGameAttributeValue(VictimActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_CritDamageResist) --暴击伤害减少
    local TargetLv = UGCAttributeSystem.GetGameAttributeValue(VictimActor, UGCCustomGameAttributeType.UGCAttributeGroup_Character_Level) or 1
    
    
    -- B.防御减伤比
    local TmpDefence = TargetDefence * (1 + TargetDefenceBoost)
    local K = 0
    local C = 100
    local damage_decreace_ratio = 1 - TmpDefence * (1 - CauserBreakDefenceRatio) / (TmpDefence + K * TargetLv + C)

    -- 火属性伤害比例加成
    local FireDamageBoost = 1
    if self:HasTag(Context, "UGC.Damage.Property.Fire") then
        FireDamageBoost = (1 + CauserFireDamageRatio) * (1 - TargetFireDefenceRatio)
        local fire_debug = "CauserFireDamageRatio: " .. tostring(CauserFireDamageRatio).." ,"
        fire_debug = fire_debug .. "TargetFireDefenceRatio: ".. tostring(TargetFireDefenceRatio).." ,"
        fire_debug = fire_debug .. "FireBoost: ".. tostring(FireDamageBoost)
        ugcprint("[UGCGlobalDamageCalculation] HasTag Fire: " .. fire_debug)
    end

    -- 爆头伤害比例加成
    local HeadDamageBoost = 1
    if self:IsHeadDamage(Context) then
        HeadDamageBoost = 1 + CauserHeadDamageRatio - TargetHeadDefenceRatio
    end

    -- 步枪伤害比例加成
    if not self:HasTag(Context, "UGC.Damage.Type.Rifle") then
        CauserRifleAttackRatio = 0
    end
    -- 机枪伤害比例加成
    if not self:HasTag(Context, "UGC.Damage.Type.MachineGun") then
        CauserMachineAttackRatio = 0
    end
    -- 霰弹枪伤害比例加成
    if not self:HasTag(Context, "UGC.Damage.Type.Shotgun") then
        CauserShotgunAttackRatio = 0
    end
    -- 射手步枪枪伤害比例加成
    if not self:HasTag(Context, "UGC.Damage.Type.DMRGun") then
        CauserDMRAttackRatio = 0
    end
    local CauserGunTotalAttackRatio = CauserRifleAttackRatio + CauserMachineAttackRatio + CauserShotgunAttackRatio + CauserDMRAttackRatio
    ugcprint("[UGCGlobalDamageCalculation] Params: ".. "TargetDefence: ".. TargetDefence.. ", damage_decreace_ratio: ".. damage_decreace_ratio.. ", HeadDamageBoost: ".. HeadDamageBoost)
    ugcprint("[UGCGlobalDamageCalculation] Params: CauserGunTotalAttackRatio: ".. tostring(CauserGunTotalAttackRatio)..", CauserAttackRatio: "..tostring(CauserAttackRatio))

    -- 是否暴击
    local IsCritical = (math.random() <= CauserCriticalChance)
    local CriticalRatio = IsCritical and ((1 + CauserCriticalRatio) * (1 - TargetCritDefenceRatio)) or 1
    ugcprint("[UGCGlobalDamageCalculation] Params: ".. "SourceMagnitude: ".. SourceMagnitude..", IsCritical: ".. tostring(IsCritical).. ", CriticalRatio: ".. CriticalRatio)
    if IsCritical and ExtraResult then
        local CritTag = UGCGameplayTagSystem.RequestGameplayTag("UGC.Damage.Result.Critical")
        if CritTag then
            ExtraResult.ResultTags:Add(CritTag)
        end
    end

    -- 最终伤害
    local FinalDamage = SourceMagnitude * (1 + CauserGunTotalAttackRatio + CauserAttackRatio) * FireDamageBoost * HeadDamageBoost * CriticalRatio * damage_decreace_ratio
   
    ugcprint("[UGCGlobalDamageCalculation] Params: "..", FinalDamage: ".. FinalDamage)
    -- PSkill_Utils:DevLog("MBRTemplarGlow:GetCalculationResult ->", value, add_value, add_cdr, add_radio)
    return FinalDamage, ExtraResult
end

-- 是否有某个tag
function UGCGlobalDamageCalculation:HasTag(Context, Tag)
    if not Tag or not Context then
        return false
    end

    for _, TagName in pairs(Context.DamageTypeTags) do
        if TagName == Tag then
            return true
        end
    end
    return false
end

return UGCGlobalDamageCalculation