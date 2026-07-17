---@class UGCPlayerController_C:BP_UGCPlayerController_C
---@field WeaponSystemComponent BP_PlayerControllerWeaponSystemComponent_C
---@field PlayerInteractEntityComponent BP_PlayerInteractEntityComponent_C
---@field ClientGameplayComponent BP_ClientGameplayComponent_C
---@field ShopV2Component ShopV2Component_C
---@field TalentTreeComponent TalentTreeComponent_C
--Edit Below--
--客户端侧gameplay相关子系统启动器
---@type GameplayBooter
local GameplayBooter = UGCGameSystem.UGCRequire("Script.Gameplay.GameplayBooter")
GameplayBooter.Construct()

UGCGameSystem.UGCRequire("Script.Blueprint.Arts_UI.Lobby.LobbyFlow")
UGCGameSystem.UGCRequire("Script.Blueprint.Arts_UI.Game.UIBP.Breakthrough.BreakthroughManager")
UGCGameSystem.UGCRequire("ExtendResource.ShopV2.OfficialPackage.".."Script.ShopV2.ShopV2Manager")

local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
local UGCGameState = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameState')
local PromiseFuture = require("common.PromiseFuture")
local Delegate = require("common.Delegate")

---@type UGCPlayerController_C
local UGCPlayerController = {}

UGCGameSystem.UGCRequire("Script.Blueprint.TimingListUtils")

-- GamePart是否加载完成
UGCPlayerController.GamePartReady = false
-- 是否是队长
UGCPlayerController.bIsTeamLeader = false
-- 大厅队友的PlayerKey
UGCPlayerController.LobbyTeammatePlayerKeys = {}
-- 大厅队友PlayerKey更新时的委托 
UGCPlayerController.OnLobbyTeammatePlayerKeysUpdate = Delegate.New()
UGCPlayerController.bDefaultWeaponGranted = false
UGCPlayerController.DefaultWeaponRetryTimer = nil

-- 大厅信息配置
UGCPlayerController.LobbyInfo = {
    -- 当前选择的模式ID（默认1002）
    SelectedModeID = 1002,
    -- 是否自动填充队友
    bFillTeammate = false,
    -- 是否队伍状态完整
    bTeamComplete = true,
    -- 是否在匹配中
    bIsMatching = false
}
 

function UGCPlayerController:GetAvailableServerRPCs()
    return "RPC_Server_RespawnPlayer", "RPC_Server_RequestRespawn", "RPC_Server_SetLobbyReadyStatus", "RPC_Server_EnterSpectating",
     "RPC_Server_TeleportToPortal", "RPC_Server_SetLobbySelectedModeID", "RPC_Server_SetFillTeammate", "RPC_Server_SetLobbybIsMatching","RPC_Server_LikeOther"
end

function UGCPlayerController:GetReplicatedProperties()
    return {"bIsTeamLeader", "Lazy"}, {"LobbyTeammatePlayerKeys", "Lazy"}, {"LobbyInfo", "Lazy"}
end

function UGCPlayerController:ReceiveBeginPlay()
    UGCPlayerController.SuperClass.ReceiveBeginPlay(self)

    if UGCGameSystem.IsServer() then
        if UGCGameState.IsInLobby() then
            self:HandleBeginPlayInServerForLobby()
        else
            self:HandleBeginPlayInServerForFighting()
        end
    else
        --
        GameplayBooter.BeginPlayOnClient()
        --
        if UGCGameState.IsInLobby() then
            self:HandleBeginPlayInClientForLobby()
        else
            self:HandleBeginPlayInClientForFighting()
        end
    end
    
end

function UGCPlayerController:HandleBeginPlayInServerForLobby()
    LobbyFlow:Go(LobbyFlowState.LFS_Lobby)
    UGCGenericMessageSystem.ListenGlobalMessage(self, UGCGenericMessageSystem.Messages.UGC.Player.PlayerEnter, self, self.InitInServer) -- 在PlayerEnter时初始化
    UGCGenericMessageSystem.ListenGlobalMessage(self, UGCGenericMessageSystem.Messages.UGC.Player.PlayerExit, self, self.OnPlayerExit)
end

