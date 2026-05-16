---@class UGC_Mode_Item_UIBP_C:UUserWidget
---@field CanvasPanel_Selected UCanvasPanel
---@field ImageEx_GameMode UImage
---@field NewButton_Select UButton
---@field ScrollBox_ModeIntro UScrollBox
---@field TextBlock_ModeIntro UTextBlock
---@field TextBlock_ModeName UTextBlock
--Edit Below--

---@type UGC_Mode_Item_UIBP_C
local UGC_Mode_Item_UIBP = {}


function UGC_Mode_Item_UIBP:Construct()
    self.NewButton_Select.OnClicked:Add(self.OnSelectClicked, self)
end

function UGC_Mode_Item_UIBP:Destruct()
    self.NewButton_Select.OnClicked:Remove(self.OnSelectClicked, self)
end

function UGC_Mode_Item_UIBP:OnUpdate(Data)
    self.Data = Data

    -- 刷新模式信息（标题、图片、描述）
    if self.Data.ModeConfig then
        ---@type FCombinedModeConfig
        local ModeConfig = self.Data.ModeConfig
        self.TextBlock_ModeName:SetText(LobbyUtils.GetTrimmedString(ModeConfig.ModeName, 6))
        self.TextBlock_ModeIntro:SetText(LobbyUtils.GetTrimmedString(ModeConfig.ModeDesc, 12))
        self.ImageEx_GameMode:SetBrushFromTexture(ModeConfig.ModePost)
    end

    -- 刷新模式选中框，默认隐藏
    self.CanvasPanel_Selected:SetVisibility(ESlateVisibility.Collapsed)
    if self.Data.FocusedMode and self.Data.ModeID then
        local FocusedDetailID = LobbyModel:GetModeConfig(self.Data.FocusedMode).DetailID
        local OwningDetailID = LobbyModel:GetModeConfig(self.Data.ModeID).DetailID
        if OwningDetailID == FocusedDetailID then
            self.CanvasPanel_Selected:SetVisibility(ESlateVisibility.Visible)
        end
    end
end

function UGC_Mode_Item_UIBP:OnSelectClicked()
    -- 注意：这里的选择只是高亮选框，并没有真正选择模式

    local ModeMaxPlayerNum = UGCMultiMode.GetModeSetting(self.Data.ModeID).TeamPlayers
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    local CurPlayerNum = #PlayerController.LobbyTeammatePlayerKeys
    if CurPlayerNum > ModeMaxPlayerNum then
        UGCWidgetManagerSystem.ShowTipsUI("当前人数大于模式最大人数!")
        return;
    end

    if self.Data.OnModeFocusedCallback and self.Data.ModeID then
        ---@see UGC_ModeSelection_UIBP_C#OnModeFocused
        local Callback = self.Data.OnModeFocusedCallback
        Callback(self.Data.ModeID)
    else
        ugcprint("[UGC_Mode_Item_UIBP:OnSelectClicked] Callback or ModeID is nil, please check code in function <UGC_Mode_Item_UIBP:OnUpdate>!")
    end
end

return UGC_Mode_Item_UIBP