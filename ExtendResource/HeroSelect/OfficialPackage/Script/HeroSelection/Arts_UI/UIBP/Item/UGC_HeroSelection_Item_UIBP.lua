---@class UGC_HeroSelection_Item_UIBP_C:UUserWidget
---@field DX_Flip UWidgetAnimation
---@field Button_ItemGet_Item UButton
---@field CanvasPanel_Lock UCanvasPanel
---@field CanvasPanel_Mark UCanvasPanel
---@field CanvasPanel_Name UCanvasPanel
---@field Image_2 UImage
---@field Image_CurrentSelect UImage
---@field Image_HeroIcon UImage
---@field Image_Select UImage
---@field TextBlock_ItemGet_Item_GoodsName UTextBlock
---@field TextBlock_Mark UTextBlock
--Edit Below--


---@type UGC_HeroSelection_Item_UIBP_C
local UGC_HeroSelection_Item_UIBP = {}


function UGC_HeroSelection_Item_UIBP:Construct()
    self.Button_ItemGet_Item.OnClicked:Add(self.OnClicked, self)
end

function UGC_HeroSelection_Item_UIBP:Destruct()
    self.Button_ItemGet_Item.OnClicked:Remove(self.OnClicked, self)
end


function UGC_HeroSelection_Item_UIBP:SetData(Data)
    if not Data then return end

    self.HeroID = Data.ID

    -- 英雄名称
    local Name = Data.Name
    local Count = FuncUtil.GetStringLength(Name)
    local Max = 6
    if Count > Max then
        Name = FuncUtil.SubString(Name, 1, Max) .. "..."
    end
    self.TextBlock_ItemGet_Item_GoodsName:SetText(Name or Data.ID or "None")
    -- 英雄图标
    self.Image_HeroIcon:SetBrushFromTexture(Data.Icon, true)
    -- 限免图标
    if Data.bTimeLimitedFree then
        self.CanvasPanel_Mark:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.CanvasPanel_Mark:SetVisibility(ESlateVisibility.Collapsed)
    end
    -- 锁定图标
    if Data.bLocked then
        self.CanvasPanel_Lock:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.CanvasPanel_Lock:SetVisibility(ESlateVisibility.Collapsed)
    end
    -- 选中框
    if Data.bFocused then
        self.Image_Select:SetVisibility(ESlateVisibility.Visible)
    else
        self.Image_Select:SetVisibility(ESlateVisibility.Collapsed)
    end
    -- 选择角标
    if Data.bSelected then
        self.Image_CurrentSelect:SetVisibility(ESlateVisibility.Visible)
    else
        self.Image_CurrentSelect:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UGC_HeroSelection_Item_UIBP:OnClicked()
    if self.HeroID then
        ---@type HeroSelectionViewModel
        local VM = UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionViewModel")
        VM:executeCommand(VM.FocusCommand, self.HeroID)
    end
end

return UGC_HeroSelection_Item_UIBP
