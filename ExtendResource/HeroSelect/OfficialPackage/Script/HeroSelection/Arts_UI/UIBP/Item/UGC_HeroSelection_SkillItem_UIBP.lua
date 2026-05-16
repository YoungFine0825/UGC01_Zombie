---@class UGC_HeroSelection_SkillItem_UIBP_C:UUserWidget
---@field Button_SKill UButton
---@field Image_SkillBg UImage
---@field Image_SkillIcon UImage
---@field Text_SkillName UTextBlock
---@field Text_SkillName_Tag UTextBlock
---@field WidgetSwitcher UWidgetSwitcher
---@field TipsWidgetClass UClass
--Edit Below--


---@type UGC_HeroSelection_SkillItem_UIBP_C
local UGC_HeroSelection_SkillItem_UIBP = {
    bInitDoOnce = false,
    Data = {},
    Idx = 0,
    TipsWidget = nil,
    bIsTipsShowing = false
}


function UGC_HeroSelection_SkillItem_UIBP:Construct()
    self:LuaInit()
    self:InitUI()

    HeroSelectionManager.OnHeroFocused:Add(self.OnHeroFocused, self)
    self.TipsWidget.OnCloseClicked:Add(self.OnTipCloseClicked, self)
end

function UGC_HeroSelection_SkillItem_UIBP:Destruct()
    HeroSelectionManager.OnHeroFocused:Remove(self.OnHeroFocused, self)
    self.TipsWidget.OnCloseClicked:Remove(self.OnTipCloseClicked, self)

    self.TipsWidget:RemoveFromViewport()
    self.TipsWidget = nil

end

function UGC_HeroSelection_SkillItem_UIBP:InitUI()
    if not self.TipsWidget then
        if self.TipsWidgetClass then
            self.TipsWidget = UserWidget.NewWidgetObjectBP(self, self.TipsWidgetClass)
            self.TipsWidget:AddToViewport()
            self:HideSkillTip(true)
        end
    end
end

function UGC_HeroSelection_SkillItem_UIBP:SetData(Data)
    if Data then
        ---@type HeroAbilityLabel
        self.Data = Data.HeroAbilityData
        ---@type HeroUI
        self.HeroUIData = Data.HeroUIData
        ---@type number
        self.Idx = Data.Idx
    else
        return
    end

    -- 0:Icon  1:Text
    if self.HeroUIData.HeroAbilityLabelIsIcon then
        self.Text_SkillName:SetText(self.Data.Name)
        self.Text_SkillName:SetColorAndOpacity(self.Data.NameColor)
        self.Image_SkillIcon:SetBrushFromTexture(self.Data.Icon)
        self.WidgetSwitcher:SetActiveWidgetIndex(0)
    else
        self.Text_SkillName_Tag:SetText(self.Data.Name)
        self.Text_SkillName_Tag:SetColorAndOpacity(self.Data.NameColor)
        self.Image_SkillBg:SetColorAndOpacity(self.Data.BackgroundColor)
        self.WidgetSwitcher:SetActiveWidgetIndex(1)
    end

    -- 最后处理 Tips 显示
    self.TipsWidget:SetData(self.Data)
    self.TipsWidget:SetParent(self)
end

-- [Editor Generated Lua] function define Begin:
function UGC_HeroSelection_SkillItem_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
	self.Button_SKill.OnClicked:Add(self.Button_SKill_OnClicked, self);
	-- [Editor Generated Lua] BindingEvent End;
end

function UGC_HeroSelection_SkillItem_UIBP:Button_SKill_OnClicked()
    ugcprint('[HeroSelection] UGC_HeroSelection_SkillItem_UIBP:Button_SKill_OnClicked()')
	self:ToggleSkillTip()
end

-- [Editor Generated Lua] function define End;

function UGC_HeroSelection_SkillItem_UIBP:ToggleSkillTip()
    ugcprint('[HeroSelection] UGC_HeroSelection_SkillItem_UIBP:ToggleSkillTips()')
    if self.bIsTipsShowing then
        self:HideSkillTip()
    else
        self:ShowSkillTip()
    end
end

function UGC_HeroSelection_SkillItem_UIBP:ShowSkillTip()
    ugcprint('[HeroSelection] UGC_HeroSelection_SkillItem_UIBP:ShowSkillTips()')
    if self.bIsTipsShowing then
        return
    end

    --UGCTimerUtility.CreateLuaTimer(-1, function()
    --    self.TipsWidget:SetPosition()
    --end);

    self.TipsWidget:SetPosition()
    self.TipsWidget:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.bIsTipsShowing = true
end

function UGC_HeroSelection_SkillItem_UIBP:HideSkillTip(bForce)
    ugcprint('[HeroSelection] UGC_HeroSelection_SkillItem_UIBP:HideSkillTips()')
    if not self.bIsTipsShowing and not bForce then
        return
    end

    if self.TipsWidget then
        self.TipsWidget:SetVisibility(ESlateVisibility.Collapsed)
        self.bIsTipsShowing = false
    end
end

function UGC_HeroSelection_SkillItem_UIBP:OnHeroFocused(HeroID)
    if HeroID ~= self.Data.HeroID then
        self:HideSkillTip()
    end
end

function UGC_HeroSelection_SkillItem_UIBP:OnTipCloseClicked()
    self:HideSkillTip(true)
end

return UGC_HeroSelection_SkillItem_UIBP
