---@class UGCGameMode_C:BP_UGCGameBase_C
--Edit Below--
local UGCGameMode = {}
UGCGameMode.IsStartMatch = false
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
local UGCGameState = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameState')

function UGCGameMode:ReceiveBeginPlay()
    local ModeID = UGCMultiMode.GetModeID()
    self:InitMode(ModeID)

    local Class = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath('ExtendResource/HeroSelect/OfficialPackage/Asset/HeroSelection/Blueprint/BP_HeroSelectionActor.BP_HeroSelectionActor_C'))
    if not self.HeroActor then
        print("[HeroSelection] UGCGameMode:ReceiveBeginPlay: HeroActor spawned!!!!!!!!!!!!")
        self.HeroActor = UGCGameSystem.SpawnActor(self, Class, Vector.New(7169, 7304, 1586), Rotator.New(0, 90, 0), Vector.New(1, 1, 1), self)
    else
        print("[HeroSelection] Error: UGCGameMode:ReceiveBeginPlay: HeroActor is not nil.")
    end
end

function UGCGameMode:InitMode(ModeID)
    if UGCGameState.IsInLobby() then
        -- UGCGenericMessageSystem.ListenGlobalMessage(self,  UGCGenericMessageSystem.Messages.UGC.Player.PlayerEnter, self, self.ExecuteStartMatch)
        UGCGameSystem.LoadStreamLevel("LobbySkyBox", true, false)
    else
        UGCGameSystem.LoadStreamLevel("BattleSkyBox", true, false)
    end

    UGCGenericMessageSystem.ListenGlobalMessage(self,  UGCGenericMessageSystem.Messages.UGC.MobPawn.PostBeKilled, self, self.OnPostBeKilledDS)

    ugcprint("UGCGameMode:ReceiveBeginPlay ModeID="..ModeID)

    UGCLevelFlowSystem.EnableLevelFlow(UGCGameSystem.GetUGCResourcesFullPath(UGCGameData.GetGameModeActorMgrConfig(ModeID)))
end

-- function UGCGameMode:ExecuteStartMatch()
--     print("UGCGameMode:ReceiveBeginPlay StartMatch Called")
--     if not UGCGameMode.IsStartMatch then
--         UGCGameMode.IsStartMatch = true
--         self:StartMatch()
--     else
--         print("UGCGameMode:ReceiveBeginPlay StartMatch Called, but IsStartMatch is true.")
--         return
--     end
-- end

function UGCGameMode:OnPostBeKilledDS(Victim, CauserController)
    if not Victim or not UGCObjectUtility.IsObjectValid(Victim) then
        ugcprint("UGCGameMode:OnPostBeKilledDS Failed, Victim is invalid.")
        return
    end

    if not CauserController or not UGCObjectUtility.IsObjectValid(CauserController) then
        ugcprint("UGCGameMode:OnPostBeKilledDS Failed, CauserController is invalid.")
        return
    end

    if not CauserController:IsPlayerController() then
        ugcprint("UGCGameMode:OnPostBeKilledDS Failed, CauserController is not player controller.")
        return
    end

    -- 击杀怪物掉落exp
    local MonsterDetailCfg = UGCGameData.GetMonsterConfig(Victim.MonsterID)
    ugcprint("UGCGameMode:OnPostBeKilledDS, MonsterID is: "..tostring(Victim.MonsterID)..", MonsterDetailCfg:"..tostring(MonsterDetailCfg))
    if MonsterDetailCfg and MonsterDetailCfg.KillExp > 0 then
        local CauserCharacter = UGCPlayerControllerSystem.GetPlayerCharacter(CauserController)
        if CauserCharacter and UGCObjectUtility.IsObjectValid(CauserCharacter) and UGCGameSystem.GetPlayerStateByPlayerPawn(CauserCharacter) then
            UGCGameSystem.GetPlayerStateByPlayerPawn(CauserCharacter):AddExp(MonsterDetailCfg.KillExp)
        end
    end

end

return UGCGameMode;