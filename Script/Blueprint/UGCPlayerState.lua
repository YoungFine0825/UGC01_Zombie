---@class UGCPlayerState_C:BP_UGCPlayerState_C
---@field WeaponSystemComponent BP_PlayerStateWeaponSystemComponent_C
---@field PlayerInGameStatDataComponent BP_PlayerInGameStatDataComponent_C
---@field PlayerExp int32
---@field UGCPlayerLevel int32
--Edit Below--
local Delegate = require("common.Delegate")
local PromiseFuture = require("common.PromiseFuture")
---@type UGCPlayerState_C
local UGCPlayerState = {
    -- 玩家等级变化委托，当玩家等级同步时触发（客户端）
    PlayerLevelChangedDelegate = Delegate.New(),
    -- 玩家经验变化委托，当玩家经验同步时触发（客户端）
    PlayerExpChangedDelegate = Delegate.New(),
    -- 玩家游戏记录数据变化委托，当游戏GameGameRecord数据同步时触发（客户端）
    PlayerGameGameRecordDataDelegate = Delegate.New(),
    -- 游戏记录数据表，存储玩家游戏过程中的各种统计数据
    GameRecordData = {},
    --弃用 游戏完成记录表，存储玩家已解锁的游戏模式
    GameCompletionRecord = {},
}
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
local UGCGameState = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameState')
UGCPlayerState.RespawnConfig = {}

---@type Gameplay.PlayerGameRecordData
UGCPlayerState.GameRecordData = {
    TotalScore = 0,                       --积分点数
    TotalKill = 0,--击杀数
    TotalHeadshot = 0,--爆头数
    TotalDamage = 0,                     -- 总伤害
    ---- 旧字段
    LevelInfo = {},                      -- 每个关卡的分数
    TotalMonsterKill = 0,                -- 总击杀怪物
    TotalMonsterHeadshot = 0,
    TotalMonsterKillByType = {           -- 击杀不同类型的怪物
        Monster = 0,                     -- 普通怪物
        EliteMonster = 0,                -- 精英怪物
        Boss = 0                         -- BOSS
    },
    PlayerExp = 0,                       -- 玩家经验
    GameTime = 0,                        -- 游戏时间
    TotalCriticalHit = 0,                -- 总暴击
    CurrentStage = 1,                    -- 当前关卡
    LikeNum = 0,                         -- 点赞数
    Likes = {},                          -- 点赞列表
    ReceivedLikes = {},                  -- 收到的点赞列表
}

-- 初始化结算参数表
-- 该表用于存储游戏结算相关的状态信息
UGCPlayerState.SettleParams = {}
UGCPlayerState.SettleParams.bIsSettled = false  -- 标记当前是否已结算
UGCPlayerState.SettleParams.bIsFinished = true  -- 标记结算时流程是否已完成（是否胜利）
UGCPlayerState.IsModeUnLock = true  -- 模式默认全部解锁 by yangfan

--判断玩家所处的状态（Alive、Dying、Dead）
UGCPlayerState.AliveState = UGCGameData.AliveState.Alive;

-- 玩家在大厅中的准备状态，初始为未准备
UGCPlayerState.bIsReadyInLobby = false
-- 准备状态更新委托，用于通知准备状态变化（客户端）
UGCPlayerState.ReadyStateUpdateDelegate = Delegate.New()
-- 在线状态更新委托，用于通知玩家在线状态变化（客户端）
UGCPlayerState.OnlineStateUpdateDelegate = Delegate.New()
-- 判断当前玩家是否进入传送门，判断UI显隐
UGCPlayerState.bIsPlayerInPortalDoor = false

-- 玩家在线状态
UGCPlayerState.bIsOnline = true 

UGCPlayerState.bIsLobbyTeamLeader = false

UGCPlayerState.DyingInfo = {
    EndTime = 0,
    RemainingTime = 0,
    bEnabled = false,
}

function UGCPlayerState:GetReplicatedProperties()
    return {"RespawnConfig", "Lazy"}, {"HeroID", "Lazy"}, {"GameRecordData", "Lazy"}, {"GameCompletionRecord", "Lazy"},
    {"bIsReadyInLobby", "Lazy"}, {"SettleParams", "Lazy"}, {"bIsPlayerInPortalDoor", "Lazy"}, {"IsModeUnLock", "Lazy"},
    {"AliveState", "Lazy"}, {"bIsOnline", "Lazy"}, {"bIsLobbyTeamLeader", "Lazy"},{"GameStartTime", "Lazy"}
