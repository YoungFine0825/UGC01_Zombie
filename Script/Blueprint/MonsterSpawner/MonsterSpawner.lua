---@class MonsterSpawner_C:BP_UGCMobSpawner_C
---@field SpawnerType FName
--Edit Below--
local MonsterSpawner = {}
 
local MonsterGroupTablePath="Data/Table/DT_MonsterSpawnScheme"
local MonsterDetailsTablePath="Data/Table/DT_MonsterDetails"

function MonsterSpawner:ReceiveBeginPlay()
    MonsterSpawner.SuperClass.ReceiveBeginPlay(self)
    ugcprint("MonsterSpawner:ReceiveBeginPlay X="..tostring(self:K2_GetActorLocation().X))
end


function MonsterSpawner:OnMobSpawn(MobPawn)
    ugcprint("MonsterSpawner:OnMobSpawn")
end

function MonsterSpawner:GetMonsterID(SchemeID, SpawnerType)
    ugcprint("MonsterSpawner:GetMonsterID SchemeID="..tostring(SchemeID).." SpawnerType="..tostring(SpawnerType))
    local MonsterGroupTable = UGCGameSystem.GetTableData(MonsterGroupTablePath)
    if not MonsterGroupTable then
        ugcprint("MonsterGroupTable not found")
        return -1
    end

    local MonsterGroup = nil
    for _, value in pairs(MonsterGroupTable) do
		if value.SchemeID == tonumber(SchemeID) then
			MonsterGroup = value
            break
		end
	end
    if not MonsterGroup then
        ugcprint("MonsterSpawner:GetMonsterID SchemeID not found")
        return -1
    end


    local Monsters = nil
    for _, value in pairs(MonsterGroup.SpawnerTypes) do
		if value.SpawnerType == SpawnerType then
			Monsters = value
            break
		end
	end
    if not Monsters then
        ugcprint("MonsterSpawner:GetMonsterID SpawnerType not found")
        return -1
    end

    local totalWeight = 0
    for _, MonsterInfo in pairs(Monsters.Monsters) do
        totalWeight = totalWeight + MonsterInfo.Weight
    end
    local randNum = math.random(1,totalWeight)
    if totalWeight <= 0 then
        randNum = totalWeight
    end
    for _, MonsterInfo in pairs(Monsters.Monsters) do
        randNum = randNum - MonsterInfo.Weight
        if randNum <= 0 then
            return MonsterInfo.MonsterID
        end
    end

    return -1
end

function MonsterSpawner:GetMonsterDetails(MonsterID)
    local MonsterDetailsTable = UGCGameSystem.GetTableData(MonsterDetailsTablePath)
    if not MonsterDetailsTable then
        ugcprint("MonsterDetailsTable not found")
        return nil
    end

    for _, value in pairs(MonsterDetailsTable) do
		if value.MonsterID == MonsterID then
			return value
		end
	end
    return nil
end

function MonsterSpawner:CustomSpawnMob(InCustomParam)
    print("MonsterSpawner:CustomSpawnMob")
    local SchemeID = InCustomParam.SchemeID
    local MonsterID = self:GetMonsterID(SchemeID, self.SpawnerType)
    if MonsterID == -1 then
        ugcprint("MonsterSpawner:CustomSpawnMob GetMonsterID failed SchemeID="..tostring(SchemeID))
        return nil
    end

    ugcprint("MonsterSpawner:CustomSpawnMob MonsterID="..MonsterID)
    local MonsterDetails = self:GetMonsterDetails(MonsterID)
    if not MonsterDetails then
        ugcprint("MonsterSpawner:CustomSpawnMob GetMonsterDetails failed MonsterID="..tostring(MonsterID))
        return nil
    end

    local MonsterClass = UGCObjectUtility.LoadObjectBySoftPath(MonsterDetails.MonsterClass)
    ugcprint("MonsterSpawner:CustomSpawnMob  Class="..tostring(MonsterClass))

    local SpawnedMonster = self:SpawnMob(MonsterClass)
    if SpawnedMonster then
        if SpawnedMonster.LuaLogicPart and MonsterDetails.MonsterID then
            ugcprint("MonsterSpawner:CustomSpawnMob success MonsterID="..tostring(MonsterDetails.MonsterID))
            SpawnedMonster.LuaLogicPart:SetMonsterID(MonsterDetails.MonsterID)
        else
            ugcprint("MonsterSpawner:CustomSpawnMob  LuaLogicPart is Nil or MonsterDetails error")
        end
    else
        ugcprint("MonsterSpawner:CustomSpawnMob  SpawnedMonster is Nil")
    end

    
    return SpawnedMonster
end

return MonsterSpawner