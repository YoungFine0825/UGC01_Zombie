---@class UGC_ModeSelection_UIBP_C:UUserWidget
---@field Button_Confirm UButton
---@field Button_DifficultySelect UButton
---@field CanvasPanel_Difficulty UCanvasPanel
---@field CanvasPanel_SelectDifficulty UCanvasPanel
---@field ModeItem UUGC_ReuseList2_C
---@field NewButton_Close UButton
---@field TextBlock_Difficult UTextBlock
---@field UGC_DifficultyTips UUGC_DifficultyTips_UIBP_C
---@field UGC_ReuseList2_Difficulty UUGC_ReuseList2_C
---@field WidgetSwitcher_Arrow UWidgetSwitcher
--Edit Below--

---@type UGC_ModeSelection_UIBP_C
local UGC_ModeSelection_UIBP = {}

function UGC_ModeSelection_UIBP:Construct()
    self.NewButton_Close.OnClicked:Add(self.OnCloseClicked, self)
    self.Button_Confirm.OnClicked:Add(self.OnChooseClicked, self)
    self.Button_DifficultySelect.OnClicked:Add(self.OnDifficultySelectClicked, self)

    self.ModeItem.OnAfterNewItem:Add(self.OnModeItemReload, self)
    self.UGC_ReuseList2_Difficulty.OnAfterNewItem:Add(self.OnDifficultyItemReload, self)
end

function UGC_ModeSelection_UIBP:Destruct()
    self.NewButton_Close.OnClicked:Remove(self.OnCloseClicked, self)
    self.Button_Confirm.OnClicked:Remove(self.OnChooseClicked, self)
    self.Button_DifficultySelect.OnClicked:Remove(self.OnDifficultySelectClicked, self)

    self.ModeItem.OnAfterNewItem:Remove(self.OnModeItemReload, self)
    self.UGC_ReuseList2_Difficulty.OnAfterNewItem:Remove(self.OnDifficultyItemReload, self)
end

function UGC_ModeSelection_UIBP:OnOpen(Data)
    self:ToggleDifficulty(false)
    LobbyUtils.SetOtherWidgetHidden(true)
end

function UGC_ModeSelection_UIBP:OnClose()
    LobbyUtils.SetOtherWidgetHidden(false)
end

function UGC_ModeSelection_UIBP:OnUpdate(Data)
    self.Data = Data

    self:UpdateMode()
    self:UpdateDifficulty()
end

function UGC_ModeSelection_UIBP:UpdateMode()
    if not self.Data.FocusedMode then
        self.Data.FocusedMode = LobbyModel:GetCurrentSelectedModeID()
    end

    ---@see UGC_ModeSelection_UIBP_C#OnModeItemReload
    self.ModeItem:Reload(#LobbyModel:GetAllDisplayModeID())
end

function UGC_ModeSelection_UIBP:UpdateDifficulty()
    if self.Data.Difficulty or LobbyModel:GetCurrentSelectedDifficulty() then
        local Difficulty = self.Data.Difficulty or LobbyModel:GetCurrentSelectedDifficulty()
        self.TextBlock_Difficult:SetText(Difficulty)
        self:ToggleDifficulty(false)
    end

    local ModeID = self.Data.FocusedMode or LobbyModel:GetCurrentSelectedModeID()
    ---@see UGC_ModeSelection_UIBP_C#OnDifficultyItemReload
    self.UGC_ReuseList2_Difficulty:Reload(#LobbyModel:GetModeListWithSameDetailID(ModeID))
end

function UGC_ModeSelection_UIBP:OnCloseClicked()
    LobbyFlow:Go(LobbyFlowState.LFS_Lobby)
end

function UGC_ModeSelection_UIBP:OnChooseClicked()
    if self.Data.FocusedMode then
        if LobbyModel:IsModeLocked(self.Data.FocusedMode) then
            UGCWidgetManagerSystem.ShowTipsUI("该模式已被锁定！")
            return
        else
            local PC = UGCGameSystem.GetLocalPlayerController()

            LobbyModel:SelectMode(self.Data.FocusedMode)
            LobbyFlow:Go(LobbyFlowState.LFS_Lobby)
        end
    else
        UGCWidgetManagerSystem.ShowTipsUI("模式为空！")
        ugcprint("[UGC_ModeSelection_UIBP:OnChooseClicked] FocusedMode is nil!")
    end
end

function UGC_ModeSelection_UIBP:OnModeItemReload(Widget, Idx)
    Idx = Idx + 1

    local ModeID = LobbyModel:GetAllDisplayModeID()[Idx]
    local ModeConfig = LobbyModel:GetModeConfig(ModeID)

    ---@see UGC_Mode_Item_UIBP_C#OnUpdate
    Widget:OnUpdate({
        Idx = Idx,
        ModeID = ModeID,
        ModeConfig = ModeConfig,
        FocusedMode = self.Data.FocusedMode,
        OnModeFocusedCallback = function (NewModeID) self:OnModeFocused(NewModeID) end
    })
end

function UGC_ModeSelection_UIBP:OnDifficultyItemReload(Widget, Idx)
    Idx = Idx + 1

    local ModeID = self.Data.FocusedMode or LobbyModel:GetCurrentSelectedModeID()

    local ModeConfig = LobbyModel:GetModeListWithSameDetailID(ModeID)[Idx]
    local Difficulty = ModeConfig.Difficulty
    local bIsLocked = LobbyModel:IsModeLocked(ModeConfig.ModeID)

    ---@see UGC_Difficulty_Item_UIBP_C#OnUpdate
    Widget:OnUpdate({
        Idx = Idx,
        Difficulty = Difficulty,
        bIsLocked = bIsLocked,
        ModeConfig = ModeConfig,
        bTipsIsLeft = true,
        FocusedMode = ModeID,
        OnModeFocusedCallback = function (NewDifficulty) self:OnModeFocused(NewDifficulty) end
    })
end

function UGC_ModeSelection_UIBP:OnModeFocused(ModeID)
    self:OnUpdate({ FocusedMode = ModeID, Difficulty = LobbyModel:GetModeConfig(ModeID).Difficulty })
end

function UGC_ModeSelection_UIBP:OnDifficultySelectClicked()
    self:ToggleDifficulty()
end

function UGC_ModeSelection_UIBP:ToggleDifficulty(bExpand)
    local bIsExpanded = self.CanvasPanel_SelectDifficulty:GetVisibility() == ESlateVisibility.Visible

    -- 如果 bExpand 没有定义，则根据当前的展开状态切换
    if bExpand == nil then
        bExpand = not bIsExpanded
    end

    -- 根据 bExpand 的值设置箭头索引和可见性
    self.WidgetSwitcher_Arrow:SetActiveWidgetIndex(bExpand and 0 or 1)
    self.CanvasPanel_SelectDifficulty:SetVisibility(bExpand and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

return UGC_ModeSelection_UIBP