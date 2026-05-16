---@class UGC_Lobby_Main_UIBP_C:UUserWidget
---@field Button_CancelMatch UButton
---@field Button_CancelReady UButton
---@field Button_DifficultySelect UButton
---@field Button_Ready UButton
---@field Button_Show UButton
---@field CanvasPanel_CancelReady UCanvasPanel
---@field CanvasPanel_Difficulty UCanvasPanel
---@field CanvasPanel_Matching UCanvasPanel
---@field CanvasPanel_ModeSelect UCanvasPanel
---@field CanvasPanel_Ready UCanvasPanel
---@field CanvasPanel_Root UCanvasPanel
---@field CanvasPanel_SelectDifficult UCanvasPanel
---@field CanvasPanel_Time UCanvasPanel
---@field Challenge UCanvasPanel
---@field Currency_Item01 UGC_Currency_Item_UIBP_C
---@field EXFunction1 UButton
---@field EXFunction2 UButton
---@field EXFunction3 UButton
---@field EXFunction4 UButton
---@field FillTeammateCheckBox UCheckBox
---@field FillTeammatePanel UCanvasPanel
---@field Function1 UButton
---@field Function2 UButton
---@field Function3 UButton
---@field Function4 UButton
---@field Function5 UButton
---@field Function6 UButton
---@field HorizontalBox_Currency UHorizontalBox
---@field Image_Talent_RedPoint UImage
---@field ImageEx_GameMode UImage
---@field NewButton_Action_NoUI UButton
---@field NewButton_ChangeHero UButton
---@field NewButton_Close UButton
---@field NewButton_ModeSelect UButton
---@field NewButton_Speak_NoUI UButton
---@field NewButton_Talk_NoUI UButton
---@field NewButton_Voice_NoUI UButton
---@field TeammateStatus_1 UGC_TeammateStatus_Item_UIBP_C
---@field TeammateStatus_2 UGC_TeammateStatus_Item_UIBP_C
---@field TeammateStatus_3 UGC_TeammateStatus_Item_UIBP_C
---@field TeammateStatus_4 UGC_TeammateStatus_Item_UIBP_C
---@field TextBlock_Auto UTextBlock
---@field TextBlock_Countdown UTextBlock
---@field TextBlock_Difficult UTextBlock
---@field TextBlock_EXFunction1 UTextBlock
---@field TextBlock_EXFunction2 UTextBlock
---@field TextBlock_EXFunction3 UTextBlock
---@field TextBlock_EXFunction4 UTextBlock
---@field TextBlock_Function1 UTextBlock
---@field TextBlock_Function2 UTextBlock
---@field TextBlock_Function3 UTextBlock
---@field TextBlock_Function4 UTextBlock
---@field TextBlock_Function5 UTextBlock
---@field TextBlock_Function6 UTextBlock
---@field TextBlock_MatchingTime UTextBlock
---@field TextBlock_ModeName UTextBlock
---@field UGC_PlayerMessage UGC_Avator_Item_UIBP_C
---@field UGC_ReuseList2_Difficulty UGC_ReuseList2_C
---@field WidgetSwitcher_Arrow UWidgetSwitcher
---@field WidgetSwitcher_Matching UWidgetSwitcher
---@field WidgetSwitcher_Time UWidgetSwitcher
--Edit Below--

---@type UGC_Lobby_Main_UIBP_C
local UGC_Lobby_Main_UIBP = {}

