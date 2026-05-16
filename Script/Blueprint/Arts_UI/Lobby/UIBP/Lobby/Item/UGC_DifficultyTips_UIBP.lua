---@class UGC_DifficultyTips_UIBP_C:UUserWidget
---@field Button_Close UButton
---@field CanvasPanel_DifficultTips UCanvasPanel
---@field ScrollBox_Conditions UScrollBox
---@field TextBlock_Conditions UTextBlock
---@field TextBlock_Difficult UTextBlock
--Edit Below--

---@type UGC_DifficultyTips_UIBP_C
local UGC_DifficultyTips_UIBP = {}

function UGC_DifficultyTips_UIBP:Construct()
    self.Button_Close.OnClicked:Add(self.OnCloseClicked, self)
end

function UGC_DifficultyTips_UIBP:Destruct()
    self.Button_Close.OnClicked:Remove(self.OnCloseClicked, self)
end

function UGC_DifficultyTips_UIBP:OnUpdate(Data)
    self.Data = Data

    ---@type FCombinedModeConfig
    local ModeConfig = self.Data.ModeConfig

    if self.Data.ModeConfig then
        self.TextBlock_Difficult:SetText(ModeConfig.ModeName)
        self.TextBlock_Conditions:SetText(ModeConfig.UnlockDesc)
    end

    self:UpdatePosition()
end

function UGC_DifficultyTips_UIBP:UpdatePosition()
    if not self.Data.ParentGeometry then
        ugcprint("[UGC_DifficultyTips_UIBP] ParentGeometry is nil, try update position failed")
        return
    end

    local Pos = { X = 0.0, Y = 0.0 }
    local ParentPos = { X = 0.0, Y = 0.0 }
    local MinPadding = 8
    local ParentGeometry = self.Data.ParentGeometry
    local ViewportGeometry = WidgetLayoutLibrary.GetViewportWidgetGeometry(self)
    local ParentSize = SlateBlueprintLibrary.GetLocalSize(ParentGeometry)
    local TipSize = { X = 227.0, Y = 101.0 }
    local ViewportSize = SlateBlueprintLibrary.GetLocalSize(ViewportGeometry)
    local ViewportScale = UGCWidgetManagerSystem.GetViewportScale(self)

    ParentPos.X = UGCWidgetManagerSystem.GetAbsolutePosition(ParentGeometry).X
    ParentPos.Y = UGCWidgetManagerSystem.GetAbsolutePosition(ParentGeometry).Y
    Pos.X = UGCWidgetManagerSystem.AbsoluteToLocal(ViewportGeometry, ParentPos).X
    Pos.Y = UGCWidgetManagerSystem.AbsoluteToLocal(ViewportGeometry, ParentPos).Y

    if self.Data.bIsLeft then
        -- 显示在左侧
        Pos.X = Pos.X - (TipSize.X * ViewportScale) - MinPadding
    else
        -- 显示在右侧
        Pos.X = Pos.X + (ParentSize.X * ViewportScale) + MinPadding
    end

    self.CanvasPanel_DifficultTips.Slot:SetPosition(Pos)
end

function UGC_DifficultyTips_UIBP:OnCloseClicked()
    LobbyUtils.CloseWidget(LobbyWidgetType.LWT_ModeDifficultyTip)
end

return UGC_DifficultyTips_UIBP