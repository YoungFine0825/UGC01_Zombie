世界级
    创建UGCGameMode、UGCGameState
    UGCGameMode:ReceiveBeginPlay
    GameplayBooter.BeginPlayOnServer
    UGCLevelActorMgr.ReceiveBeginPlay
    UGCGameState.ReceiveBeginPlay
    BP_ServerGameplayComponent.ReceiveBeginPlay + OnServerBeginPlay
    UGCLevelActor.ReceiveBeginPlay

玩家级
    玩家连接进入
    创建UGCPlayerController、UGCPlayerState
    UGCPlayerState:ReceiveBeginPlay
    UGCPlayerController各组件 BeginPlay：Backpack / AntiCheat / QuickSign / TalentTreeComponent / CharaStat
    UGCPlayerController:ReceiveBeginPlay
    PostLogin
    UGCPlayerPawn：创建、附身ClientOnPossessBy以及执行ReceiveBeginPlay
    广播 UGC.PlayerPawn.PawnSpawn
    GamePartManager.HandlePlayerEnter