function UGC_Lobby_Main_UIBP:Construct()
    -- 内部按钮事件
    self.NewButton_Close.OnClicked:Add(self.OnCloseClicked, self)
    self.NewButton_ModeSelect.OnClicked:Add(self.OnModeSelectClicked, self)
    self.Button_Show.OnClicked:Add(self.OnMatchClicked, self)
    self.Button_CancelMatch.OnClicked:Add(self.OnCancelMatchClicked, self)
    self.Button_Ready.OnClicked:Add(self.OnReadyClicked, self)
    self.Button_CancelReady.OnClicked:Add(self.OnCancelReadyClicked,self)
    self.Button_DifficultySelect.OnClicked:Add(self.OnDifficultySelectClicked, self)
    self.NewButton_ChangeHero.OnClicked:Add(self.OnChangeHeroClicked, self)
    
    self.FillTeammateCheckBox.OnCheckStateChanged:Add(self.OnFillTeammateStateChange, self)

    -- 功能按钮
    self.Function2.OnClicked:Add(self.OnShopClicked, self)
    self.Function3.OnClicked:Add(self.OnTalentTreeClicked, self)
    self.Function4.OnClicked:Add(self.OnHeroClicked, self)
    self.EXFunction4.OnClicked:Add(self.OnWarehouseClicked, self)
    
    -- 其他 UI 事件
    self.UGC_ReuseList2_Difficulty.OnAfterNewItem:Add(self.UGC_ReuseList2_Difficulty_OnAfterNewItem, self)

    -- 隐藏天赋红点
    self.Image_Talent_RedPoint:SetVisibility(ESlateVisibility.Collapsed)

    -- 显示绿洲币按钮
    UGCCommoditySystem.ShowRechargeEntryUI():Then(
            function (Result)
                local UI = Result:Get()
                if UI ~= nil then
                    UI:RemoveFromParent()
                    self.HorizontalBox_Currency:AddChild(UI)
                    UI:SetVisibility(ESlateVisibility.Visible)
                end
            end
    )
    -- TODO: 处理 ELSE：充值通道未打开

    -- 适配异形屏
    self:ShowWidgetLayoutData(self.CanvasPanel_Root)
    UICommonFunctionLibrary.SetAdaptation(self.CanvasPanel_Root, self.CanvasPanel_Root)
    self:ShowWidgetLayoutData(self.CanvasPanel_Root)
end

function UGC_Lobby_Main_UIBP:Destruct()
    self.NewButton_Close.OnClicked:Remove(self.OnCloseClicked, self)
    self.Button_Show.OnClicked:Remove(self.OnMatchClicked, self)
    self.Button_CancelMatch.OnClicked:Remove(self.OnCancelMatchClicked, self)
    self.Button_Ready.OnClicked:Remove(self.OnReadyClicked, self)
    self.Button_CancelReady.OnClicked:Remove(self.OnCancelReadyClicked)
    self.Button_DifficultySelect.OnClicked:Remove(self.OnDifficultySelectClicked, self)
    self.NewButton_ChangeHero.OnClicked:Remove(self.OnChangeHeroClicked, self)

    self.FillTeammateCheckBox.OnCheckStateChanged:Remove(self.OnFillTeammateStateChange, self)

    self.Function2.OnClicked:Remove(self.OnShopClicked, self)
    self.Function3.OnClicked:Remove(self.OnTalentTreeClicked, self)
    self.Function4.OnClicked:Remove(self.OnHeroClicked, self)
    self.EXFunction4.OnClicked:Remove(self.OnWarehouseClicked, self)

    self.UGC_ReuseList2_Difficulty.OnAfterNewItem:Remove(self.UGC_ReuseList2_Difficulty_OnAfterNewItem, self)
end

function UGC_Lobby_Main_UIBP:OnOpen(Data)
    LobbyUtils.SetOtherWidgetHidden(true)
    self:ToggleDifficulty(false)

    ---@see UGC_Currency_Item_UIBP_C#OnUpdate
    self.Currency_Item01:OnGamePartLoaded()

    local PC = UGCGameSystem.GetLocalPlayerController()

    --处理断线重连（杀进程）
    --PC.PlayerControllerReconnectedDelegate:Add(self.OnPlayerReconnect, self)
    --处理静默重连（断网弱网）
    PC.OnReconnected:Add(self.OnPlayerReconnected, self)
    --处理 JoyStick UI 刷新
    PC.OnTouchInterfaceChangedDelegate:Add(self.OnTouchInterfaceChanged, self)
end

function UGC_Lobby_Main_UIBP:OnClose()
    LobbyUtils.SetOtherWidgetHidden(false)

    local PC = UGCGameSystem.GetLocalPlayerController()

    --PC.PlayerControllerReconnectedDelegate:Remove(self.OnPlayerReconnect, self)
    PC.OnReconnected:Remove(self.OnPlayerReconnected, self)
    PC.OnTouchInterfaceChangedDelegate:Remove(self.OnTouchInterfaceChanged, self)
end

