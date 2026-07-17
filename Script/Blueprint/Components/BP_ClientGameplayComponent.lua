---@class BP_ClientGameplayComponent_C:ActorComponent
---@field AudioRoundEnd UAkAudioEvent
---@field AudioRoundStart UAkAudioEvent
---@field AudioZombieHeadshot ULuaArrayHelper<UAkAudioEvent>
--Edit Below--
--[[
    局内游戏客户端逻辑组件，主要配合BP_ServerGameplayComponent在客户端的表现，挂在PlayerController上
--]]
---@type BP_ClientGameplayComponent_C
local BP_ClientGameplayComponent = {
    ---@type BP_GameplayStateComponent
    GameplayStateComp = nil,
}

---@type UGCPlayerController_C
BP_ClientGameplayComponent.m_playerController = nil
 
--[[--]]
function BP_ClientGameplayComponent:ReceiveBeginPlay()
    BP_ClientGameplayComponent.SuperClass.ReceiveBeginPlay(self)
    if not UGCGameSystem.IsServer() then
        self:OnBeginPlay()
    end
end


--[[
function BP_ClientGameplayComponent:ReceiveTick(DeltaTime)
    BP_ClientGameplayComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function BP_ClientGameplayComponent:ReceiveEndPlay()
    BP_ClientGameplayComponent.SuperClass.ReceiveEndPlay(self)
    if not UGCGameSystem.IsServer() then
        self:OnEndPlay()
    end
end

function BP_ClientGameplayComponent:OnBeginPlay()
    ---@type UGCGameState_C
    local gameState = UGCGameSystem.GetGameState()
    self.GameplayStateComp = gameState.GameplayStateComponent

    self.m_playerController = UGCActorComponentUtility.GetOwner(self)

    local ClientEvts = GameplayEvents.Client
    UGCGenericMessageSystem.ListenUserDefinedGlobalMessage(self,ClientEvts.OnGameStateChanged,self,self.OnGameStateChanged)
    UGCGenericMessageSystem.ListenUserDefinedGlobalMessage(self,ClientEvts.OnRoundFlowChanged,self,self.OnRoundFlowChanged)
end

function BP_ClientGameplayComponent:OnEndPlay()
    local ClientEvts = GameplayEvents.Client
    UGCGenericMessageSystem.UnListenMessage(self,ClientEvts.OnGameStateChanged)
    UGCGenericMessageSystem.UnListenMessage(self,ClientEvts.OnRoundFlowChanged)
end

function BP_ClientGameplayComponent:GetAvailableClientRPCs()
    return "RPC_Client_OnHitZombie","RPC_Client_OnGainScore"
end

function BP_ClientGameplayComponent:OnGameStateChanged()
    local gameState = self.GameplayStateComp.GameStateInfo.GameState
    GameplayUtils.Print("BP_ClientGameplayComponent.OnGameStateChanged: 当前游戏状态：",gameState)
    if gameState == EGameState.Gaming then
        UGCWidgetManagerSystem.ShowTipsUI("游戏开始！")
    elseif gameState == EGameState.Settlement then
        UGCWidgetManagerSystem.ShowTipsUI("游戏结算！")
        --展示玩家数据界面
        UGCTimerUtility.CreateLuaTimer(2,function()
            self:ShowPlayerRecordDataUI(true)
        end,false)
        --
    elseif gameState == EGameState.GameEnd then
        UGCWidgetManagerSystem.ShowTipsUI("游戏结束！")
        --关闭玩家数据界面
        self:DestroyPlayerRecordDataUI()
        --返回大厅
        GameplaySystem.BackToLobby()
    end
end

function BP_ClientGameplayComponent:OnRoundFlowChanged()
    local roundFlow = self.GameplayStateComp.RoundFlowInfo
    local roundPhase = roundFlow.RoundPhase
    local curRound = roundFlow.CurRoundNum
    GameplayUtils.Print("BP_ClientGameplayComponent.OnRoundFlowChanged: 当前回合阶段：",roundPhase)
    if roundPhase == ERoundPhase.FreezePlayer then

    elseif roundPhase == ERoundPhase.RoundStart then
        UGCWidgetManagerSystem.ShowTipsUI(string.format("第%s回合开始！",curRound))
        --播放音乐
        --UGCSoundManagerSystem.PlaySound2D(self.AudioRoundStart)

        local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(self.m_playerController)
        UGCSoundManagerSystem.PlaySoundAtLocation(
                self.AudioRoundStart,
                playerPawn:K2_GetActorLocation(),
                playerPawn:K2_GetActorRotation()
        )
    elseif roundPhase == ERoundPhase.RoundEnd then
        UGCWidgetManagerSystem.ShowTipsUI(string.format("第%s回合结束！",curRound))
        --播放音乐
        --UGCSoundManagerSystem.PlaySound2D(self.AudioRoundEnd)
        UGCTimerUtility.CreateLuaTimer(1.4,function()
            if UE.IsValid(self) then
                local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(self.m_playerController)
                UGCSoundManagerSystem.PlaySoundAtLocation(
                        self.AudioRoundEnd,
                        playerPawn:K2_GetActorLocation(),
                        playerPawn:K2_GetActorRotation()
                )
            end
        end,false)
    end
end

---@private
---@param zombiePawn BP_Zombie_Base_C
---@param dmgPosition EAvatarDamagePosition
function BP_ClientGameplayComponent:RPC_Client_OnHitZombie(zombiePawn,dmgPosition,isDead)
    local isHeadshot = dmgPosition == EAvatarDamagePosition.BigHead
    if isHeadshot and isDead then
        --爆头音效
        local audioNum = self.AudioZombieHeadshot and self.AudioZombieHeadshot:Num() or 0
        if audioNum <= 0 then
            return
        end
        local audioIndex = math.random(1, audioNum)
        local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(self.m_playerController)
        --UGCSoundManagerSystem.PlaySound2D(self.AudioZombieHeadshot:Get(audioIndex))
        UGCSoundManagerSystem.PlaySoundAtLocation(
                self.AudioZombieHeadshot:Get(audioIndex),
                playerPawn:K2_GetActorLocation(),
                playerPawn:K2_GetActorRotation()
        )
    end
end

---@private
---@param score number
---@param dmgPosition EAvatarDamagePosition
function BP_ClientGameplayComponent:RPC_Client_OnGainScore(score,dmgPosition)
    local isHeadshot = dmgPosition == EAvatarDamagePosition.BigHead
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Client.OnLocalPlayerGainScore,score,isHeadshot)
end

---@public
---@return UUserWidget
function BP_ClientGameplayComponent:GetPlayerRecordDataUI()
    if self.m_resultUIWeakPtr and UGCObjectUtility.IsWeakObjectPtrValid(self.m_resultUIWeakPtr) then
        return UGCObjectUtility.GetObjectFromWeakObjectPtr(self.m_resultUIWeakPtr)
    end
    return nil
end

---@public
function BP_ClientGameplayComponent:DestroyPlayerRecordDataUI()
    if not self.m_resultUIWeakPtr then
        return
    end
    if not UGCObjectUtility.IsWeakObjectPtrValid(self.m_resultUIWeakPtr) then
        self.m_resultUIWeakPtr = nil
        return
    end
    ---@type UUserWidget
    local widget = UGCObjectUtility.GetObjectFromWeakObjectPtr(self.m_resultUIWeakPtr)
    UGCWidgetManagerSystem.RemoveFromSlot(widget)
end

---@protected
function BP_ClientGameplayComponent:CreatePlayerRecordDataUI(bShow)
    if self:GetPlayerRecordDataUI() == nil then
        local WidgetPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Game/UIBP/UGC_ResultTab_UIBP.UGC_ResultTab_UIBP_C')
        UGCWidgetManagerSystem.CreateWidgetAsync(WidgetPath, function(Widget)
            local UISlotName = 'UI.UISlot.MainUISlot_High'
            local ZOrder = 0
            local AnchorData = UGCObjectUtility.NewStruct("AnchorData")
            local Anchors = UGCObjectUtility.NewStruct("Anchors")
            Anchors.Maximum = Vector2D.New(1.0, 1.0)
            Anchors.Minimum = Vector2D.New(0, 0)
            AnchorData.Anchors = Anchors
            UGCWidgetManagerSystem.AddToSlot(Widget,UISlotName, ZOrder, AnchorData)
            UGCWidgetManagerSystem.ShowWidget(Widget)
            self.m_resultUIWeakPtr = UGCObjectUtility.MakeWeakObjectPtr(Widget)
            Widget.Button_Close:SetVisibility(ESlateVisibility.Collapsed)
        end)
    end
end

---@public
function BP_ClientGameplayComponent:ShowPlayerRecordDataUI(show)
    local ResultUI = self:GetPlayerRecordDataUI();
    if ResultUI then
        if show then
            UGCWidgetManagerSystem.ShowWidget(ResultUI)
        else
            UGCWidgetManagerSystem.HideWidget(ResultUI)
        end
    elseif show then
        self:CreatePlayerRecordDataUI(true);
    end
end

return BP_ClientGameplayComponent