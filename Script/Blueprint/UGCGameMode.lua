---@class UGCGameMode_C:BP_UGCGameBase_C
--Edit Below--
--服务端侧gameplay相关子系统启动器
---@type GameplayBooter
local GameplayBooter = UGCGameSystem.UGCRequire("Script.Gameplay.GameplayBooter")

local UGCGameMode = {}
UGCGameMode.IsStartMatch = false
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
local UGCGameState = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameState')


function UGCGameMode:ReceiveBeginPlay()

    GameplayBooter.Construct()
    GameplayBooter.BeginPlayOnServer()

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

function UGCGameMode:ReceiveTick(DeltaTime)
    GameplayBooter.OnTick(true,DeltaTime)
end


function UGCGameMode:ReceiveEndPlay()
    GameplayBooter.EndPlayOnServer()
end

function UGCGameMode:InitMode(ModeID)
    if UGCGameState.IsInLobby() then
        UGCGameSystem.LoadStreamLevel("LobbySkyBox", true, false)
    else
        --UGCGameSystem.LoadStreamLevel("BattleSkyBox", true, false)
    end

    ugcprint("UGCGameMode:ReceiveBeginPlay ModeID="..ModeID)

    UGCLevelFlowSystem.EnableLevelFlow(UGCGameSystem.GetUGCResourcesFullPath(UGCGameData.GetGameModeActorMgrConfig(ModeID)))
end

function UGCGameMode:OnPlayerRespawned(PlayerKey, bIsAI)
    if not bIsAI then
        ugcprint("UGCGameMode:OnPlayerRespawned PlayerKey="..PlayerKey)
    end
end

function UGCGameMode:UGC_PlayerRespawnEvent(RespawnedController)
	ugcprint("UGCGameMode:UGC_PlayerRespawnEvent PlayerKey="..RespawnedController.PlayerKey)
end

return UGCGameMode;