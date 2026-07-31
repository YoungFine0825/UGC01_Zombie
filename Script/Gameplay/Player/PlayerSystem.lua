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
    return playerState:GetAliveState()
end

---@public 获取玩家状态。作用域：服务端&客户端
---@return Gameplay.EPlayerAliveState
function PlayerSystem:GetPlayerAliveStateByController(playerController)
    ---@type UGCPlayerState_C
    local playerState = UGCGameSystem.GetPlayerStateByPlayerController(playerController)
    if not playerState then
        return EPlayerAliveState.None
    end
    return playerState:GetAliveState()
end

---@public 获取玩家状态。作用域：服务端&客户端
---@return Gameplay.EPlayerAliveState
function PlayerSystem:GetPlayerAliveStateByPlayerKey(PlayerKey)
    ---@type UGCPlayerState_C
    local playerState = UGCGameSystem.GetPlayerStateByPlayerKey(PlayerKey)
    if not playerState then
        return EPlayerAliveState.None
    end
    return playerState:GetAliveState()
end

---@public
---@param ZombiePawn BP_Zombie_Base_C
---@param Damage number
---@param DamageContext FGameMagnitudeContext @伤害事件上下文
function PlayerSystem:CalcuZombieDamageScore(playerKey,ZombiePawn, Damage, DamageContext)
    local dmgPosition = UGCAttributeSystem.GetDamagePositionTypeFromContext(DamageContext)
    local dmgType = UGCAttributeSystem.GetDamageTypeFromContext(DamageContext)
    local isDead = UGCAttributeSystem.GetGameAttributeValue(ZombiePawn,"Health") <= 0
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    local multiple = UGCAttributeSystem.GetGameAttributeValue(playerPawn,UGCCustomGameAttributeType.UGCAttributeGroup_Character_ScoreMultiple)
    multiple = math.max(1,multiple)
    local baseScore = 0
    if dmgType == ERestrictedDamageType.ShootDamage then
        if isDead then
            if dmgPosition == EAvatarDamagePosition.BigHead then
                baseScore = 100--爆头击杀得分更高
            else
                baseScore =  60
            end
        else
            baseScore =  10
        end
    elseif dmgType == ERestrictedDamageType.MeleeDamage then
        if isDead then
            baseScore =  150--近战击杀得分更高，无论是不是爆头
        else
            baseScore =  60
        end
    else
        baseScore =  10
    end
    local score = baseScore * multiple
    return score
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

---@public
function PlayerSystem:GetPlayerCurrentScore(playerKey)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    local playerPropertyName = "Score"
    local propertyValue = UGCAttributeSystem.GetGameAttributeValue(playerPawn,playerPropertyName)
    return propertyValue
end

---@public
---@return boolean,number
function PlayerSystem:ConsumePlayerScore(playerKey,delta)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    local playerPropertyName = "Score"
    local propertyValue = UGCAttributeSystem.GetGameAttributeValue(playerPawn,playerPropertyName)
    local newValue = math.max(0,propertyValue - delta)
    UGCAttributeSystem.SetGameAttributeValue(playerPawn,playerPropertyName,newValue)
    return true,newValue
end

---@public
function PlayerSystem:GetSelfRescueTimes(playerKey)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    if not playerPawn then
        return 0
    end
    local times = UGCAttributeSystem.GetGameAttributeValue(playerPawn,"SelfRescueTimes")
    return times
end

---@public
function PlayerSystem:UseSelfRescueTimes(playerKey,usedTimes)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    if not playerPawn then
        return 0
    end
    local times = UGCAttributeSystem.GetGameAttributeValue(playerPawn,"SelfRescueTimes")
    local remainingTimes = math.max(0,times - usedTimes)
    UGCAttributeSystem.SetGameAttributeValue(playerPawn,"SelfRescueTimes",remainingTimes)
    return remainingTimes
end

---@public
function PlayerSystem:GetCurrentPlayerNum()
    local ret = UGCGameSystem.GetPlayerNum(true)
    return ret
end

