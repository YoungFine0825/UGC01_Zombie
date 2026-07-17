---@class Gameplay.EGameState
EGameState = {
    Deactive = 0,
    ReadyToStart = 1,--关卡加载完成准备开始游戏
    Gaming = 2,--游戏开始
    Settlement = 3,--游戏结算
    GameEnd = 4,--游戏结束
}

---@class Gameplay.ERoundPhase
ERoundPhase = {
    Deactive = 0,
    FreezePlayer = 1,
    RoundStart = 2,
    RoundEnd = 3,
}

---@class Gameplay.EZombieType
EZombieType = {
    Unknown = 0,
    NormalZombie = 1,
    RageZombie = 2,
}

---@class Gameplay.EPlayerAliveState
EPlayerAliveState = {
    None = -1,
    Alive = 0,
    Dying = 1,
    Dead = 2,
}

---@class Gameplay.EPlayerInGameStatKeys
EPlayerInGameStatKeys = {
    Unknown = nil,
    TotalScore = "Score",
    TotalKill = "TotalKill",
    TotalHeadshot = "TotalHeadshot",--爆头数
    TotalDamage = "TotalDamage",
}