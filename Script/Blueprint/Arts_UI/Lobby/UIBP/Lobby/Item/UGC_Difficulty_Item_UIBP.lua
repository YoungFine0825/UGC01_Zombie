---@class UGC_Difficulty_Item_UIBP_C:UUserWidget
---@field CanvasPanel_Select UCanvasPanel
---@field Image_Lock UImage
---@field NewButton_Select UButton
---@field NewButton_Tips UButton
---@field SizeBox_difficultyItem USizeBox
---@field TextBlock_Difficulty UTextBlock
---@field WidgetSwitcher_Mode UWidgetSwitcher
--Edit Below--

---@type UGC_Difficulty_Item_UIBP_C
local UGC_Difficulty_Item_UIBP = {}


function UGC_Difficulty_Item_UIBP:Construct()
    self.NewButton_Tips.OnClicked:Add(self.OnTipsClicked, self)
    self.NewButton_Select.OnClicked:Add(self.OnSelectClicked, self)
end

function UGC_Difficulty_Item_UIBP:Destruct()
    self.NewButton_Tips.OnClicked:Remove(self.OnTipsClicked, self)
    self.NewButton_Select.OnClicked:Remove(self.OnSelectClicked, self)
end

function UGC_Difficulty_Item_UIBP:OnUpdate(Data)
    self.Data = Data
    self.Idx = Data.Idx

    if self.Data.Difficulty then
        self.TextBlock_Difficulty:SetText(self.Data.Difficulty)
    end

    -- 更新已选中时候的字体颜色
    if self.Data.Difficulty and self.Data.Difficulty == LobbyModel:GetModeConfig(self.Data.FocusedMode).Difficulty then
        self.TextBlock_Difficulty:SetColorAndOpacity({ SpecifiedColor = { R = 0.040915, G = 0.042311, B = 0.052861, A = 1.0 }, ColorUseRule = 0 })
    else
        if self.Data.bIsLocked then
            self.TextBlock_Difficulty:SetColorAndOpacity({ SpecifiedColor = { R = 1.0, G = 1.0, B = 1.0, A = 0.4 }, ColorUseRule = 0 })
        else
            self.TextBlock_Difficulty:SetColorAndOpacity({ SpecifiedColor = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 }, ColorUseRule = 0 })
        end
    end

    if self.Data.bIsLocked then
        self.Image_Lock:SetVisibility(ESlateVisibility.Visible)
        self.WidgetSwitcher_Mode:SetActiveWidgetIndex(0)
    else
        self.Image_Lock:SetVisibility(ESlateVisibility.Collapsed)
        self.WidgetSwitcher_Mode:SetActiveWidgetIndex(1)
    end

    -- 区分大厅和模式选择的视觉效果
    if self.Data.bIsBig then
        self.SizeBox_difficultyItem:SetWidthOverride(195)
        self.SizeBox_difficultyItem:SetHeightOverride(34)
        self.TextBlock_Difficulty.Font.Size = 11
    else
        self.SizeBox_difficultyItem:SetWidthOverride(165)
        self.SizeBox_difficultyItem:SetHeightOverride(51)
        self.TextBlock_Difficulty.Font.Size = 13
    end

    LobbyUtils.CloseWidget(LobbyWidgetType.LWT_ModeDifficultyTip)
end

function UGC_Difficulty_Item_UIBP:OnTipsClicked()
    ---@see UGC_DifficultyTips_UIBP_C#OnUpdate
    LobbyUtils.OpenAndUpdateWidget(LobbyWidgetType.LWT_ModeDifficultyTip, {
        ModeConfig = self.Data.ModeConfig,
        ParentGeometry = self:GetCachedGeometry(),
        bIsLeft = self.Data.bTipsIsLeft
    })
end

function UGC_Difficulty_Item_UIBP:OnSelectClicked()
    if self.Data.Difficulty then
        if self.Data.OnModeFocusedCallback then
            ---@see UGC_ModeSelection_UIBP_C#OnModeFocused
            local Callback = self.Data.OnModeFocusedCallback
            Callback(self.Data.ModeConfig.ModeID)
        else
            -- 没有回调时，点击难度视作直接选择
            LobbyModel:SelectDifficulty(self.Data.Difficulty)
        end
    end
end

return UGC_Difficulty_Item_UIBP