end

function UGCPlayerState:GetAvailableServerRPCs()
    return "RPC_Server_ReduceFreeReviveCount", "RPC_Server_ReducePaidReviveCount"
end

function UGCPlayerState:OnLevelChanged()
    ugcprint("[UGCPlayerState] OnLevelChanged")
end

function UGCPlayerState:ReceiveBeginPlay()
    UGCPlayerState.SuperClass.ReceiveBeginPlay(self)
    ugcprint(string.format("[UGCPlayerState] BeginPlay, GameStartTime: "..tostring(UGCPlayerState.GameStartTime)))
	if UGCGameSystem.IsServer() and UGCActorComponentUtility.GetOwner(self) then
        self:HandleBeginPlayInServer()
    elseif not UGCGameSystem.IsServer() and not UGCGameState.IsInLobby() then
        self:HandleBeginPlayInClientForFighting()
    end
end

function UGCPlayerState:HandleBeginPlayInServer()
    UGCPlayerState.GameStartTime = UGCGameSystem.GetServerTimeSec()
    UnrealNetwork.RepLazyProperty(self,"GameStartTime")
    local MsgPawnSpawn = UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnSpawn
    local MsgPawnRespawn = UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnRespawn
    UGCGenericMessageSystem.ListenGlobalMessage(self, MsgPawnSpawn, self, self.OnPawnSpawn)
    UGCGenericMessageSystem.ListenGlobalMessage(self, MsgPawnRespawn, self, self.OnPawnRespawn)

    -- if UGCGameState.IsInLobby() then
    --     print("UGCPlayerState:ReceiveBeginPlay bOnlySpector = true")
    --     self.bOnlySpectator = true
    -- else
    --     print("UGCPlayerState:ReceiveBeginPlay bOnlySpector = false")
    --     self.bOnlySpectator = false
    -- end

    -- 在玩家PostLogin之后执行初始化逻辑
    local Message = UGCGenericMessageSystem.Messages.UGC.Player.PlayerEnter
    UGCGenericMessageSystem.ListenGlobalMessage(self, Message, UGCActorComponentUtility.GetOwner(self), 
        function (...)
            self:OnPlayerEnter(...) 
        end
    );

    Message = UGCGenericMessageSystem.Messages.UGC.Player.PlayerLost
    UGCGenericMessageSystem.ListenGlobalMessage(self, Message, UGCActorComponentUtility.GetOwner(self),
        function (...)
            self:OnPlayerLost(...)
        end
    )

    Message = UGCGenericMessageSystem.Messages.UGC.Player.PlayerReconnect
    UGCGenericMessageSystem.ListenGlobalMessage(self, Message, UGCActorComponentUtility.GetOwner(self),
        function (...)
            self:OnPlayerReconnect(...)
        end
    )

    self.OnLevelChanged = Delegate.New()

    -- 获取复活配置
    self.RespawnConfig = UGCGameData.GetRespawnConfig(UGCMultiMode.GetModeID())
    UnrealNetwork.RepLazyProperty(self, "RespawnConfig")

    --绑定小怪事件
    local Msg3 = UGCGenericMessageSystem.Messages.UGC.MobPawn.PostTakeDamage
    local Msg4 = UGCGenericMessageSystem.Messages.UGC.MobPawn.PostBeKilled
    UGCGenericMessageSystem.ListenGlobalMessage(self, Msg3, self, self.OnMobPawnTakeDamage)
    UGCGenericMessageSystem.ListenGlobalMessage(self, Msg4, self, self.OnMobPawnBeKill)
    
    UGCGenericMessageSystem.ListenGlobalMessage(self, UGCGenericMessageSystem.Messages.UGC.LevelFlow.LevelBegin, self, self.UpdateCurrentStage)
end

