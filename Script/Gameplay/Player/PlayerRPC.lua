---@class Gameplay.PlayerRPC
local PlayerRPC = LuaClass("Gameplay.PlayerRPC")

function PlayerRPC:Ctor()

end

---@public 丧尸被爆头 server call client
---@param playerController UGCPlayerController_C
---@param zombiePawn BP_Zombie_Base_C
---@param dmgPosition EAvatarDamagePosition
---@param isDead boolean
function PlayerRPC:S2C_OnHitZombie(playerController,zombiePawn,dmgPosition,isDead)
    local clientGameplayComp = playerController:GetClientGameplayComponent()
    UnrealNetwork.CallUnrealRPC_Unreliable(playerController,
            clientGameplayComp or playerController,
            "RPC_Client_OnHitZombie",
            zombiePawn,
            dmgPosition,
            isDead
    )
end

---@public 通知指定玩家的分 server call client
---@param playerController UGCPlayerController_C
---@param score number
---@param dmgPosition EAvatarDamagePosition
function PlayerRPC:S2C_OnGainScore(playerController,score,dmgPosition)
    local clientGameplayComp = playerController:GetClientGameplayComponent()
    UnrealNetwork.CallUnrealRPC_Unreliable(playerController,
            clientGameplayComp or playerController,
            "RPC_Client_OnGainScore",
            score,
            dmgPosition
    )
end

return PlayerRPC