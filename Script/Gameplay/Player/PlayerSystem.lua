---@class Gameplay.PlayerProfileData
---@field UGCPlayerLevel number 玩家等级
---@field PlayerExp number 玩家经验值
---@field HeroID number 选择的英雄ID
local createPlayerProfileDefaultObject = function()
    return {
        UGCPlayerLevel = 1,
        PlayerExp = 0,
        HeroID = -1,
    }
end

---@class Gameplay.PlayerGameRecordData
---@field TotalScore number
---@field TotalKill number
---@field TotalHeadshot number
---@field TotalDamage number

---@class Gameplay.PlayerSystem
local PlayerSystem = LuaClass("Gameplay.PlayerSystem")

function PlayerSystem:Ctor()

end

function PlayerSystem:BeginPlayOnServer()

end

function PlayerSystem:EndPlayOnServer()

end

---@public 获取玩家状态。作用域：服务端&客户端
---@return Gameplay.EPlayerAliveState
function PlayerSystem:GetPlayerAliveState(playerPawn)
    ---@type UGCPlayerState_C
    local playerState = UGCGameSystem.GetPlayerStateByPlayerPawn(playerPawn)
    if not playerState then
        return EPlayerAliveState.None
    end
    return playerState.AliveState
end

---@public
---@param ZombiePawn BP_Zombie_Base_C
---@param Damage number
---@param Context FGameMagnitudeContext @伤害事件上下文
function PlayerSystem:CalcuZombieDamageScore(ZombiePawn, Damage, DamageContext)
    local dmgPosition = UGCAttributeSystem.GetDamagePositionTypeFromContext(DamageContext)
    local dmgType = UGCAttributeSystem.GetDamageTypeFromContext(DamageContext)
    local isDead = UGCAttributeSystem.GetGameAttributeValue(ZombiePawn,"Health") <= 0
    if dmgType == ERestrictedDamageType.ShootDamage then
        if isDead then
            if dmgPosition == EAvatarDamagePosition.BigHead then
                return 100
            else
                return 60
            end
        else
            return 10
        end
    elseif dmgType == ERestrictedDamageType.MeleeDamage then
        if isDead then
            return 130--近战击杀得分更高，无论是不是爆头
        else
            return 60
        end
    end
end

---@public 生效范围：服务器
---@return Gameplay.PlayerProfileData
function PlayerSystem:ServerGetPlayerGameProfile(UID, ChunkIndex)
    local ret = UGCPlayerStateSystem.GetPlayerArchiveData(UID,ChunkIndex)
    local defaultObject = createPlayerProfileDefaultObject()
    if ret then
        for k,v in pairs(defaultObject) do
            if ret[k] == nil then
                ret[k] = v
            end
        end
    else
        ret = defaultObject
    end
    return ret
end

---@public 生效范围：服务器
---@param PlayerState UGCPlayerState_C
---@return Gameplay.PlayerProfileData
function PlayerSystem:ServerGetPlayerGameProfileByPlayerState(PlayerState,ChunkIndex)
    local UID = UGCGameSystem.GetUIDByPlayerState(PlayerState)
    return self:ServerGetPlayerGameProfile(UID,ChunkIndex)
end

---@public 生效范围：服务器
---@param UID
---@param ProfileData Gameplay.PlayerProfileData
---@param ChunkIndex number
---@return boolean
function PlayerSystem:ServerSavePlayerGameProfile(UID, ProfileData, ChunkIndex)
    if not ProfileData then
        return false
    end
    local defaultObj = createPlayerProfileDefaultObject()
    for k,v in pairs(defaultObj) do
        if ProfileData[k] == nil then
            ProfileData[k] = v
        end
    end
    local ret = UGCPlayerStateSystem.SavePlayerArchiveData(UID, ProfileData, ChunkIndex)
    return ret
end

---@public 生效范围：服务器
---@param PlayerState UGCPlayerState_C
---@param ProfileData Gameplay.PlayerProfileData
---@param ChunkIndex number
---@return boolean
function PlayerSystem:ServerSavePlayerGameProfileByPlayerState(PlayerState, ProfileData, ChunkIndex)
    if not ProfileData then
        return false
    end
    local UID = UGCGameSystem.GetUIDByPlayerState(PlayerState)
    return self:ServerSavePlayerGameProfile(UID,ProfileData,ChunkIndex)
end

---@public 玩家进入观战状态。生效范围：服务器
function PlayerSystem:ServerEnableSpectating(playerController,enabled)
    if enabled then
        UGCGameSystem.EnterSpectating(playerController)
    else
        UGCGameSystem.LeaveSpectating(playerController)
    end
end

---@public
function PlayerSystem:GetPlayerInGameStatData(playerKey,statKey)
    ---@type UGCPlayerState_C
    local playerState = UGCGameSystem.GetPlayerStateByPlayerKey(playerKey)
    if not playerState then
        return 0
    end
    local statDataComp = playerState:GetInGameStatDataComponent()
    if not statDataComp then
        return 0
    end
    local ret = statDataComp:GetStatData(statKey)
    return ret
end

---@public
function PlayerSystem:AddPlayerInGameStatData(playerKey,statKey,delta)
    ---@type UGCPlayerState_C
    local playerState = UGCGameSystem.GetPlayerStateByPlayerKey(playerKey)
    if not playerState then
        return false
    end
    local statDataComp = playerState:GetInGameStatDataComponent()
    if not statDataComp then
        return false
    end
    statDataComp:AddStatData(statKey,delta)
    return true
end

---@public
function PlayerSystem:SetPlayerInGameStatData(playerKey,statKey,newValue)
    ---@type UGCPlayerState_C
    local playerState = UGCGameSystem.GetPlayerStateByPlayerKey(playerKey)
    if not playerState then
        return false
    end
    local statDataComp = playerState:GetInGameStatDataComponent()
    if not statDataComp then
        return false
    end
    statDataComp:SetStatData(statKey,newValue)
    return true
end

return PlayerSystem