function UGCPlayerState:HandleBeginPlayInClientForFighting()
    BreakthroughManager:AddOrUpdateResultPlayerState({GameRecordData = self.GameRecordData, UID = self:GetInt64UID(), IconURL = self.IconURL, Gender = self.Gender, FrameLevel = self.FrameLevel, PlayerLevel = self.PlayerLevel, PlayerName = self.PlayerName, PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerState(self)})
end

function UGCPlayerState:OnPawnSpawn()
    self:OnSpawnOrRespawn()
end

function UGCPlayerState:OnPawnRespawn()
    self:OnSpawnOrRespawn()

    if UGCGameSystem.IsServer() and UGCMultiMode.GetModeID() ~= 1001 then
        self:ApplyHeroSelectionAndTalentSkill()
    end
end

function UGCPlayerState:OnSpawnOrRespawn()
    if UGCGameSystem.IsServer() then
        ugcprint("[UGCPlayerState:OnSpawnOrRespawn] Called")

        local Uid = UGCGameSystem.GetUIDByPlayerState(self)
        local Data = GameplaySystem.PlayerSystem:ServerGetPlayerGameProfile(Uid)
        self.CustomData = Data

        -- 获取英雄配置
        if GameplaySystem.IsInLobby() then
            -- 大厅逻辑
        else
            -- 局内逻辑
        end
    end
end

function UGCPlayerState:OnPlayerEnter(_,PlayerKey)
    if UGCGameSystem.GetPlayerKeyByPlayerState(self) ~= PlayerKey then
        return
    end

    self.bIsOnline = true
    UnrealNetwork.RepLazyProperty(self, "bIsOnline")

    local Uid = UGCGameSystem.GetUIDByPlayerState(self)
    local Data = GameplaySystem.PlayerSystem:ServerGetPlayerGameProfile(Uid)
    self.CustomData = Data
    self.PlayerExp = Data.PlayerExp
    self.UGCPlayerLevel = Data.UGCPlayerLevel

    -- 获取等级配置
    ugcprint("[UGCPlayerState] Init Level: "..tostring(self.UGCPlayerLevel))
    ugcprint("[UGCPlayerState] Init Exp: "..tostring(self.PlayerExp))

    -- 英雄选择
    local ModeID = UGCMultiMode.GetModeID()
    if self:ReadHeroID() < 0 then self:SaveHeroID(HeroSelectionManager:GetFirstAvailableHeroID()) end
    if UGCGameData.GetGameModeName(ModeID) == UGCGameData.ModeName.Lobby then
        local function SelectHeroFromArchiveData()
            local PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerState(self)
            --if HeroSelectionManager:GetSelectedHeroID(PlayerKey) ~= self:ReadHeroID() then
            --    HeroSelectionManager:SelectHero(PlayerKey, self:ReadHeroID())
            --end
            HeroSelectionManager:SelectHero(PlayerKey, self:ReadHeroID())
        end

        HeroSelectionManager.OnHeroSelected:Add(function (PlayerKey, HeroID)
            if PlayerKey == UGCGameSystem.GetPlayerKeyByPlayerState(self) then
                self:SaveHeroID(HeroID)
            end
        end)

        if HeroSelectionManager:IsInitialized() then
            SelectHeroFromArchiveData()
        else
            HeroSelectionManager.OnInitialized:Add(SelectHeroFromArchiveData, self)
        end
    else
        if HeroSelectionManager:IsInitialized() then
            self:ApplyHeroSelectionAndTalentSkill()
        else
            HeroSelectionManager.OnInitialized:Add(self.ApplyHeroSelectionAndTalentSkill, self)
        end
    end

    self:SetShowTeammatePositionUI(UGCMultiMode.GetModeID() ~= 1001)
end

function UGCPlayerState:OnPlayerLost(_, PlayerKey)
    if UGCGameSystem.GetPlayerKeyByPlayerState(self) == PlayerKey then
        self.bIsOnline = false
        UnrealNetwork.RepLazyProperty(self, "bIsOnline")
    end
end

function UGCPlayerState:OnPlayerReconnect(_, PlayerKey)
    if UGCGameSystem.GetPlayerKeyByPlayerState(self) == PlayerKey then
        self.bIsOnline = true
        UnrealNetwork.RepLazyProperty(self, "bIsOnline")
    end
end

