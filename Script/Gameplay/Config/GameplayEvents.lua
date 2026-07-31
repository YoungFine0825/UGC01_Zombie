local Events = {
    --前后端都会广播
    Global = {
        OnPlayerEnterInteractEntity = "GameplayEvents.Global.OnPlayerEnterInteractEntity",--玩家进入交互实体触发区域
        OnPlayerLeaveInteractEntity = "GameplayEvents.Global.OnPlayerLeaveInteractEntity",--玩家离开交互实体触发区域
        OnPlayerInteractCompleted = "GameplayEvents.Global.OnPlayerInteractCompleted",--玩家交互动作完成(不含成功/失败语义)
    },
    --仅在服务端广播
    Server = {
        OnGameplayStart = "GameplayEvents.Server.OnGameplayStart",--关卡、玩家准备完毕开始局内游戏
        OnGameplayEnd = "GameplayEvents.Server.OnGameplayEnd",--局内游戏结束
        OnRoundStart = "GameplayEvents.Server.OnRoundStart",--回合开始
        OnRoundEnd = "GameplayEvents.Server.OnRoundEnd",
        OnZombieBeKilled = "GameplayEvents.Server.OnZombieBeKilled",--一个丧尸被击杀
        OnAllZombiesBeEliminated = "GameplayEvents.Server.OnAllZombiesBeEliminated",--本回合所有丧尸被消灭
        OnPlayerAliveStateChanged = "GameplayEvents.Server.OnPlayerAliveStateChanged",
        OnAllPlayersDead = "GameplayEvents.Server.OnAllPlayersDead",
        OnPlayerInteractionCompleted = "GameplayEvents.Server.OnPlayerInteractionCompleted",
        OnTeamBuffPicked = "GameplayEvents.Server.OnTeamBuffPicked",--TeamBuff掉落物被拾取(manager,pickupActor,playerKey)
    },
    --仅在客户端广播
    Client = {
        OnGameStateChanged = "GameplayEvents.Client.OnGameStateChanged",
        OnRoundFlowChanged = "GameplayEvents.Client.OnRoundFlowChanged",
        OnLocalPlayerAliveStateChanged = "GameplayEvents.Client.OnLocalPlayerAliveStateChanged",
        OnLocalPlayerGainScore = "GameplayEvents.Client.OnLocalPlayerGainScore",
        OnLocalPlayerUpdateInteractEntityWidget = "GameplayEvents.Client.OnLocalPlayerUpdateInteractEntityWidget",
        OnLocalPlayerInvokeInteraction = "GameplayEvents.Client.OnLocalPlayerInvokeInteraction",--玩家确认进行交互
        OnLocalPlayerReceiveInteractionResult = "GameplayEvents.Client.OnLocalPlayerReceiveInteractionResult",--客户端收到服务端处理的交互的结果
        OnLocalPlayerInterruptInteractionFinished = "GameplayEvents.Client.OnLocalPlayerInterruptInteractionFinished",
    },
}

GameplayEvents = Events