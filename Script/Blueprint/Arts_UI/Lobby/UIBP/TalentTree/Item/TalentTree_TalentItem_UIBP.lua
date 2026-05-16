---@class TalentTree_TalentItem_UIBP_C:UUserWidget
---@field Border_Color UBorder
---@field Button_Select UButton
---@field CanvasPanel_Lock UCanvasPanel
---@field CanvasPanel_Select UCanvasPanel
---@field Image_TalentIcon UImage
---@field Image_UnlockIcon UImage
---@field TextBlock_Divider UTextBlock
---@field TextBlock_FullNumber UTextBlock
---@field TextBlock_Name UTextBlock
---@field TextBlock_UpgradeNumber UTextBlock
--Edit Below--
local TalentTree_TalentItem_UIBP = { bInitDoOnce = false } 

function TalentTree_TalentItem_UIBP:Construct()
    self.CanvasPanel_Lock:SetVisibility(ESlateVisibility.Collapsed)

    self.Button_Select.OnClicked:Add(self.OnSelectClicked, self)
end

function TalentTree_TalentItem_UIBP:Destruct()
    self.Button_Select.OnClicked:Remove(self.OnSelectClicked, self)
end

function TalentTree_TalentItem_UIBP:SubUTF8String(str, maxChars)
    local currentLength = 0
    local result = ""

    for _, char in utf8.codes(str) do
        if currentLength >= maxChars then
            break
        end
        local utf8Char = utf8.char(char)
        result = result .. utf8Char
        currentLength = currentLength + 1
    end

    return result
end

function TalentTree_TalentItem_UIBP:OnUpdate(Data)
    self.Data = Data
    self.Idx = self.Data.Idx
    self.ID = self.Data.TalentData.ID
    self.IsUnlocked = self.Data.IsUnlocked

    ugcprint(string.format("TalentTree_TalentItem_UIBP:OnUpdate, Idx = %d, TalentID = %d.", self.Idx, self.Data.TalentData.ID))
    if self.IsUnlocked then
        self.CanvasPanel_Lock:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.CanvasPanel_Lock:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end

    if self.Idx == 0 then
        self.Border_Color:SetVisibility(ESlateVisibility.Collapsed)
        self.CanvasPanel_Lock:SetVisibility(ESlateVisibility.Collapsed)
    end

    self.TextBlock_FullNumber:SetText(self.Data.TalentData.MaxLevel)
    self.TextBlock_UpgradeNumber:SetText(self.Data.TalentData.Level)

    if self.Data.TalentData.Level == self.Data.TalentData.MaxLevel then
        self.TextBlock_FullNumber:SetColorRGBStr("006B4B")
        self.TextBlock_UpgradeNumber:SetColorRGBStr("006B4B")
        self.TextBlock_Divider:SetColorRGBStr("006B4B")
    else
        self.TextBlock_FullNumber:SetColorRGBStr("FFFFFF")
        self.TextBlock_UpgradeNumber:SetColorRGBStr("FFFFFF")
        self.TextBlock_Divider:SetColorRGBStr("FFFFFF")
    end

    if self.Data.TalentData.Level > 0 then
        self.Image_TalentIcon:SetColorRGBStr("FCC933")
        self.TextBlock_Name:SetColorRGBStr("FCC933")
    else
        self.Image_TalentIcon:SetColorRGBStr("3D4459")
        self.TextBlock_Name:SetColorRGBStr("3D4459")
    end

    if self.Data.TalentData.isSelected then
        -- self.WidgetSwitcher_State:SetActiveWidgetIndex(2)
        self.CanvasPanel_Select:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        -- self.WidgetSwitcher_State:SetActiveWidgetIndex(1)
        self.CanvasPanel_Select:SetVisibility(ESlateVisibility.Collapsed)
    end

    if not self.Data.TalentData.Icon then
        self.Image_TalentIcon:SetVisibility(ESlateVisibility.Collapsed)
        self.TextBlock_Name:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local name = self.Data.TalentData.Name
        local maxChars = 4
        local trimmedName = self:SubUTF8String(name, maxChars)
        self.TextBlock_Name:SetText(trimmedName)
    else
        self.Image_TalentIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.TextBlock_Name:SetVisibility(ESlateVisibility.Collapsed)
        self.Image_TalentIcon:SetBrushFromTexture(self.Data.TalentData.Icon)
    end
end

function TalentTree_TalentItem_UIBP:OnSelectClicked()
    ugcprint(string.format("TalentTree_TalentItem_UIBP:OnSelectClicked, TalentID = %d.", self.Data.TalentData.ID))
    TalentTreeManager:OpenTalentTip(self.Data.TalentData.ID, self.IsUnlocked)
end

return TalentTree_TalentItem_UIBP