function UGCPlayerState:InitGameGameRecordData()
    local TotalLevelCount = UGCLevelFlowSystem.GetTotalLevelCount()
    if TotalLevelCount then
        for i = 1, TotalLevelCount do
            self.GameRecordData.LevelInfo[i] = {
                LevelDamage = 0,                 -- 该关卡总伤害
                LevelMonsterKill = 0,            -- 该关卡总击杀怪物
                LevelMonsterKillByType = {       -- 击杀不同类型的怪物
                    Monster = 0,                 -- 普通怪物
                    EliteMonster = 0,            -- 精英怪物
                    Boss = 0                     -- BOSS
                },
                LevelPlayerExp = 0,              -- 该关卡总经验
                LevelTime = 0,                   -- 该关卡游戏时间
                LevelCriticalHit = 0             -- 该关卡总暴击
            }
        end
        UnrealNetwork.RepLazyProperty(self, "GameRecordData")
        return
    end
end

function UGCPlayerState:ApplyHeroSelectionAndTalentSkill()
    assert(UGCMultiMode.GetModeID() ~= 1001)

    local function ApplyHeroSelection()
            HeroSelectionManager:ApplySelectedHeroData(UGCGameSystem.GetPlayerKeyByPlayerState(self), self:ReadHeroID())
        end
    if HeroSelectionManager:IsInitialized() then
        ApplyHeroSelection()
    else
        HeroSelectionManager.OnInitialized:Add(ApplyHeroSelection)
    end

    if TalentTreeManager:HasTalentSkillsForHero(self:ReadHeroID()) then
        TalentTreeManager:ApplySelectedHeroSkill(self:ReadHeroID())
    end
end

function UGCPlayerState:OnMobPawnTakeDamage(MobPawn, DamageCauser, EventInstigator, Damage, DamageContext)
    if EventInstigator and EventInstigator.PlayerState == self then
        GameplayUtils.Print("UGCPlayerState。OnMobPawnTakeDamage： ",Damage)
        local dmgPosition = UGCAttributeSystem.GetDamagePositionTypeFromContext(DamageContext)
        local isDead = UGCAttributeSystem.GetGameAttributeValue(MobPawn,"Health") <= 0
        local score = GameplaySystem.PlayerSystem:CalcuZombieDamageScore(MobPawn,Damage,DamageContext)
        local statComponent = self:GetInGameStatDataComponent()
        statComponent:AddStatData(EPlayerInGameStatKeys.TotalDamage,Damage)
        statComponent:AddStatData(EPlayerInGameStatKeys.TotalScore,score)
        --通知客户端玩家得分
        GameplaySystem.PlayerRPC:S2C_OnGainScore(EventInstigator,score,dmgPosition)
        --
        local isHeadshot = dmgPosition == EAvatarDamagePosition.BigHead
        if isHeadshot and isDead then
            GameplayUtils.Print("UGCPlayerState.OnMobPawnTakeDamage: 爆头击杀+1")
            statComponent:AddStatData(EPlayerInGameStatKeys.TotalHeadshot,1)
        end

        --通知客户端，丧尸被击中
        GameplaySystem.PlayerRPC:S2C_OnHitZombie(EventInstigator,MobPawn,dmgPosition,isDead)

    else
        GameplayUtils.Print("UGCPlayerState.OnMobPawnTakeDamage: EventInstigator is not self")
    end
end

function UGCPlayerState:OnMobPawnBeKill(MobPawn, Killer)
    if Killer and Killer.PlayerState == self then
        GameplayUtils.Print("UGCPlayerState.OnMobPawnBeKill")
        self:UpdateGameRecordData_MonsterKilled(MobPawn.MonsterType)
    end
end

function UGCPlayerState:UpdateCurrentStage(CurrentStage)
    ugcprint("UGCPlayerState:UpdateCurrentStage CurrentStage="..tostring(CurrentStage))
    self.GameRecordData.CurrentStage = CurrentStage
    UnrealNetwork.RepLazyProperty(self, "GameRecordData")
end

---@protected
function UGCPlayerState:UpdateGameRecordData_MonsterKilled(MonsterType)

    local statComponent = self:GetInGameStatDataComponent()
    statComponent:AddStatData(EPlayerInGameStatKeys.TotalKill,1)
end

