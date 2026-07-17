---@class Gameplay.Struct.MonsterGroup
---@field MonsterID number
---@field Weight number

---@class Gameplay.Struct.MonsterSpawnerTypeConfig
---@field SpawnerType string
---@field Monsters Gameplay.Struct.MonsterGroup[]

---@class Gameplay.Struct.MonsterSpawnScheme
---@field SchemeID number
---@field SpawnerTypes Gameplay.Struct.MonsterSpawnerTypeConfig[]
---@field RageStartRatio number
---@field RageRatioStep number
---@field RageMaxRatio number
---@field RageStartRound number


---@class Gameplay.Struct.MonsterDetails
---@field MonsterID number
---@field MonsterName string
---@field MonsterClass FSoftClassPath
---@field BodyHitScore number
---@field BodyKillScore number
---@field HeadshotKillScore number