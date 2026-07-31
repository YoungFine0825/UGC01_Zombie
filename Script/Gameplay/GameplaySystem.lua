local UGCRequire = UGCGameSystem.UGCRequire

---@class Gameplay.IGameplaySystem
---@field BeginPlayOnServer function
---@field EndPlayOnServer function
---@field BeginPlayOnClient function
---@field EndPlayOnClient function
---@field OnTick fun(DeltaTime:number)
---@field OnServerTick fun(DeltaTime:number)
---@field OnClientTick fun(DeltaTime:number)
---@field test number



GameplaySystem = {
    ---@type Gameplay.Config.ActorTags
    ActorTags = UGCRequire("Script.Gameplay.Config.ActorTags"),
    ---@type Gameplay.EventSystem
    EventSystem = UGCRequire("Script.Gameplay.Core.EventSystem").New(),
    ---@type Gameplay.WeaponSystem
    WeaponSystem = UGCRequire("Script.Gameplay.Weapon.WeaponSystem").New(),
    ---@type Gameplay.WeaponConfigMgr
    WeaponConfigMgr = UGCRequire("Script.Gameplay.Weapon.WeaponConfigMgr").New(),
    ---@type Gameplay.SodaConfigMgr
    SodaConfigMgr = UGCRequire("Script.Gameplay.Player.SodaConfigMgr").New(),
    ---@type Gameplay.BackpackSystem
    BackpackSystem = UGCRequire("Script.Gameplay.Backpack.BackpackSystem").New(),
    ---@type Gameplay.PlayerSystem
    PlayerSystem = UGCRequire("Script.Gameplay.Player.PlayerSystem").New(),
    ---@type Gameplay.PlayerRPC
    PlayerRPC = UGCRequire("Script.Gameplay.Player.PlayerRPC").New(),
    ---@type Gameplay.InteractEntitySystem
    InteractEntitySystem = UGCRequire("Script.Gameplay.InteractEntity.InteractEntitySystem").New(),

    --纯服务端系统
    ---@type Gameplay.MonsterAISystem
    MonsterAISystem = UGCRequire("Script.Gameplay.Monster.MonsterAISystem").New(),
    ---@type Gameplay.ZombieSpawnSystem
    ZombieSpawnSystem = UGCRequire("Script.Gameplay.Monster.ZombieSpawnSystem").New(),
    ---@type Gameplay.NavigationSystem
    NavigationSystem = UGCRequire("Script.Gameplay.Navigation.NavigationSystem").New(),
}


---@return BP_GameplayStateComponent
function GameplaySystem.GetGameplayStateComponent()
    ---@type UGCGameState_C
    local gameState = UGCGameSystem.GetGameState()
    return gameState.GameplayStateComponent
end

---获取服务端玩法规则组件
---@return BP_ServerGameplayComponent_C
function GameplaySystem.GetServerGameplayComponent()
    ---@type BP_Gameplay_LevelAcor_Base_C
    local levelActor = UGCLevelFlowSystem.GetCurrentLevelActor()
    if not levelActor then
        GameplayUtils.Exception("GameplaySystem.GetGameplayServerComponent: 当前关卡的Level Actor尚未创建完毕！")
        return nil
    end
    local ret = levelActor:GetServerGameplayComponent()
    return ret
end

---@return BP_ClientGameplayComponent_C
function GameplaySystem.GetClientGameplayComponent()
    local pc = UGCGameSystem.GetLocalPlayerController()
    if not pc then
        return nil
    end

end

---@return boolean
function GameplaySystem.IsInLobby()
    local ModeID = UGCMultiMode.GetModeID()
    return ModeID == 1001
end

---@return boolean
function GameplaySystem.BackToLobby()
    return UGCMultiMode.RequestMatch(1001, nil, nil)
end

---@return UGCPlayerController_C
function GameplaySystem.GetPlayerControllerByPlayerKey(playerKey)
    return UGCGameSystem.GetPlayerControllerByPlayerKey(playerKey)
end

---@return UGCPlayerState_C
function GameplaySystem.GetPlayerStateByPlayerKey(playerKey)
    return UGCGameSystem.GetPlayerStateByPlayerKey(playerKey)
end

---@return UGCPlayerPawn_C
function GameplaySystem.GetPlayerPawnByPlayerKey(playerKey)
    return UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
end