function UGCPlayerState:SetLobbyReadyStatus(bIsReady)
    if not UGCGameSystem.IsServer() then
        return
    end
    
    self.bIsReadyInLobby = bIsReady
    UnrealNetwork.RepLazyProperty(self, "bIsReadyInLobby")
end

function UGCPlayerState:SetIsLobbyTeamLeader(bIsTeamLeader)
    if not UGCGameSystem.IsServer() then
        return
    end

    self.bIsLobbyTeamLeader = bIsTeamLeader
    UnrealNetwork.RepLazyProperty(self, "bIsTeamLeader")
end

function UGCPlayerState:AddExp(Delta)
    self.GameRecordData.PlayerExp = self.GameRecordData.PlayerExp + Delta
	if not UGCGameSystem.IsServer() then
        ugcprint("[UGCPlayerState] AddExp should not execute on client.")
        return
    end

    if self.FreezeExp then
        ugcprint("[UGCPlayerState] AddExp Failed, Reason: Exp Freezed.")
        return
    end

    ugcprint("[UGCPlayerState] Try AddExp: "..tostring(Delta))

    local InitialLevel = self.UGCPlayerLevel
    -- 处理升级的情况
    local NewExp = self.PlayerExp + Delta
    local LevelUp = false
    while true do
        local Cfg = UGCGameData.GetLevelConfig(self.UGCPlayerLevel)
        ugcprint("[UGCPlayerState] Level Cfg: "..tostring(Cfg))
        if Cfg and (NewExp >= Cfg.Exp)then
            NewExp = NewExp - Cfg.Exp
            self.UGCPlayerLevel = self.UGCPlayerLevel + 1
            LevelUp = true
        else
            break
        end
    end
    self.PlayerExp = NewExp

    -- 更新 Level 属性
    local Player = UGCGameSystem.GetPlayerPawnByPlayerState(self)
    if Player then
        UGCAttributeSystem.SetGameAttributeValue(Player, 'Level', self.UGCPlayerLevel)
        ugcprint("[UGCPlayerState] Level up: "..self.UGCPlayerLevel)
    end

    -- 存储数据
    self.CustomData.PlayerExp = self.PlayerExp
    self.CustomData.UGCPlayerLevel = self.UGCPlayerLevel
    GameplaySystem.PlayerSystem:ServerSavePlayerGameProfileByPlayerState(self, self.CustomData)

    if LevelUp then
        self.OnLevelChanged:Broadcast(InitialLevel, self.UGCPlayerLevel)
    end
end

function UGCPlayerState:ReadHeroID()
    assert(UGCActorComponentUtility.HasAuthority(self))
    local PlayerData = GameplaySystem.PlayerSystem:ServerGetPlayerGameProfileByPlayerState(self)
    ugcprint("[UGCPlayerState] ReadHeroID: " .. tostring(PlayerData.HeroID))
    return PlayerData.HeroID
end

function UGCPlayerState:SaveHeroID(HeroID)
    assert(UGCActorComponentUtility.HasAuthority(self))
    ugcprint("[UGCPlayerState] SaveHeroID: " .. tostring(HeroID))
    local PlayerData = GameplaySystem.PlayerSystem:ServerGetPlayerGameProfileByPlayerState(self)
    PlayerData.HeroID = HeroID
    GameplaySystem.PlayerSystem:ServerSavePlayerGameProfileByPlayerState(self,PlayerData)
end

function UGCPlayerState:ModifyLevel(NewLevel)
    if not NewLevel or NewLevel <= 0 then
        ugcprint("[UGCPlayerState] ModifyLevel NewLevel is invalid : "..tostring(NewLevel))
        return
    end

	if not UGCGameSystem.IsServer() then
        ugcprint("[UGCPlayerState] ModifyLevel should not execute on client.")
        return
    end

    local InitialLevel = self.UGCPlayerLevel
     self.UGCPlayerLevel = NewLevel

     -- 更新 Level 属性
     local Player = UGCGameSystem.GetPlayerPawnByPlayerState(self)
     if Player then
         UGCAttributeSystem.SetGameAttributeValue(Player, 'Level', self.UGCPlayerLevel)
         ugcprint("[UGCPlayerState] Level Changed: "..self.UGCPlayerLevel)
     end

     -- 存储数据
     self.CustomData.PlayerExp = self.PlayerExp
     self.CustomData.UGCPlayerLevel = self.UGCPlayerLevel
     GameplaySystem.PlayerSystem:ServerSavePlayerGameProfileByPlayerState(self, self.CustomData)

    ugcprint(string.format("[UGCPlayerState] Level OnLevelChanged, Initial Level = %s, Current Level = %s: ", InitialLevel, self.UGCPlayerLevel))
    self.OnLevelChanged:Broadcast(InitialLevel, self.UGCPlayerLevel)