function UGC_Lobby_Main_UIBP:OnUpdate(Data)
    self.Data = Data

    -- 更新模式信息
    self:UpdateMode()
    -- 更新匹配信息
    self:UpdateMatch()
    -- 更新难度信息
    self:UpdateDifficulty()
    -- 更新玩家信息
    UGCTimerUtility.CreateLuaTimer(0.2, function() self:UpdatePlayerData() end)
    -- 更新货币信息
    self.Currency_Item01:OnGamePartLoaded()
    -- 更新天赋点信息
    if TalentTreeManager and TalentTreeManager:HasAvailableTalentPoints() then
        self.Image_Talent_RedPoint:SetVisibility(ESlateVisibility.Visible)
    else
        self.Image_Talent_RedPoint:SetVisibility(ESlateVisibility.Collapsed)
    end

    self:RefreshTeammateStatus(self.Data.Index, self.Data.PlayerState)

    local PC = UGCGameSystem.GetLocalPlayerController()
    if PC ~= nil and UGCGameSystem.GetPlayerStateByPlayerController(PC) ~= nil then
        if UGCGameSystem.GetPlayerStateByPlayerController(PC).bIsLobbyTeamLeader then
            self.WidgetSwitcher_Matching:SetActiveWidgetIndex(0)
        elseif UGCGameSystem.GetPlayerStateByPlayerController(PC) then
            self.WidgetSwitcher_Matching:SetActiveWidgetIndex(UGCGameSystem.GetPlayerStateByPlayerController(PC).bIsReadyInLobby and 2 or 1)
        else
            self.WidgetSwitcher_Matching:SetActiveWidgetIndex(1)
        end

        self.FillTeammateCheckBox:SetIsChecked(PC.LobbyInfo.bFillTeammate) 
    end
end

function UGC_Lobby_Main_UIBP:OnPlayerReconnected()
    ugcprint("UGC_Lobby_Main_UIBP:OnPlayerReconnected()")
end

function UGC_Lobby_Main_UIBP:OnTouchInterfaceChanged()
    ugcprint("UGC_Lobby_Main_UIBP:OnTouchInterfaceChanged()")
    UGCTimerUtility.CreateLuaTimer(-1, function()
        UGCWidgetManagerSystem.SetVirtualJoystickVisibility(false)
    end)
end

function UGC_Lobby_Main_UIBP:UpdateMode()
    print("UGC_Lobby_Main_UIBP:UpdateMode Data.ModeID="..tostring(self.Data.ModeID) .. "CurrentSelectedModeID=" .. tostring( LobbyModel:GetCurrentSelectedModeID()))
    local ModeID = self.Data.ModeID or LobbyModel:GetCurrentSelectedModeID()
    local ModeConfig = LobbyModel:GetModeConfig(ModeID)

    -- 刷新模式名称
    self.TextBlock_ModeName:SetText(LobbyUtils.GetTrimmedString(ModeConfig.ModeName, 6))

    -- 刷新模式图标
    self.ImageEx_GameMode:SetBrushFromTexture(ModeConfig.ModeBanner, false)

    --单人模式无需匹配队友
    local ModeMaxPlayerNum = UGCMultiMode.GetModeSetting(LobbyModel.CurrentSelectedModeID).TeamPlayers
    if ModeMaxPlayerNum <= 1 then
        self.FillTeammatePanel:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.FillTeammatePanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

