---@class MonsterSpawnerManager_C:BP_UGCMobSpawnerManager_C
---@field Score int32
--Edit Below--
local MonsterSpawnerManager = {}
 
local GameModeConfigTablePath = "Data/Table/UGCGameModeConfig"

function MonsterSpawnerManager:ReceiveBeginPlay()
    ugcprint("MonsterSpawnerManager:ReceiveBeginPlay")
    MonsterSpawnerManager.SuperClass.ReceiveBeginPlay(self)
    local ModeID = UGCMultiMode.GetModeID()
    local GameModeConfigTable = UGCGameSystem.GetTableData(GameModeConfigTablePath)
    if not GameModeConfigTable then
        ugcprint("MonsterSpawnerManager:ReceiveBeginPlay GameModeConfigTable not found")
        return
    end

    local ModeConfig = nil
    for _, value in pairs(GameModeConfigTable) do
		if value.ModeID == ModeID then
			ModeConfig = value
            break
		end
	end
    if not ModeConfig then
        ugcprint("MonsterSpawnerManager:ReceiveBeginPlay ModeID not found")
        return -1
    end

    ugcprint("MonsterSpawnerManager:ReceiveBeginPlay ModeID="..ModeID)
    local NewSpawnConfig = {}
    NewSpawnConfig.ConfigMode = EUGCMobSpawnerConfigMode.Custom
    NewSpawnConfig.CustomParam = { SchemeID = ModeConfig.EnemyRefresh }
    
    self:CleanAllMobConfigOverride()
    self:SetMobConfigOverride(NewSpawnConfig)
end


--[[
function MonsterSpawnerManager:ReceiveTick(DeltaTime)
    MonsterSpawnerManager.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function MonsterSpawnerManager:ReceiveEndPlay()
    MonsterSpawnerManager.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function MonsterSpawnerManager:GetReplicatedProperties()
    return
end
--]]

function MonsterSpawnerManager:OnAllMobDie()
    ugcprint("MonsterSpawnerManager:OnAllMobDie")
    local teamids = UGCTeamSystem.GetTeamIDs()
    local LevelActor = UGCLevelFlowSystem.GetCurrentLevelActor()
    ugcprint("MonsterSpawnerManager:OnAllMobDie LevelActor.GameTotalScore"..tostring(LevelActor.GameTotalScore))
    ugcprint("MonsterSpawnerManager:OnAllMobDie LevelActor.MobManagerCount"..tostring(LevelActor.MobManagerCount))
    for _, teamid in pairs(teamids) do
        UGCLevelFlowSystem.LevelAddScore(teamid, LevelActor.GameTotalScore/#UGCActorComponentUtility.GetAllActorsOfClass(self, UGCObjectUtility.LoadClass('/Game/UGC/UGCGame/NPC/Spawner/BP_UGCMobSpawnerManager.BP_UGCMobSpawnerManager_C')))
    end
end

return MonsterSpawnerManager