end

function UGCPlayerState:ToggleFreezeExp()
    self.FreezeExp = not self.FreezeExp
    ugcprint("[UGCPlayerState] ToggleFreezeExp: "..tostring(self.FreezeExp))
end

function UGCPlayerState:ReduceFreeRespawnCount()
    self.RespawnConfig.CurrentFreeReviveCount = self.RespawnConfig.CurrentFreeReviveCount - 1
    UnrealNetwork.RepLazyProperty(self, "RespawnConfig.CurrentFreeReviveCount")
    ugcprint("RespawnConfigTable.CurrentFreeReviveCount = "..self.RespawnConfig.CurrentFreeReviveCount)
end

function UGCPlayerState:ReducePaidRespawnCount()
    self.RespawnConfig.CurrentPaidReviveCount = self.RespawnConfig.CurrentPaidReviveCount - 1
    UnrealNetwork.RepLazyProperty(self, "RespawnConfig.CurrentPaidReviveCount")
    ugcprint("RespawnConfigTable.CurrentPaidReviveCount = "..self.RespawnConfig.CurrentPaidReviveCount)
end

function UGCPlayerState:ReceiveEndPlay()
    UGCPlayerState.SuperClass.ReceiveEndPlay(self)

    Delegate.RemoveAll(self.OnLevelChanged)
    Delegate.RemoveAll(self.PlayerLevelChangedDelegate)
    Delegate.RemoveAll(self.PlayerExpChangedDelegate)
    Delegate.RemoveAll(self.PlayerGameGameRecordDataDelegate)
end

function UGCPlayerState:OnRep_PlayerExp()
    self.PlayerExpChangedDelegate(self.PlayerExp)

    PromiseFuture.New():Set(
            function(P)
                while true do
                    local GameState = UGCGameSystem.GameState
                    local IsLobby = LobbyFlow:CurrentState() == LobbyFlowState.LFS_Lobby

                    if GameState and IsLobby then
                        LobbyUtils.UpdateWidget(LobbyWidgetType.LWT_MainLobby)
                        return
                    else
                        ugcprint("[UGCPlayerState] Waiting for GameState...")
                        P:Yield()
                    end
                end
            end
    ):AutoResume(self, 0.2, 60)
end

function UGCPlayerState:OnRep_UGCPlayerLevel()
    self.PlayerLevelChangedDelegate(self.UGCPlayerLevel)
end

function UGCPlayerState:OnRep_GameRecordData()
    ugcprint("[UGCPlayerState] OnRep_GameRecordData")
    self.PlayerGameGameRecordDataDelegate(self.GameRecordData)
    if self.SettleParams.bIsSettled then
        BreakthroughManager:RefreshBattleResultUI()
    end
    BreakthroughManager:AddOrUpdateResultPlayerState({GameRecordData = self.GameRecordData, UID = self:GetInt64UID(), IconURL = self.IconURL, Gender = self.Gender, FrameLevel = self.FrameLevel, PlayerLevel = self.PlayerLevel, PlayerName = self.PlayerName, PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerState(self)})
end

function UGCPlayerState:OnRep_GameCompletionRecord()
    ugcprint(string.format("[UGCPlayerState] OnRep_GameCompletionRecord : %s", table.concat(self.GameCompletionRecord, ",")))

    local function DoWork()
        local ModeID = UGCMultiMode.GetModeID()
        if ModeID == 1001 then
            -- 大厅逻辑
            LobbyUtils.UpdateWidget(LobbyWidgetType.LWT_MainLobby)
        else
            -- 局内逻辑
        end
    end

    PromiseFuture.New():Set(
            function(P)
                while true do
                    local GameState = UGCGameSystem.GameState
                    local IsLobby = LobbyFlow:CurrentState() == LobbyFlowState.LFS_Lobby

                    if GameState and IsLobby then
                        DoWork()
                        return
                    else
                        P:Yield()
                    end
                end
            end
    ):AutoResume(self, 0.2, 60)