function UGCPlayerController:HandleBeginPlayInServerForFighting()
    local ld = UGCTeamSystem.GetTeamLeaderKeyByTeamID(UGCTeamSystem.GetTeamIDByPlayerKey(UGCGameSystem.GetPlayerKeyByPlayerController(self)))
    print("[UGCPlayerController] HandleBeginPlayInServerForFighting "..#ld)
end


function UGCPlayerController:HandleBeginPlayInClientForLobby()    
    LobbyFlow:Go(LobbyFlowState.LFS_Lobby)
    local NewIndex = TimingListUtils.NewList()
    TimingListUtils.Add(NewIndex, 0, self, "GamePartReady")
    TimingListUtils.Add(NewIndex, 0, UGCGameSystem, "GameState", self, self.RecieveGamePartReady)
    TimingListUtils.Activate(NewIndex, 0.2, 20)
end

function UGCPlayerController:HandleBeginPlayInClientForFighting()
    local GamePartReadyMessage = UGCGenericMessageSystem.Messages.UGC.GamePart.GamePartLoaded
    local ChangeGamePartReady = function()
        self.GamePartReady = true
    end
    UGCGenericMessageSystem.ListenGlobalMessage(self, GamePartReadyMessage, self, ChangeGamePartReady)
    local NewIndex = TimingListUtils.NewList()
    TimingListUtils.Add(NewIndex, 0, self, "GamePartReady")
    TimingListUtils.Add(NewIndex, 0, UGCGameSystem, "GameState", self, self.RecieveGamePartReady)
    TimingListUtils.Activate(NewIndex, 0.2, 20)
    self:InitBattleMainUI()
end

function UGCPlayerController:InitInServer(PlayerKey)
    local bIsUGCPIE = UGCBlueprintFunctionLibrary.IsUGCPIE(self)
    if PlayerKey == UGCGameSystem.GetPlayerKeyByPlayerController(self) then
        self.bIsTeamLeader =  bIsUGCPIE and PlayerKey == 10001 or UGCTeamSystem.GetIsLeaderOrNotByPlayerKey(PlayerKey)
        -- self.bIsTeamLeader = true
        UnrealNetwork.RepLazyProperty(self, "bIsTeamLeader")
        UGCGameSystem.GetPlayerStateByPlayerController(self):SetIsLobbyTeamLeader(self.bIsTeamLeader)
        
        ---如果是队长则默认已准备
        self:RPC_Server_SetLobbyReadyStatus(self.bIsTeamLeader)
    end
    
    if bIsUGCPIE then
        self.LobbyTeammatePlayerKeys = UGCTeamSystem.GetPlayerKeysByTeamID(UGCTeamSystem.GetTeamIDByPlayerKey(UGCGameSystem.GetPlayerKeyByPlayerController(self)), true)
        -- self.LobbyTeammatePlayerKeys = {self.PlayerKey}
    else
        self.LobbyTeammatePlayerKeys = UGCTeamSystem.GetLobbyTeamKeysByPlayerKey(UGCGameSystem.GetPlayerKeyByPlayerController(self))
    end
    UnrealNetwork.RepLazyProperty(self, "LobbyTeammatePlayerKeys")

    ---给加入游戏的队友同步大厅信息
    if self.bIsTeamLeader then
        if not bIsUGCPIE then
            self.LobbyInfo.bTeamComplete = #UGCTeamSystem.GetLobbyTeamKeysByPlayerKey(self.PlayerKey) == #UGCTeamSystem.GetLobbyTeammateUIDsByUID(UGCGameSystem.GetUIDByPlayerController(self))
            UnrealNetwork.RepLazyProperty(self, "LobbyInfo.bTeamComplete")
        end

        for _, TeammatePlayerKey in ipairs(self.LobbyTeammatePlayerKeys) do
            if TeammatePlayerKey == PlayerKey then
                local PC = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
                PC:SetLobbyInfo(self.LobbyInfo)
                break     
            end
        end
    end
end

function UGCPlayerController:OnPlayerExit(PlayerKey)
    local bIsUGCPIE = UGCBlueprintFunctionLibrary.IsUGCPIE(self)
    
    for Index, TeammatePlayerKey in ipairs(self.LobbyTeammatePlayerKeys) do
        if TeammatePlayerKey == PlayerKey then
            self.LobbyInfo.bTeamComplete = false
            UnrealNetwork.RepLazyProperty(self, "LobbyInfo.bTeamComplete")
        end
    end
end

function UGCPlayerController:RecieveGamePartReady()
    ugcprint("[UGCPlayerController] ReceiveBeginPlay GamePartReady")

    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(self)

    if not PlayerState then
        print("[UGCPlayerController:RecieveGamePartReady] PlayerState is nil")
        return
    end

    if not PlayerState.SettleParams.bIsSettled then 
        PlayerState:OnRep_AliveState()
    end
    PlayerState:OnRep_SettleParams()
end

function UGCPlayerController:RecievePawnReady()
    local PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(self)
    UGCGameSystem.SetPlayerRespawnInfo(PlayerKey, true,UGCActorComponentUtility.GetActorTransform(UGCGameSystem.GetPlayerPawnByPlayerController(self)):Copy())
end

function UGCPlayerController:ReceiveTick(DeltaTime)
    GameplayBooter.OnTick(false,DeltaTime)
end

function UGCPlayerController:ReceiveEndPlay()
    if UGCGameSystem.IsServer() then
        UGCGenericMessageSystem.UnListenMessage(self, UGCGenericMessageSystem.Messages.UGC.Player.PlayerEnter) 
        UGCGenericMessageSystem.UnListenMessage(self, UGCGenericMessageSystem.Messages.UGC.Player.PlayerExit) 
    else
        GameplayBooter.EndPlayOnClient()
    end
end

function UGCPlayerController:InitBattleMainUI()
    if not UGCActorComponentUtility.HasAuthority(self) then
        ugcprint("UGCPlayerController:InitMainUI 1")

        local WidgetLayoutPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/UGCMainUI.UGCMainUI_C')
        UGCWidgetManagerSystem.LoadMainUIWidgetLayoutByPath(WidgetLayoutPath)

        PromiseFuture.New():Set(
            function (PromiseFuture)
                while true do
                    local BattleHUD = BattleHUDClass.GetBattleHUD(self)
                    if BattleHUD then
                        local Module = BattleHUD:GetModule("MainTeamModule")
                        if Module then
                            local WidgetPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Game/UIBP/Item/UGC_Team_LvNum_Item_UIBP.UGC_Team_LvNum_Item_UIBP_C')
                            local SocketName = 'CanvasPanelDynamicBefore'
                            Module:AddExpandWidget(WidgetPath, true, SocketName)
                            return
                        end
                    end
                    PromiseFuture:Yield()
                end
            end
        ):AutoResume(self, 0.2, 5)

        local PortalUIPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Game/UIBP/Teleport/UGC_Game_Teleport_Main_UBP.UGC_Game_Teleport_Main_UBP_C')
        UGCWidgetManagerSystem.AddNewUI(PortalUIPath, true)
    end
end

function UGCPlayerController:SetLobbyReadyStatus(bIsReady)
    UnrealNetwork.CallUnrealRPC(self, self, "RPC_Server_SetLobbyReadyStatus", bIsReady)
end

function UGCPlayerController:SetLobbyInfo(LobbyInfo)
    if UGCActorComponentUtility.HasAuthority(self) == false then
        return
    end

    print(string.format("UGCPlayerController:SetLobbyInfo ModeID=%d, bFillTeammate=%s", LobbyInfo.SelectedModeID, tostring(LobbyInfo.bFillTeammate)))

    self.LobbyInfo = LobbyInfo
    UnrealNetwork.RepLazyProperty(self, "LobbyInfo")
end

function UGCPlayerController:RPC_Server_SetLobbyReadyStatus(bIsReady)
    UGCGameSystem.GetPlayerStateByPlayerController(self):SetLobbyReadyStatus(bIsReady)
end

function UGCPlayerController:RPC_Server_RespawnPlayer()

    local pawn = UGCGameSystem.GetPlayerPawnByPlayerController(self)
        --判断是倒地还是死亡
    local DyingTag = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Dying")

    if pawn and UGCPersistEffectSystem.HasDynamicState(pawn, DyingTag) then
        ugcprint("[UGCPlayerController:RPC_Server_RespawnPlayer]")
        UGCPlayerPawnSystem.ConfirmRescueOtherImmediately(pawn, pawn)
        UGCPawnAttrSystem.SetHealth(pawn, UGCPawnAttrSystem.GetHealthMax(pawn))
    else
        local PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(self)
        ugcprint("UGCPlayerController:RPC_Server_RespawnPlayer")
        UGCGameSystem.RespawnPlayer(PlayerKey)

        local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(self)

        if not PlayerState then
            print("[UGCPlayerController:RPC_Server_RespawnPlayer]:PlayerState is nil")
            return
        end

        PlayerState.AliveState = UGCGameData.AliveState.Alive
        UnrealNetwork.RepLazyProperty(PlayerState, "AliveState")

        GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnPlayerAliveStateChanged,self,PlayerState.AliveState)
    end
