---@class UGCPlayerPawn_C:BP_UGCPlayerPawn_C
---@field WeaponSystemComponent BP_PlayerPawnWeaponSystemComponent_C
---@field PlayerAutoRecoverHpComponent BP_PlayerAutoRecoverHpComponent_C
---@field PlayerAliveStateControlComponent BP_PlayerAliveStateControlComponent_C
---@field PlayerStaminaComponent PlayerStaminaComponent_C
---@field PlayerLevel int32
--Edit Below--
---@type UGCPlayerPawn_C
local UGCPlayerPawn = {}
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
 
function UGCPlayerPawn:ReceiveBeginPlay()

    UGCPlayerPawn.SuperClass.ReceiveBeginPlay(self)
    
    if UGCGameSystem.IsServer() then
        self:InitInServer()
    else
        self:OnRep_CoverAllAvatarMeshInfo()
    end

    if UGCGameData.GetGameModeName(UGCMultiMode.GetModeID()) == UGCGameData.ModeName.Lobby then
        UAEClosure_PlayerStaticFunction.SetCharacterMovementEnable(self, false)
    end
end

function UGCPlayerPawn:InitInServer()
    -- 玩家死亡不生成死亡盒子
    UGCPlayerPawnSystem.SkipSpawnDeadTombBox(self,true)

    --不直接死亡
    UGCPlayerPawnSystem.SetIsDirectlyDie(self,false)

    -- 玩家每次出生或者复活后无敌一段时间
    UGCGenericMessageSystem.ListenGlobalMessage(self, UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnRespawn, self, self.OnRespawn)

    ugcprint("UGCPlayerPawn:InitInServer "..tostring(self.PlayerName))

    --监听受伤
    UGCGenericMessageSystem.ListenGlobalMessage(self,"UGC.PlayerPawn.PreTakeDamage",self,self.LuaPreTakeDamage)
    UGCGenericMessageSystem.ListenGlobalMessage(self,"UGC.PlayerPawn.PostTakeDamage",self,self.LuaPostTakeDamage)
end

function UGCPlayerPawn:ReceiveEndPlay()
    UGCPlayerPawn.SuperClass.ReceiveEndPlay(self)
    UGCGenericMessageSystem.UnListenMessage(self, "UGC.PlayerPawn.PreTakeDamage")
    UGCGenericMessageSystem.UnListenMessage(self, "UGC.PlayerPawn.PostTakeDamage")
end

function UGCPlayerPawn:OnRespawn(_, PlayerKey)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(PlayerKey)
    GameplayUtils.Print("UGCPlayerPawn.OnRespawn: 玩家",playerPawn.PlayerName,"复活！！")
    --
    UGCPlayerPawnSystem.SetIsInvincible(playerPawn, true)
    self.InvincibleTimer = UGCTimerUtility.CreateLuaTimer(
        5, function()
                local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(PlayerKey)
                UGCPlayerPawnSystem.SetIsInvincible(playerPawn, false)
        end, false
    )
end

--[[
function UGCPlayerPawn:ReceiveTick(DeltaTime)
    UGCPlayerPawn.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

-- function UGCPlayerPawn:ReceiveEndPlay()
--     UGCPlayerPawn.SuperClass.ReceiveEndPlay(self) 
-- end

function UGCPlayerPawn:GetReplicatedProperties()
    return { "__SubObjectRepList", "Lazy"}
end

--[[
function UGCPlayerPawn:GetAvailableServerRPCs()
    return
end
--]]

---@private
---生效范围：服务器
---@param VictimPlayer ASTExtraBaseCharacter|AUGCMobCharacter @造成伤害的玩家角色|怪物
---@param DamageCauserActor AActor @伤害来源
---@param EventInstigator Controller @伤害来源的玩家控制器
---@param Damage float @伤害值
---@param DamageContext FGameMagnitudeContext @伤害事件上下文
function UGCPlayerPawn:LuaPreTakeDamage(VictimPlayer, DamageCauserActor, EventInstigator, Damage, DamageContext)
    --local playerKey = UGCGameSystem.GetPlayerKeyByPlayerPawn(VictimPlayer)
    --if playerKey == self:GetPlayerKey() then
    --    if self.PlayerAliveStateControlComponent:GetAliveState() == EPlayerAliveState.Dying then
    --        GameplayUtils.Print("UGCPlayerPawn.LuaPreTakeDamage: 玩家",playerKey,"倒地受到伤害 ",Damage)
    --    end
    --end
end

--判断武器伤害类型
---生效范围：服务器
---@param VictimPlayer ASTExtraBaseCharacter|AUGCMobCharacter @造成伤害的玩家角色|怪物
---@param DamageCauserActor AActor @伤害来源
---@param EventInstigator Controller @伤害来源的玩家控制器
---@param Damage float @伤害值
---@param DamageContext FGameMagnitudeContext @伤害事件上下文
function UGCPlayerPawn:LuaPostTakeDamage(VictimPlayer, DamageCauserActor, EventInstigator, Damage, DamageContext)
    GameplayUtils.Print("UGCPlayerPawn.LuaPostTakeDamage: 玩家",self:GetPlayerKey(),"受到伤害 ",Damage)
end

---@public
function UGCPlayerPawn:GetPlayerKey()
    if not self.m_playerKey then
        self.m_playerKey = UGCGameSystem.GetPlayerKeyByPlayerPawn(self)
    end
    return self.m_playerKey
end

---@public
function UGCPlayerPawn:EnableHitbox(enabled)
    local hitboxes = {
        self.HitBox_Stand,
        self.HitBox_Prone
    }
    for k,v in pairs(hitboxes) do
        v:SetCollisionEnabled(enabled and 1 or 0)
    end
end
return UGCPlayerPawn