function UGC_Lobby_Main_UIBP:UpdateMatch()
    ugcprint("UGC_Lobby_Main_UIBP:UpdateMatch()")
    if self.Data.bIsMatching == nil then
        return
    end

    if self.Data.bIsMatching then
        ugcprint("UGC_Lobby_Main_UIBP:UpdateMatch(): bIsMatching = true")
        self.Challenge:SetVisibility(ESlateVisibility.Collapsed)
        self.CanvasPanel_Matching:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.WidgetSwitcher_Matching:SetVisibility(ESlateVisibility.Collapsed)

        if not self.MatchingTimer then
            self.TextBlock_MatchingTime:SetText("00:00")
            self.MatchingStartTime = os.time()
            self.MatchingTimer = UGCTimerUtility.CreateLuaTimer(0.5, function()
                local MatchingPassTime = os.time() - self.MatchingStartTime
                self.TextBlock_MatchingTime:SetText(string.format("%02d:%02d", MatchingPassTime // 60, MatchingPassTime % 60))
                if UGCGameSystem.GameState then
                    if MatchingPassTime > UGCGameSystem.GameState.MatchTimeout then
                        local PC = UGCGameSystem.GetLocalPlayerController()
                        if PC and PC.bIsTeamLeader then
                            LobbyModel:CancelMatch()
                        end

                        UGCWidgetManagerSystem.ShowTipsUI("当前游玩人数不足，请稍后再试")
                    end
                end
            end, true)
        end
    else
        ugcprint("UGC_Lobby_Main_UIBP:UpdateMatch(): bIsMatching = false")
        self.Challenge:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.CanvasPanel_Matching:SetVisibility(ESlateVisibility.Collapsed)
        self.WidgetSwitcher_Matching:SetVisibility(ESlateVisibility.SelfHitTestInvisible)

        if self.MatchingTimer then
            UGCTimerUtility.RemoveLuaTimer(self.MatchingTimer)
            self.MatchingTimer = nil
        end
    end
end

function UGC_Lobby_Main_UIBP:UpdateDifficulty()
    if self.Data.Difficulty or LobbyModel:GetCurrentSelectedDifficulty() then
        local Difficulty = self.Data.Difficulty or LobbyModel:GetCurrentSelectedDifficulty()
        self.TextBlock_Difficult:SetText(Difficulty)
        self:ToggleDifficulty(false)
    end

    ---@see UGC_Lobby_Main_UIBP_C#UGC_ReuseList2_Difficulty_OnAfterNewItem
    self.UGC_ReuseList2_Difficulty:Reload(#LobbyModel:GetModeListWithSameDetailID())
end

function UGC_Lobby_Main_UIBP:UpdatePlayerData()
    local PlayerState = UGCGameSystem.GetLocalPlayerState()
    local PlayerKey = UGCPlayerStateSystem.GetPlayerKeyInt64(PlayerState)
    local PlayerInfo = ScriptGameplayStatics.GetPlayerAccountInfo(UGCGameSystem.GameState, PlayerKey):Copy()

    ---@type UGCLevelConfigRow
    local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
    local NowLevelConfig = UGCGameData.GetLevelConfig(PlayerState.UGCPlayerLevel)
    local NowExp = PlayerState.PlayerExp
    local TargetExp = NowLevelConfig.Exp
    local ExpRatio = math.min(NowExp / TargetExp, 1)

    ugcprint("UpdatePlayerData: PlayerName = " .. PlayerInfo.PlayerName ..
            ", IconURL = " .. PlayerInfo.IconURL ..
            ", Level = " .. PlayerState.UGCPlayerLevel ..
            ", NowExp = " .. NowExp ..
            ", TargetExp = " .. TargetExp ..
            ", ExpRatio = " .. ExpRatio)

    ---@see UGC_Avator_Item_UIBP_C#OnUpdate
    self.UGC_PlayerMessage:OnUpdate({
        PlayerAccountInfo = PlayerInfo,
        Level = PlayerState.UGCPlayerLevel,
        NowExp = NowExp,
        TargetExp = TargetExp,
        ExpRatio = ExpRatio
    })
end

function UGC_Lobby_Main_UIBP:OnCloseClicked()
    LobbyFlow:Go(LobbyFlowState.LFS_ExitConfirm)
end

function UGC_Lobby_Main_UIBP:OnModeSelectClicked()
    if LobbyModel:IsMatching() then
        UGCWidgetManagerSystem.ShowTipsUI("匹配中无法设置")
        return
    end

    local PC = UGCGameSystem.GetLocalPlayerController()
    if PC and not PC.bIsTeamLeader then
        UGCWidgetManagerSystem.ShowTipsUI("只有队长才能选择模式")
        return
    end

    if PC and not PC.LobbyInfo.bTeamComplete then
        UGCWidgetManagerSystem.ShowTipsUI("队伍有成员退出，请退出玩法重新进入")
        return
    end

    LobbyFlow:Go(LobbyFlowState.LFS_ModeSelect)
end

function UGC_Lobby_Main_UIBP:RefreshMatchButton(bIsLeader)
    self.WidgetSwitcher_Matching:SetActiveWidgetIndex(bIsLeader and 0 or 1)
end

function UGC_Lobby_Main_UIBP:OnMatchClicked()
    local ModeMaxPlayerNum = UGCMultiMode.GetModeSetting(LobbyModel.CurrentSelectedModeID).TeamPlayers
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    local CurPlayerNum = #PlayerController.LobbyTeammatePlayerKeys
    
    if not PlayerController.LobbyInfo.bTeamComplete then
        UGCWidgetManagerSystem.ShowTipsUI("队伍有成员退出，请退出玩法重新进入")
        return
    end

    if CurPlayerNum > ModeMaxPlayerNum then
        UGCWidgetManagerSystem.ShowTipsUI("当前人数大于模式最大人数!")
        return;
    end

    local bLeader = PlayerController.bIsTeamLeader
    if bLeader then
        if not UGCGameSystem.GameState:IsAllLobbyTeammateReady() then
            UGCWidgetManagerSystem.ShowTipsUI("有队友未准备，不能开始匹配!")
            return
        end
    end

    LobbyModel:RequestMatch(not self.FillTeammateCheckBox:IsChecked())
end

function UGC_Lobby_Main_UIBP:OnFillTeammateStateChange(bChecked)
    local PC = UGCGameSystem.GetLocalPlayerController()
    if PC then
        if PC.bIsTeamLeader then
            UnrealNetwork.CallUnrealRPC(PC, PC, "RPC_Server_SetFillTeammate", bChecked)
        elseif LobbyModel.bIsMatching then
            self.FillTeammateCheckBox:SetIsChecked(not bChecked)
        else
            UGCWidgetManagerSystem.ShowTipsUI("只有队长才能勾选是否匹配队友")
            self.FillTeammateCheckBox:SetIsChecked(not bChecked)
        end
    end
end

function UGC_Lobby_Main_UIBP:OnReadyClicked()
    local PlayerController = UGCGameSystem.GetLocalPlayerController()

    -- UGCWidgetManagerSystem.ShowTipsUI("已准备")
    PlayerController:SetLobbyReadyStatus(true)
end

function UGC_Lobby_Main_UIBP:OnCancelReadyClicked()
    local PlayerController = UGCGameSystem.GetLocalPlayerController()

    -- UGCWidgetManagerSystem.ShowTipsUI("已取消准备")
    PlayerController:SetLobbyReadyStatus(false)
end

function UGC_Lobby_Main_UIBP:OnCancelMatchClicked()
    LobbyModel:CancelMatch()
end

function UGC_Lobby_Main_UIBP:OnDifficultySelectClicked()
    if LobbyModel:IsMatching() then
        UGCWidgetManagerSystem.ShowTipsUI("匹配中无法设置")
        return
    end

    local PC = UGCGameSystem.GetLocalPlayerController()
    if PC and not PC.bIsTeamLeader then
        UGCWidgetManagerSystem.ShowTipsUI("只有队长才能选择难度")
        return
    end

    self:ToggleDifficulty()
end

function UGC_Lobby_Main_UIBP:OnShopClicked()
    ShopV2Manager:OpenMainUI()
end

function UGC_Lobby_Main_UIBP:OnWarehouseClicked()
    self:OnWarehouseClicked()
end

function UGC_Lobby_Main_UIBP:OnChangeHeroClicked()
    self:OnHeroClicked()
end

function UGC_Lobby_Main_UIBP:OnTalentTreeClicked()
    LobbyFlow:Go(LobbyFlowState.LFS_TalentTree)
end

function UGC_Lobby_Main_UIBP:OnHeroClicked()
    LobbyFlow:Go(LobbyFlowState.LFS_HeroSelection)
end

function UGC_Lobby_Main_UIBP:OnWarehouseClicked()
    if not BackpackManager.OnMainUIClosed then
        return
    end
    LobbyFlow:Go(LobbyFlowState.LFS_Warehouse)
end

function UGC_Lobby_Main_UIBP:UGC_ReuseList2_Difficulty_OnAfterNewItem(Widget, Idx)
    Idx = Idx + 1

    local ModeID = LobbyModel:GetCurrentSelectedModeID()

    local ModeConfig = LobbyModel:GetModeListWithSameDetailID(ModeID)[Idx]
    local Difficulty = ModeConfig.Difficulty
    local bIsLocked = LobbyModel:IsModeLocked(ModeConfig.ModeID)

    ---@see UGC_Difficulty_Item_UIBP_C#OnUpdate
    Widget:OnUpdate({
        Idx = Idx,
        Difficulty = Difficulty,
        bIsLocked = bIsLocked,
        ModeConfig = ModeConfig,
        bTipsIsLeft = false,
        FocusedMode = ModeID,
        bIsBig = true
    })
end

function UGC_Lobby_Main_UIBP:ToggleDifficulty(bExpand)
    local bIsExpanded = self.CanvasPanel_SelectDifficult:GetVisibility() == ESlateVisibility.Visible

    -- 如果 bExpand 没有定义，则根据当前的展开状态切换
    if bExpand == nil then
        bExpand = not bIsExpanded
    end

    -- 根据 bExpand 的值设置箭头索引和可见性
    self.WidgetSwitcher_Arrow:SetActiveWidgetIndex(bExpand and 1 or 0)
    self.CanvasPanel_SelectDifficult:SetVisibility(bExpand and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

function UGC_Lobby_Main_UIBP:ShowWidgetLayoutData(Widget)
    if not Widget then
        ugcprint("Widget is nil")
        return
    end

    local CanvasPanelSlot = WidgetLayoutLibrary.SlotAsCanvasSlot(Widget)
    if not CanvasPanelSlot then
        ugcprint("CanvasPanelSlot is nil")
        return
    end

    local Anchors = CanvasPanelSlot:GetAnchors()
    local Alignment = CanvasPanelSlot:GetAlignment()
    local Position = CanvasPanelSlot:GetPosition()
    local Size = CanvasPanelSlot:GetSize()
    local LocalSize = SlateBlueprintLibrary.GetLocalSize(Widget:GetCachedGeometry())
    local ScaleX, ScaleY = Widget.RenderTransform.Scale.X, Widget.RenderTransform.Scale.Y
    local TranslationX, TranslationY = Widget.RenderTransform.Translation.X, Widget.RenderTransform.Translation.Y
    local Visibility = Widget:GetVisibility()

    ugcprint(string.format("ShowWidgetLayoutData: %s", Widget))
    ugcprint(string.format("Anchor: %s, %s, %s, %s", Anchors.Minimum.X, Anchors.Minimum.Y, Anchors.Maximum.X, Anchors.Maximum.Y))
    ugcprint(string.format("Alignment: %s, %s", Alignment.X, Alignment.Y))
    ugcprint(string.format("Position: %s, %s", Position.X, Position.Y))
    ugcprint(string.format("Size: %s, %s", Size.X, Size.Y))
    ugcprint(string.format("LocalSize: %s, %s", LocalSize.X, LocalSize.Y))
    ugcprint(string.format("Scale: %s, %s", ScaleX, ScaleY))
    ugcprint(string.format("Translation: %s, %s", TranslationX, TranslationY))
    ugcprint(string.format("Visibility: %s", Visibility))
end

function UGC_Lobby_Main_UIBP:RefreshTeammateStatus(Index, PlayerState)
    if Index == 1 then
        self.TeammateStatus_1:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.TeammateStatus_1:Refresh(PlayerState)
    elseif Index == 2 then
        self.TeammateStatus_2:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.TeammateStatus_2:Refresh(PlayerState)
    elseif Index == 3 then
        self.TeammateStatus_3:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.TeammateStatus_3:Refresh(PlayerState)
    elseif Index == 4 then
        self.TeammateStatus_4:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.TeammateStatus_4:Refresh(PlayerState)
    end
end

function UGC_Lobby_Main_UIBP:HideTeammateStatus(Index)
    if Index == 1 then
        self.TeammateStatus_1:SetVisibility(ESlateVisibility.Collapsed)
    elseif Index == 2 then
        self.TeammateStatus_2:SetVisibility(ESlateVisibility.Collapsed)
    elseif Index == 3 then
        self.TeammateStatus_3:SetVisibility(ESlateVisibility.Collapsed)
    elseif Index == 4 then
        self.TeammateStatus_4:SetVisibility(ESlateVisibility.Collapsed)
    end
end

return UGC_Lobby_Main_UIBP