end

function UGCPlayerController:RPC_Client_GameSettle(IsFinish)
    ugcprint("UGCPlayerController:RPCCallSettlement, IsFinish: " .. IsFinish)
    local ModeID = UGCMultiMode.GetModeID()
    ShopV2Manager:DeactivateRandomRefreshTab()
    BreakthroughManager:OpenBattleResultUI(ModeID, IsFinish)
end

function UGCPlayerController:RPC_Server_RmoveItem(PC, CoinID, Num)
    local BP_VirtualItemManager_GlobalActor = UGCBlueprintFunctionLibrary.GetGamePartGlobalActor(UGCGameSystem.GameState, "VirtualItemManager")
    BP_VirtualItemManager_GlobalActor:RemoveItem(PC, CoinID, Num)
end

---@public 打开复活界面
function UGCPlayerController:OpenRespawnUI()
    if UGCGameSystem.IsServer() then
        return
    end
    local ModeID = UGCMultiMode.GetModeID()
    BreakthroughManager:OpenRespawnUI(ModeID)
end

function UGCPlayerController:RPC_Server_RequestRespawn(bFreeRespawn)
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(self)

    if PlayerState == nil then
        print("[UGCPlayerController:RPC_Server_RequestRespawn] PlayerState is nil")
        return
    end

    if bFreeRespawn then
        self:RPC_Server_RespawnPlayer()
        PlayerState:ReduceFreeRespawnCount()
    else
        local VirtualItemManager = UGCGamePartSystem.VirtualItemManager.GetGlobalActor()
        if VirtualItemManager == nil then
            ugcprint("UGCPlayerController:RPC_Server_RequestCoinRespawn VirtualItemManager is nil")
            return
        end
        
        local CoinItemID = PlayerState.RespawnConfig.CurrencyID
        local Price = PlayerState.RespawnConfig.Price

        VirtualItemManager:RemoveItem(self, CoinItemID, Price, 
            function (Result)
                if Result.bSucceeded then
                    self:RPC_Server_RespawnPlayer()
                    PlayerState:ReducePaidRespawnCount()
                else
                    ugcprint("UGCPlayerController:RPC_Server_RequestCoinRespawn Coin respawn failed")
                end
            end
        )
    end