---@public
function PlayerSystem:GetCurrentAlivePlayerNum()
    local allPlayerKeys = UGCGameSystem.GetAllPlayerKey()
    local ret = 0
    for _,playerKey in pairs(allPlayerKeys) do
        if self:GetPlayerAliveStateByPlayerKey(playerKey) == EPlayerAliveState.Alive then
            ret = ret + 1
        end
    end
    return ret
end

---@public 杀死玩家，进入Dead状态（注意不是濒死状态）
function PlayerSystem:ServerRespawnPlayer(playerKey)
    if not UGCGameSystem.IsServer() then
        return
    end
    local playerController = UGCGameSystem.GetPlayerControllerByPlayerKey(playerKey)
    ---@type UGCPlayerState_C
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerKey(playerKey)
    if not PlayerState then
        GameplayUtils.Print("PlayerSystem.ServerRespawnPlayer: 无法找到玩家",playerKey,"的PlayerState")
        return
    end
    local pawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    --判断是倒地还是死亡
    local DyingTag = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Dying")
    if pawn and UGCPersistEffectSystem.HasDynamicState(pawn, DyingTag) then
        GameplayUtils.Print("PlayerSystem.ServerRespawnPlayer: 玩家",playerKey,"从濒死状态下复活")
        UGCPlayerPawnSystem.ConfirmRescueOtherImmediately(pawn, pawn)
        UGCPawnAttrSystem.SetHealth(pawn, UGCPawnAttrSystem.GetHealthMax(pawn))
    else
        GameplayUtils.Print("PlayerSystem.ServerRespawnPlayer: 玩家",playerKey,"从死亡状态下复活")
        UGCGameSystem.RespawnPlayer(playerKey)
    end
    --
    PlayerState:ServerChangeAliveState(EPlayerAliveState.Alive)
    --
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnPlayerAliveStateChanged,playerController,PlayerState.AliveState)
end

---@public 杀死玩家，进入Dead状态（注意不是濒死状态）
function PlayerSystem:ServerKillPlayer(playerKey)
    if not UGCGameSystem.IsServer() then
        return
    end
    ---@type UGCPlayerPawn_C
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    if playerPawn then
        UGCAttributeSystem.SetGameAttributeValue(playerPawn,UGCNativeGameAttributeType.Character_Health,0)
        UGCPlayerPawnSystem.EnterPawnState(playerPawn,EPawnState.Dead)
    else
        GameplayUtils.Print("PlayerSystem.ServerKillPlayer: 无法获取PlayerKey为 ",playerKey," 的PlayerPawn")
    end
end

---@public
function PlayerSystem:ServerStartSelfRescue(playerKey)
    if not UGCGameSystem.IsServer() then
        return
    end
    ---@type UGCPlayerPawn_C
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    if not playerPawn then
        return
    end
    playerPawn.PlayerAliveStateControlComponent:ServerStartSelfRescue()
end

---@public 玩家倒地后是否应该直接死亡
function PlayerSystem:ShouldPlayerDirectlyDie(playerKey)
    local rescueTime = self:GetSelfRescueTimes(playerKey)
    if rescueTime > 0 then
        return false
    end
    ---@type UGCPlayerPawn_C
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(playerKey)
    if playerPawn and playerPawn.PlayerAliveStateControlComponent:IsSelfRescuing() then
        return false
    end
    return true
end

---@public
---@return boolean
function PlayerSystem:AddPlayerScore(playerKey,score)
    local playerState = GameplaySystem.GetPlayerStateByPlayerKey(playerKey)
    if not playerState.PlayerInGameStatDataComponent then
        return false
    end
    playerState.PlayerInGameStatDataComponent:AddScore(score)
    return true
end

---@public
---@return number
function PlayerSystem:GetPlayerCurScore(playerKey)
    local playerState = GameplaySystem.GetPlayerStateByPlayerKey(playerKey)
    if not playerState.PlayerInGameStatDataComponent then
        return 0
    end
    return playerState.PlayerInGameStatDataComponent:GetCurScore()
end


---@public
---@return number
function PlayerSystem:GetPlayerTotalScore(playerKey)
    local playerState = GameplaySystem.GetPlayerStateByPlayerKey(playerKey)
    if not playerState.PlayerInGameStatDataComponent then
        return 0
    end
    return playerState.PlayerInGameStatDataComponent:GetTotalScore()
end

return PlayerSystem