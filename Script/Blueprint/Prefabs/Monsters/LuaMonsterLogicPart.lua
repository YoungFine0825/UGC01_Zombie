local LuaMonsterLogicPart = 
{
    Owner = nil,
}

local SetMetaTable = setmetatable
local MetaTable = { __index = LuaMonsterLogicPart }

function LuaMonsterLogicPart:New()
	local Result = {}
    Result.Owner = nil
	SetMetaTable(Result, MetaTable)
	return Result
end

function LuaMonsterLogicPart:ReceiveBeginPlay()
    if UGCActorComponentUtility.HasAuthority(self.Owner) then
        self:SetMonsterID(self.Owner.MonsterID)
    end
end

function LuaMonsterLogicPart:GetMonsterDetails(InMonsterID)
    local MonsterDetailsTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/DT_MonsterDetails'))
    if not MonsterDetailsTable then
        ugcprint("MonsterDetailsTable not found")
        return nil
    end
    for _, value in pairs(MonsterDetailsTable) do
		if value.MonsterID == InMonsterID then
			return value
		end
	end
    return nil
end

function LuaMonsterLogicPart:SetMonsterID(InMonsterID)
    ugcprint("LuaMonsterLogicPart:SetMonsterID NewMonsterID="..InMonsterID)
    if not self.Owner then
        return
    end
    self.Owner.MonsterID = InMonsterID
    self:UpdateMonsterInfo()
end


function LuaMonsterLogicPart:UpdateMonsterInfo()
    local MonsterDetails = self:GetMonsterDetails(self.Owner.MonsterID)
    if not MonsterDetails then
        ugcprint("LuaMonsterLogicPart:UpdateMonsterInfo MonsterDetails not found")
    end

    if MonsterDetails.MonsterName then
        self.Owner.CharacterName = MonsterDetails.MonsterName
    end

    if MonsterDetails.MonsterType then
        self.Owner.MonsterType = MonsterDetails.MonsterType
    end

    if MonsterDetails.DropGroupID_Wrapper and MonsterDetails.DropGroupID_Backpack then
        ugcprint("LuaMonsterLogicPart:UpdateMonsterInfo DropGroupID_Wrapper="..MonsterDetails.DropGroupID_Wrapper.."  DropGroupID_Backpack="..MonsterDetails.DropGroupID_Wrapper)
        self.Owner.UGCPresetCommonDropItemComponent:ClearDropConfig()
        self.Owner.UGCPresetCommonDropItemComponent:SetGeneratorType(EUGCDropItemListGeneratorType.DropItemListGeneratorType_ItemTable)
        if MonsterDetails.DropGroupID_Wrapper ~= 0 then
            self.Owner.UGCPresetCommonDropItemComponent:AddDropConfig(-1, MonsterDetails.DropGroupID_Wrapper, {}, EUGCGenerateItemEntityType.GenerateItemEntity_WrapperActor)
        end
        if MonsterDetails.DropGroupID_Backpack ~= 0 then
            self.Owner.UGCPresetCommonDropItemComponent:AddDropConfig(-1, MonsterDetails.DropGroupID_Backpack, {}, EUGCGenerateItemEntityType.GenerateItemEntity_BackPack)
        end
        
    end
 
    UGCAttributeSystem.SetGameAttributeValue(self.Owner, 'BaseHealth', MonsterDetails.Health)
    UGCAttributeSystem.SetGameAttributeValue(self.Owner, 'Defence', MonsterDetails.Defence)
    UGCAttributeSystem.SetGameAttributeValue(self.Owner, 'CritDamageResist', MonsterDetails.CritDamageResist)
    UGCAttributeSystem.SetGameAttributeValue(self.Owner, 'HeadDamageResist', MonsterDetails.HeadDamageResist)
    UGCAttributeSystem.SetGameAttributeValue(self.Owner, 'FireDamageResist', MonsterDetails.FireDamageResist)
    UGCAttributeSystem.SetGameAttributeValue(self.Owner, 'CounterAttackRatio', MonsterDetails.CounterAttackRatio)
    UGCAttributeSystem.SetGameAttributeValue(self.Owner, 'HealthStealRatio', MonsterDetails.HealthStealRatio)
end

function LuaMonsterLogicPart:BPDie(Damage, Killer, DamageCauser, DamageEvent, DamageTypeID)
    ugcprint("LuaMonsterLogicPart:BPDie")
    self.Owner.UGCPresetCommonDropItemComponent:StartDrop(self.Owner, Killer, {})
end


return LuaMonsterLogicPart