end

function UGCPlayerController:RPC_Server_SetLobbySelectedModeID(ModeID)
    if not UGCActorComponentUtility.HasAuthority(self) then
       return
    end
 
    if not self.bIsTeamLeader then
       print("UGCPlayerController:RPC_Server_SetLobbySelectedModeID PlayerKey="..tostring(UGCGameSystem.GetPlayerKeyByPlayerController(self)).." is not team leader!")
       return
    end

    --队长修改模式队友取消准备
    if self.LobbyInfo.SelectedModeID ~= ModeID then
        self.LobbyInfo.SelectedModeID = ModeID
        UnrealNetwork.RepLazyProperty(self, "LobbyInfo.SelectedModeID")

        local LeaderPlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(self)
        for _, PlayerKey in ipairs(self.LobbyTeammatePlayerKeys) do
            if PlayerKey ~= LeaderPlayerKey then
                local PC = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
                if PC ~= nil then
                    UGCGameSystem.GetPlayerStateByPlayerController(PC):SetLobbyReadyStatus(false)
                    PC:SetLobbyInfo(self.LobbyInfo)
                end
            end
        end
    end
end

function UGCPlayerController:RPC_Server_SetFillTeammate(bFillTeammate)
    if not UGCActorComponentUtility.HasAuthority(self) then
       return
    end
 
    if not self.bIsTeamLeader then
       print("UGCGameState:Server_ChangeLobbySelectedModeID PlayerKey="..tostring(UGCGameSystem.GetPlayerKeyByPlayerController(self)).." is not team leader!")
    end
 
    self.LobbyInfo.bFillTeammate = bFillTeammate
    UnrealNetwork.RepLazyProperty(self, "LobbyInfo.bFillTeammate")

    local LeaderPlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(self)
    for _, PlayerKey in ipairs(self.LobbyTeammatePlayerKeys) do
        if PlayerKey ~= LeaderPlayerKey then
            local PC = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
            if PC ~= nil then
                PC:SetLobbyInfo(self.LobbyInfo)
            end
        end
    end