end

function UGCPlayerState:OnRep_bIsReadyInLobby()
    local PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerState(self)
    ugcprint(string.format("[UGCPlayerState:OnRep_bIsReadyInLobby] PlayerKey=%d, bIsReadyInLobby=%s", PlayerKey, tostring(self.bIsReadyInLobby)))

    self.ReadyStateUpdateDelegate()
    LobbyUtils.UpdateWidget(LobbyWidgetType.LWT_MainLobby, {})
end

function UGCPlayerState:OnRep_bIsLobbyTeamLeader()
    local PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerState(self)
    ugcprint(string.format("[UGCPlayerState:OnRep_bIsLobbyTeamLeader] PlayerKey=%d, bIsLobbyTeamLeader=%s", PlayerKey, tostring(self.bIsLobbyTeamLeader)))

    self.ReadyStateUpdateDelegate()
    LobbyUtils.UpdateWidget(LobbyWidgetType.LWT_MainLobby, {})
end

function UGCPlayerState:OnRep_bIsOnline()
    local PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerState(self)
    ugcprint(string.format("[UGCPlayerState:OnRep_bIsOnline] PlayerKey=%d, bIsOnline=%s", PlayerKey, tostring(self.bIsOnline)))

    self.OnlineStateUpdateDelegate()
end

function UGCPlayerState:UpdateGameTime()
    self.GameRecordData.GameTime = UGCGameSystem.GetServerTimeSec() - self.GameStartTime
    UnrealNetwork.RepLazyProperty(self, "GameRecordData.GameTime")
    ugcprint(string.format("[UGCPlayerState] UpdateGameTime : %d", self.GameRecordData.GameTime))
end

function UGCPlayerState:OnRep_SettleParams()
    print(string.format("[UGCPlayerState] OnRep_SettleParams, bIsSettled is : %s, bIsFinished is : %s", tostring(self.SettleParams.bIsSettled), tostring(self.SettleParams.bIsFinished)))
    if self.SettleParams and self.SettleParams.bIsSettled then
        local PC = UGCGameSystem.GetPlayerControllerByPlayerState(self)
        if PC then
            PC:OnGameSettle()
        else
            print("[UGCPlayerState:OnRep_SettleParams] : PC is nil")
        end
    end
    if self.bIsPlayerInPortalDoor then
        -- 弹出跳转UI
    end
end

---@public
---@param newState Gameplay.EPlayerAliveState
function UGCPlayerState:ServerChangeAliveState(newState)
    self.AliveState = newState
    UnrealNetwork.RepLazyProperty(self, "AliveState")
end

function UGCPlayerState:OnRep_AliveState()
    ---@type UGCPlayerController_C
    local PC = UGCGameSystem.GetPlayerControllerByPlayerState(self)
    if not PC then
        --变化的是其他玩家，跳过
        GameplayUtils.Print("UGCPlayerState.OnRep_AliveState: 其他玩家生存状态发生变化: ",self.AliveState)
        return
    end
    GameplayUtils.Print("UGCPlayerState.OnRep_AliveState: 本地玩家生存状态发生变化: ",self.AliveState)
    --if self.AliveState == UGCGameData.AliveState.Dying then
    --    PC:OpenRespawnUI()
    --elseif self.AliveState == UGCGameData.AliveState.Dead then
    --    PC:OpenRespawnUI()
    --elseif self.AliveState == UGCGameData.AliveState.Alive then
    --    BreakthroughManager:CloseRespawnUI()
    --end

    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Client.OnLocalPlayerAliveStateChanged,self.AliveState)
end

function UGCPlayerState:ReceiveEndPlay()
    if UGCGameSystem.IsServer() then
        self:UpdateGameTime()
    end
end

---@public
---@return BP_PlayerInGameStatDataComponent_C
function UGCPlayerState:GetInGameStatDataComponent()
    return self.PlayerInGameStatDataComponent
end

return UGCPlayerState