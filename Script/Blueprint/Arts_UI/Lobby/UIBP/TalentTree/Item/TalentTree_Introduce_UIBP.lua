---@class TalentTree_Introduce_UIBP_C:UUserWidget
---@field Button_Cancel UButton
---@field Button_Cancel_Hui UButton
---@field Button_Close UButton
---@field Button_Confirm UButton
---@field Button_Plus UButton
---@field Button_Queren_hui UButton
---@field Button_Reduce UButton
---@field CanvasPanel_Btn UCanvasPanel
---@field CanvasPanel_Interaction UCanvasPanel
---@field CanvasPanel_Upgrade UCanvasPanel
---@field Image_TalentIcon UImage
---@field Text_Talentintroduce UTextBlock
---@field TextBlock_FullNumber UTextBlock
---@field TextBlock_Name UTextBlock
---@field TextBlock_TalentName UTextBlock
---@field TextBlock_UpgradeNumber UTextBlock
---@field WidgetSwitcher_Cancel UWidgetSwitcher
---@field WidgetSwitcher_PlusState UWidgetSwitcher
---@field WidgetSwitcher_Queren UWidgetSwitcher
---@field WidgetSwitcher_ReduceState UWidgetSwitcher
--Edit Below--
local TalentTree_Introduce_UIBP = {
    bInitDoOnce = false,
    IsLocked = false,               -- 初始化锁状态
    PlusButtonStatus = 0,           -- 0=enabled, 1=disabled
    ReduceButtonStatus = 0,         -- 0=enabled, 1=disabled
}

function TalentTree_Introduce_UIBP:Construct()
	self.Button_Close.OnClicked:Add(self.Button_Close_OnClicked, self)
    self.Button_Plus.OnClicked:Add(self.Button_Plus_OnClicked, self)
    self.Button_Reduce.OnClicked:Add(self.Button_Reduce_OnClicked, self)
    self.Button_Cancel.OnClicked:Add(self.Button_Cancel_OnClicked, self)
    self.Button_Confirm.OnClicked:Add(self.Button_Confirm_OnClicked, self)

    Common.LoadObjectAsync(UGCGameSystem.GetUGCResourcesFullPath('Asset/WwiseEvent/UGCEditor_Add.UGCEditor_Add'),
        function (Object)
            if Object ~= nil and self ~= nil then
                self.AddSound = Object
            end
        end
    )

    Common.LoadObjectAsync(UGCGameSystem.GetUGCResourcesFullPath('Asset/WwiseEvent/UGCEditor_Minus.UGCEditor_Minus'),
        function (Object)
            if Object ~= nil and self ~= nil then
                self.MinusSound = Object
            end
        end
    )

    Common.LoadObjectAsync(UGCGameSystem.GetUGCResourcesFullPath('Asset/WwiseEvent/UGCEditor_True.UGCEditor_True'),
    function (Object)
        if Object ~= nil and self ~= nil then
            self.ConfirmSound = Object
        end
    end
    )

    TalentTreeManager.OnTalentInfoUpdate:Add(self.OnTalentInfoUpdate, self)
    TalentTreeManager.OnButtonStatesUpdate:Add(self.OnButtonStatesUpdate, self)
end

function TalentTree_Introduce_UIBP:OnUpdate(Data)
    ugcprint("TalentTree_Introduce_UIBP:OnUpdate")
    self.Data = Data

    self.ID = self.Data.ID
    self.TextBlock_TalentName:SetText(self.Data.Name)
    self.Text_TalentIntroduce:SetText(self.Data.Desc)
    self.TextBlock_FullNumber:SetText(self.Data.MaxLevel)

    if not self.Data.Level then
        self.TextBlock_UpgradeNumber:SetText(0)
    else
        self.TextBlock_UpgradeNumber:SetText(self.Data.Level)
    end

    if not self.Data.Icon then
        self.Image_TalentIcon:SetVisibility(ESlateVisibility.Collapsed)
        self.TextBlock_Name:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local name = self.Data.Name
        local maxChars = 4
        local trimmedName = TalentTreeManager:SubUTF8String(name, maxChars)
        self.TextBlock_Name:SetText(trimmedName)
    else
        self.Image_TalentIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.TextBlock_Name:SetVisibility(ESlateVisibility.Collapsed)
        self.Image_TalentIcon:SetBrushFromTexture(self.Data.Icon)
    end

    if self.Data.IsUnlock then
        self.CanvasPanel_Interaction:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.CanvasPanel_Btn:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.CanvasPanel_Interaction:SetVisibility(ESlateVisibility.Collapsed)
        self.CanvasPanel_Btn:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function TalentTree_Introduce_UIBP:Button_Close_OnClicked()
    TalentTreeManager:CancelChanges()
    TalentTreeManager:CloseTalentTip()
    TalentTreeManager:SelectTalent(0)
end

function TalentTree_Introduce_UIBP:Button_Plus_OnClicked()
    if self.WidgetSwitcher_PlusState:GetActiveWidgetIndex() == 1 then
        ugcprint("[TalentTree] Plus button click ignored (disabled state)")
        return
    end

    TalentTreeManager:UpgradeTalent(self.ID)

    if self.AddSound ~= nil then
        UGCSoundManagerSystem.PlaySound2D(self.AddSound)
    end
end

function TalentTree_Introduce_UIBP:Button_Reduce_OnClicked()
    if self.WidgetSwitcher_ReduceState:GetActiveWidgetIndex() == 1 then
        ugcprint("[TalentTree] Reduce button click ignored (disabled state)")
        return
    end

    if self.IsLocked then
        ugcprint("[TalentTree] TalentTree_Introduce_UIBP:Button_Reduce_OnClicked: Operation is locked.")
        UGCWidgetManagerSystem.ShowTipsUI("操作太频繁")
        return
    end

    self.IsLocked = true
    TalentTreeManager:ReduceTalent(self.ID)

    if self.MinusSound ~= nil then
        UGCSoundManagerSystem.PlaySound2D(self.MinusSound) 
    end
end

function TalentTree_Introduce_UIBP:Button_Cancel_OnClicked()
    -- 恢复天赋点，并关闭Tip
    TalentTreeManager:CancelChanges()
    TalentTreeManager:CloseTalentTip()
    TalentTreeManager:SelectTalent(0)
end

function TalentTree_Introduce_UIBP:Button_Confirm_OnClicked()
    TalentTreeManager:ConfirmChanges(self.ID)

    if self.ConfirmSound ~= nil then
        UGCSoundManagerSystem.PlaySound2D(self.ConfirmSound) 
    end
end

function TalentTree_Introduce_UIBP:OnTalentInfoUpdate()
    local Level = TalentTreeManager:GetTalentLevel(self.ID)
    if not Level then
        self.TextBlock_UpgradeNumber:SetText(0)
    else
        self.TextBlock_UpgradeNumber:SetText(Level)
    end

    self.IsLocked = false
end

---@param isPlus boolean @要改变的按钮是否是升级按钮
---@param ButtonStatus number @按钮要变成的状态，0是激活，1是不激活
function TalentTree_Introduce_UIBP:OnButtonStatesUpdate(isPlus, ButtonStatus)
    if isPlus then
        self.PlusButtonStatus = ButtonStatus
        self.WidgetSwitcher_PlusState:SetActiveWidgetIndex(ButtonStatus)
    else
        self.ReduceButtonStatus = ButtonStatus
        self.WidgetSwitcher_ReduceState:SetActiveWidgetIndex(ButtonStatus)
    end
end

return TalentTree_Introduce_UIBP