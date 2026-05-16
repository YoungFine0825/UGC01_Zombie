---@class UGCAttributeGroup_C:GameAttributeGroup
--Edit Below--
local UGCAttributeGroup = {}
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
 
function UGCAttributeGroup:OnInitGroup()
    -- 属性操作只在Server进行
	if not UGCGameSystem.IsServer() then
        return
    end
    local OwnerActor = self:GetGroupOwner()

    -- 记录默认值，用于等级提升后重新设置属性值
    self.BaseHealth = UGCAttributeSystem.GetGameAttributeValue(OwnerActor, 'BaseHealth')
    self.OrignalMagic = UGCAttributeSystem.GetGameAttributeValue(OwnerActor, 'MaxMagic')
    self.Defence = UGCAttributeSystem.GetGameAttributeValue(OwnerActor, 'Defence')

     --1秒后更新等级相关属性, 延迟是因为需要等待Character 和 PlayerState的绑定
     UGCTimerUtility.CreateLuaTimer(1, function ()
        self:InitLevelRelated()
        self:UpdateMaxHealth()

        if OwnerActor and OwnerActor.GetPlayerStateSafety and OwnerActor:GetPlayerStateSafety() then
            local OwnerState = OwnerActor:GetPlayerStateSafety()
            ugcprint("[UGCAttributeGroup] Listen LevelChanged: "..tostring(OwnerState))
            OwnerState.OnLevelChanged:Add(self.InitLevelRelated, self)
        end
    end)

    self.HealthBoostDelegate = UGCAttributeSystem.AddGameAttributeChangedDelegate(OwnerActor, "HealthBoost", function (AttrName, CurValue)
        self:UpdateMaxHealth()
    end)
    self.BaseHealthDelegate = UGCAttributeSystem.AddGameAttributeChangedDelegate(OwnerActor, "BaseHealth", function (AttrName, CurValue)
        self:UpdateMaxHealth()
    end)

    -- 怪物属性默认值从表格里读取
    self:InitMonsterAttributes()
end

function UGCAttributeGroup:InitMonsterAttributes()
    local OwnerActor = self:GetGroupOwner()
    if OwnerActor.MonsterID and OwnerActor.MonsterID > 0 then
        local MonsterDetailCfg = UGCGameData.GetMonsterConfig(OwnerActor.MonsterID)
        ugcprint("UGCAttributeGroup:InitMonsterAttributes, MonsterID is: "..tostring(OwnerActor.MonsterID)..", MonsterDetailCfg:"..tostring(MonsterDetailCfg))
        if MonsterDetailCfg then
            UGCAttributeSystem.SetGameAttributeValue(OwnerActor, 'BaseHealth', MonsterDetailCfg.Health)
            -- UGCAttributeSystem.SetGameAttributeValue(OwnerActor, 'Defence', MonsterDetailCfg.Defence)
            UGCAttributeSystem.SetGameAttributeValue(OwnerActor, 'CritDamageResist', MonsterDetailCfg.CritDamageResist)
            UGCAttributeSystem.SetGameAttributeValue(OwnerActor, 'HeadDamageResist', MonsterDetailCfg.HeadDamageResist)
            UGCAttributeSystem.SetGameAttributeValue(OwnerActor, 'FireDamageResist', MonsterDetailCfg.FireDamageResist)
            UGCAttributeSystem.SetGameAttributeValue(OwnerActor, 'CounterAttackRatio', MonsterDetailCfg.CounterAttackRatio)
            UGCAttributeSystem.SetGameAttributeValue(OwnerActor, 'HealthStealRatio', MonsterDetailCfg.HealthStealRatio)
        end
    end
end

-- 初始化等级相关的数据
function UGCAttributeGroup:InitLevelRelated()
    local OwnerActor = self:GetGroupOwner()
    -- ugcprint("[UGCAttributeGroup] InitLevelRelated: "..tostring(OwnerActor.GetPlayerStateSafety))

    if OwnerActor and OwnerActor.GetPlayerStateSafety then
        local OwnerState = OwnerActor:GetPlayerStateSafety()
        ugcprint("[UGCAttributeGroup] InitLevelRelated: "..tostring(OwnerState))
        if OwnerState then
            -- local player = self:GetPlayerCharacter()
            -- 设置等级对应的属性值
            local LvCfg = UGCGameData.GetLevelConfig(OwnerState.UGCPlayerLevel)
            if LvCfg then
                for _, AttributeCfg in pairs(LvCfg.Attributes) do
                    UGCAttributeSystem.SetGameAttributeValue(OwnerActor, AttributeCfg.Attribute.AttributeName, AttributeCfg.Value)
                    ugcprint("[UGCAttributeGroup] Init Attribute: "..AttributeCfg.Attribute.AttributeName.." value： "..AttributeCfg.Value)
                end
            end

            -- 设置等级对应的增量
            local LvGlobalCfg = UGCGameData.GetGlobalLevelConfig()
            if LvGlobalCfg then
                UGCAttributeSystem.SetGameAttributeValue(OwnerActor, 'BaseHealth', self.BaseHealth + LvGlobalCfg.HealthDelta * (OwnerState.UGCPlayerLevel - 1))
                UGCAttributeSystem.SetGameAttributeValue(OwnerActor, 'MaxMagic', self.OrignalMagic + LvGlobalCfg.MagicDelta * (OwnerState.UGCPlayerLevel - 1))
                -- UGCAttributeSystem.SetGameAttributeValue(OwnerActor, 'Defence', self.Defence + LvGlobalCfg.DefenceDelta * (OwnerState.UGCPlayerLevel - 1))
                ugcprint("[UGCAttributeGroup] MaxMagic: "..self.OrignalMagic..', Level: '..OwnerState.UGCPlayerLevel..', magic delta:'..LvGlobalCfg.MagicDelta)
            end
        end
    end  
end

-- 力量决定HealthMax
function UGCAttributeGroup:UpdateMaxHealth()
    local OwnerActor = self:GetGroupOwner()
    if OwnerActor and self.OwnerAttrComp then
        local OldValue = UGCAttributeSystem.GetGameAttributeValue(OwnerActor, 'HealthMax')
        local HealthBoost = UGCAttributeSystem.GetGameAttributeValue(OwnerActor, 'HealthBoost')
        local BaseHealth = UGCAttributeSystem.GetGameAttributeValue(OwnerActor, 'BaseHealth')
        local NewValue = (1 + HealthBoost) * BaseHealth
        if OldValue ~= NewValue then
            UGCAttributeSystem.SetGameAttributeValue(OwnerActor, 'HealthMax', NewValue)
            UGCAttributeSystem.AddGameAttributeValue(OwnerActor, 'Health', NewValue - OldValue)
        end
        ugcprint("[UGCAttributeGroup] HealthMax New: ".. NewValue)
    else
        ugcprint("[UGCAttributeGroup] param error: ".. OwnerActor..", Comp value: ".. self.OwnerAttrComp)
    end
end

-- Destroy
function UGCAttributeGroup:OnDestroyGroup()
    local OwnerActor = self:GetGroupOwner()

    if self.HealthBoostDelegate then
        UGCAttributeSystem.RemoveGameAttributeChangedDelegate(OwnerActor, "HealthBoost", self.HealthBoostDelegate)
        self.HealthBoostDelegate = nil
    end
    if self.BaseHealthDelegate then
        UGCAttributeSystem.RemoveGameAttributeChangedDelegate(OwnerActor, "BaseHealth", self.BaseHealthDelegate)
        self.BaseHealthDelegate = nil
    end
end

return UGCAttributeGroup