end

function UGCPlayerController:RPC_Server_SetLobbybIsMatching(bIsMatching)
    if not UGCActorComponentUtility.HasAuthority(self) then
        return
     end
  
    if not self.bIsTeamLeader then
        print("UGCGameState:Server_ChangeLobbySelectedModeID PlayerKey="..tostring(UGCGameSystem.GetPlayerKeyByPlayerController(self)).." is not team leader!")
    end

    self.LobbyInfo.bIsMatching = bIsMatching
    UnrealNetwork.RepLazyProperty(self, "LobbyInfo.bIsMatching")

    local LeaderPlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(self)
    for _, PlayerKey in ipairs(self.LobbyTeammatePlayerKeys) do
        if PlayerKey ~= LeaderPlayerKey then
            local PC = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
            if PC ~= nil then
                PC:SetLobbyInfo(self.LobbyInfo)
            end
        end
    end
end

function UGCPlayerController:RPC_Server_TeleportToPortal()
    if UGCGameSystem.GameState.LevelState ~= UGCGameSystem.GameState.LevelStateEnum.Victory then
        -- 上行RPC安全处理规范，涉及到Server的RPC，需要在Server端进行安全检查或者校验，不能随意调用
        print("[UGCPlayerController:RPC_Server_TeleportToPortal] LevelState is not Victory")
        return
    end
    ugcprint(string.format("UGCPlayerController:RPC_Server_TeleportToPortal PlayerKey=%d", UGCGameSystem.GetPlayerKeyByPlayerController(self)))
    local CurPawn = UGCGameSystem.GetPlayerPawnByPlayerController(self)

    if CurPawn ~= nil and PortalManager.PortalActor ~= nil then
        local Position = PortalManager.PortalActor:K2_GetActorLocation()
        print("[UGCPlayerController:RPC_Server_TeleportToPortal] PortalActor's Position =[%s %s %s]", Position.X, Position.Y, Position.Z)
        Position.Z = Position.Z + 88
        CurPawn:DSTeleportToLocationOrRotation(Position, {}, true, false)
    end
end

function UGCPlayerController:RPC_Server_LikeOther(otherPlayerKey)
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(self)
    if PlayerState == nil then
        print("[UGCPlayerController:RPC_Server_LikeOther] PlayerState is nil")
        return
    end
    
    local otherPlayerState = UGCGameSystem.GetPlayerStateByPlayerKey(otherPlayerKey)
    if otherPlayerState == nil then
        print("[UGCPlayerController:RPC_Server_LikeOther] otherPlayerState is nil")
        return
    end

    otherPlayerState.GameRecordData.LikeNum = otherPlayerState.GameRecordData.LikeNum + 1

    local PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerState(PlayerState)
    local otherPlayerKey = UGCGameSystem.GetPlayerKeyByPlayerState(otherPlayerState)

    otherPlayerState.GameRecordData.ReceivedLikes[PlayerKey] = true
    PlayerState.GameRecordData.Likes[otherPlayerKey] = true
    
    UnrealNetwork.RepLazyProperty(otherPlayerState, "GameRecordData")
    UnrealNetwork.RepLazyProperty(PlayerState, "GameRecordData")
end

function UGCPlayerController:OnGameSettle()
    print("[UGCPlayerController:OnGameSettle]")
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(self)
    if not PlayerState then
        print("[UGCPlayerController:OnGameSettle] PlayerState is nil")
    end
    if PlayerState then
        ugcprint("UGCPlayerController:OnRep_bIsSettled, IsFinish: ".. tostring(PlayerState.SettleParams.bIsFinished).. "IsModeUnLock: ".. tostring(PlayerState.IsModeUnLock))
        local ModeID = UGCMultiMode.GetModeID()
        ShopV2Manager:DeactivateRandomRefreshTab()
        BreakthroughManager:OpenBattleResultUI(ModeID, PlayerState.SettleParams.bIsFinished, PlayerState.IsModeUnLock)
        BreakthroughManager:CloseRespawnUI()
    end
end

function UGCPlayerController:CallOpenShop()
    ugcprint("UGCPlayerController:CallOpenShop")
    local ModeID = UGCMultiMode.GetModeID()
    local CurrentStage = UGCLevelFlowSystem.GetCurrentLevelStage(self)
    local DropGroupID = UGCGameData.GetShopAfterLevelDropGroupID(ModeID, CurrentStage)
    ShopV2Manager:ActivateRandomRefreshTab(self, DropGroupID)
end

function UGCPlayerController:CallShutDownShop()
    ShopV2Manager:DeactivateRandomRefreshTab(self)
end

function UGCPlayerController:RPC_Server_EnterSpectating()
    ugcprint("UGCPlayerController:RPC_Server_EnterSpectating")
    UGCGameSystem.EnterSpectating(self)
    ugcprint("UGCPlayerController:RPC_Server_EnterSpectating Done")
end

function UGCPlayerController:OnRep_bIsPlayerInPortalDoor()
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(self)
    if PlayerState == nil then
        print("[UGCPlayerController:OnRep_bIsPlayerInPortalDoor] PlayerState is nil")
        return
    end
    if PlayerState.SettleParams.bIsSettled and PlayerState.SettleParams.bIsFinished and PlayerState.bIsPlayerInPortalDoor then
        -- 弹出跳转UI
    end
end

function UGCPlayerController:OnRep_LobbyTeammatePlayerKeys()
    ugcprint("UGCPlayerController:OnRep_LobbyTeammatePlayerKeys")
    self.OnLobbyTeammatePlayerKeysUpdate()
end

function UGCPlayerController:OnRep_LobbyInfo()
    print(string.format("UGCPlayerController:OnRep_LobbyInfo PlayerKey=%s ModeID=%d", tostring(UGCGameSystem.GetPlayerKeyByPlayerController(self)), self.LobbyInfo.SelectedModeID))

    -- if not self.LobbyInfo.bTeamComplete then
    --     UGCWidgetManagerSystem.ShowTipsUI("队伍有成员退出，请退出玩法重新进入")
    --     return
    -- end

    LobbyModel.CurrentSelectedModeID = self.LobbyInfo.SelectedModeID
    LobbyModel.bIsMatching = self.LobbyInfo.bIsMatching
    LobbyEvent.OnModeSelected(self.LobbyInfo.SelectedModeID)
    LobbyUtils.UpdateWidget(LobbyWidgetType.LWT_MainLobby, { ModeID = self.LobbyInfo.SelectedModeID, bIsMatching = self.LobbyInfo.bIsMatching })
end

---@public 改变玩家生命状态。仅限于服务端
---@param State Gameplay.EPlayerAliveState
function UGCPlayerController:ServerChangeState(NewState,PreviousState)
    ---@type UGCPlayerState_C
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(self)

    if PlayerState == nil then
        print("[UGCPlayerController:ChangeState] PlayerState is nil")
        return
    end

    PlayerState:ServerChangeAliveState(NewState)

    --if NewState == EPlayerAliveState.Dead then
    --    --UGCGameSystem.SetPlayerRespawnInfo(UGCGameSystem.GetPlayerKeyByPlayerController(self), true, UGCActorComponentUtility.GetActorTransform(UGCGameSystem.GetPlayerPawnByPlayerController(self)):Copy())
    --    UGCPlayerPawnSystem.SetDefaultPlayerRespawnPointSelectionMethod(EUGCPlayerRespawnPointSelectionMethod.RespawnOnTheSpot)
    --    UGCGameSystem.GameState:OnPlayerDead(UGCGameSystem.GetPlayerKeyByPlayerController(self))
    --elseif NewState == EPlayerAliveState.Alive then
    --    UGCGameSystem.GameState:OnPlayerAlive(UGCGameSystem.GetPlayerKeyByPlayerController(self))
    --end

    if NewState == EPlayerAliveState.Dead then
        GameplaySystem.PlayerSystem:ServerEnableSpectating(self,true)
    elseif NewState == EPlayerAliveState.Alive then
        GameplaySystem.PlayerSystem:ServerEnableSpectating(self,false)
    end

    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnPlayerAliveStateChanged,self,NewState,PreviousState)
end

---@public
---@return BP_ClientGameplayComponent_C
function UGCPlayerController:GetClientGameplayComponent()
    return self.ClientGameplayComponent
end

return UGCPlayerController
