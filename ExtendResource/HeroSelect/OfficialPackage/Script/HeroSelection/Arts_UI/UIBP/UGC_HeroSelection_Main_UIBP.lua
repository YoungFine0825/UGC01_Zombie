---@class UGC_HeroSelection_Main_UIBP_C:UUserWidget
---@field Button_Buy UButton
---@field Button_Close UButton
---@field Button_Select UButton
---@field Button_Wardrobe_Skin UButton
---@field Button_Wardrobe_Tianfu UButton
---@field BuyPopupWidget UGC_HeroSelection_Buy_Popups_UIBP_C
---@field CanvasPanel_OriginalPrice UCanvasPanel
---@field CanvasPanel_Root UCanvasPanel
---@field CanvasPanel_Skill UCanvasPanel
---@field CurrencyTipsPopupWidget UGC_HeroSelection_CurrencyTips_Popups_UIBP_C
---@field HeroSelection_Currency01 UGC_HeroSelection_CurrencyItem_UIBP_C
---@field HeroSelection_Currency02 UGC_HeroSelection_CurrencyItem_UIBP_C
---@field HeroSelection_Currency03 UGC_HeroSelection_CurrencyItem_UIBP_C
---@field Image_currency01 UImage
---@field Image_Supply_QualityBg UImage
---@field ItemExplainBox UVerticalBox
---@field ScaleBox_IPX UScaleBox
---@field ScrollBox_SelectExplain UScrollBox
---@field Text_CurrentPrice UTextBlock
---@field Text_OriginalPrice UTextBlock
---@field TextBlock_LockTips UTextBlock
---@field TextBlock_Supply_ItemName UTextBlock
---@field TextBlock_Supply_SelectExplain UTextBlock
---@field UGC_HeroSelection_List UGC_ReuseList2_C
---@field UGC_ReuseList2_Skill UGC_ReuseList2_C
---@field VerticalBox_LeftTop UVerticalBox
---@field WidgetSwitcher_ButStyle UWidgetSwitcher
---@field WidgetSwitcher_Select UWidgetSwitcher
--Edit Below--


---@type UGC_HeroSelection_Main_UIBP_C
local UGC_HeroSelection_Main_UIBP = {}


UGC_HeroSelection_Main_UIBP.bInitDoOnce = false
UGC_HeroSelection_Main_UIBP.Data = {}
---@type HeroSelectionViewModel
UGC_HeroSelection_Main_UIBP.VM = nil



function UGC_HeroSelection_Main_UIBP:Construct()
    print("[HeroSelection] UGC_HeroSelection_Main_UIBP:Construct()")
	self:LuaInit()
    self:InitViewModel()

    -- 适配异形屏
    UICommonFunctionLibrary.SetAdaptation(self.CanvasPanel_Root, self.CanvasPanel_Root)
end

function UGC_HeroSelection_Main_UIBP:Destruct()
    print("[HeroSelection] UGC_HeroSelection_Main_UIBP:Destruct()")
end

-- [Editor Generated Lua] function define Begin:
function UGC_HeroSelection_Main_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
    self.Button_Close.OnClicked:Add(self.Button_Close_OnClicked, self);
    self.Button_Select.OnClicked:Add(self.Button_Select_OnClicked, self);
    self.Button_Buy.OnClicked:Add(self.Button_Buy_OnClicked, self);
    self.UGC_HeroSelection_List.OnAfterNewItem:Add(self.UGC_HeroSelection_List_OnAfterNewItem, self);
    self.UGC_ReuseList2_Skill.OnAfterNewItem:Add(self.UGC_ReuseList2_Skill_OnAfterNewItem, self);
	-- [Editor Generated Lua] BindingEvent End;
end

function UGC_HeroSelection_Main_UIBP:Button_Close_OnClicked()
    HeroSelectionManager:CloseMainWidget()
end

function UGC_HeroSelection_Main_UIBP:Button_Select_OnClicked()
    if LobbyModel ~= nil and LobbyModel.bIsMatching == true then
        UGCWidgetManagerSystem.ShowTipsUI("当前正在匹配，无法选择英雄")
        return
    end

    -- 直接选择当前已选中的英雄
    local FocusedHeroID = HeroSelectionManager:GetCurrentFocusedHeroID()
    HeroSelectionManager:RequestSelectHero(FocusedHeroID)
end

function UGC_HeroSelection_Main_UIBP:InitViewModel()
    self.VM = UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionViewModel")

    self.VM:Init()
    self.VM:bind(self, self.VM.bIsMainUIOpened, function(Widget, Value)
        if Value then
            UGCWidgetManagerSystem.ShowWidget(Widget)
        else
            UGCWidgetManagerSystem.HideWidget(Widget)
        end
    end)
    self.VM:bind(self, self.VM.bCanSelect, function(Widget, Value)
        if Value then
            Widget.WidgetSwitcher_Select:SetActiveWidgetIndex(0)
            Widget.Button_Select:SetIsEnabled(true)
        else
            Widget.WidgetSwitcher_Select:SetActiveWidgetIndex(1)
            Widget.Button_Select:SetIsEnabled(false)
        end
    end)
    self.VM:bind(self.Button_Select, self.VM.bShowSelectButton, function(Widget, Value)
        Widget:SetVisibility(Value and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    end)
    self.VM:bind(self.Button_Buy, self.VM.bShowBuyButton, function(Widget, Value)
        Widget:SetVisibility(Value and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    end)
    self.VM:bind(self, self.VM.HeroPurchaseInfo, function(Widget, PurchaseInfo)
        Widget.Image_currency01:SetBrushFromTexture(PurchaseInfo.CoinIcon)
        Widget.Text_CurrentPrice:SetText(tostring(PurchaseInfo.CoinNumber_Discount or -1))
        Widget.Text_OriginalPrice:SetText(tostring(PurchaseInfo.CoinNumber or -1))
        if PurchaseInfo.CoinNumber > PurchaseInfo.CoinNumber_Discount then
            Widget.CanvasPanel_OriginalPrice:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else
            Widget.CanvasPanel_OriginalPrice:SetVisibility(ESlateVisibility.Collapsed)
        end
    end)
    self.VM:bind(self, self.VM.FocusedHeroID, function(Widget, HeroID)
        if HeroID and HeroID ~= -1 then
            ---@see UGC_HeroSelection_Main_UIBP_C#OnHeroFocused
            Widget:OnHeroFocused(HeroID)
        end
    end)
    self.VM:bind(self, self.VM.HeroSelectionItemDataList, function(Widget, DisplayedHeroDataList)
        Widget.UGC_HeroSelection_List:Reload(#DisplayedHeroDataList)
    end)
    self.VM:bind(self.BuyPopupWidget, self.VM.bBuyPopupOpened, function(Widget, Value)
        if Value then
            UGCWidgetManagerSystem.ShowWidget(Widget)
            ---@see UGC_HeroSelection_Buy_Popups_UIBP_C#SetData
            Widget:SetData({
                HeroData = HeroSelectionManager:GetUGCHeroData(self.VM.FocusedHeroID:get()),
                HeroUIData = HeroSelectionManager:GetUGCHeroUIData(self.VM.FocusedHeroID:get()),
                HeroPurchaseInfo = HeroSelectionManager:GetHeroPurchaseInfo(self.VM.FocusedHeroID:get())
            })
        else
            Widget:Reset()
            UGCWidgetManagerSystem.HideWidget(Widget)
        end
    end)
    self.VM:bind(self.CurrencyTipsPopupWidget, self.VM.bCurrencyTipsPopupOpened, function(Widget, Value)
        if Value then
            UGCWidgetManagerSystem.ShowWidget(Widget)
        else
            UGCWidgetManagerSystem.HideWidget(Widget)
        end
    end)
end

function UGC_HeroSelection_Main_UIBP:Button_Buy_OnClicked()
    if LobbyModel ~= nil and LobbyModel.bIsMatching == true then
        UGCWidgetManagerSystem.ShowTipsUI("当前正在匹配，无法购买英雄")
        return
    end

    self.VM:executeCommand(self.VM.BuyHeroCommand)
end

function UGC_HeroSelection_Main_UIBP:UGC_HeroSelection_List_OnAfterNewItem(Widget, Idx)
    ---@see UGC_HeroSelection_Item_UIBP_C#SetData
    Widget:SetData(self.VM.HeroSelectionItemDataList:get()[Idx + 1])
end

function UGC_HeroSelection_Main_UIBP:UGC_ReuseList2_Skill_OnAfterNewItem(Widget, Idx)
    Idx = Idx + 1

    ---@see UGC_HeroSelection_SkillItem_UIBP_C#SetData
    Widget:SetData({
        HeroAbilityData = self.CachedHeroAbilityLabelData[Idx],
        HeroUIData = self.CachedHeroUIData,
        Idx = Idx
    })
end

-- [Editor Generated Lua] function define End;

---选中某个英雄时，刷新当前选中英雄的能力列表
function UGC_HeroSelection_Main_UIBP:OnHeroFocused(HeroID)
    print("[HeroSelection] UGC_HeroSelection_Main_UIBP:OnHeroFocused(" .. tostring(HeroID) .. ")")
    self.VM:executeCommand(self.VM.ReloadHeroListCommand)

    -- 【刷新名称和描述】
    local HeroData = HeroSelectionManager:GetUGCHeroData(HeroID)
    if HeroData then
        local Name = HeroData.Name
        local Count = FuncUtil.GetStringLength(Name)
        local Max = 6
        if Count > Max then
            Name = FuncUtil.SubString(Name, 1, Max) .. "..."
        end
        self.TextBlock_Supply_ItemName:SetText(Name)
        self.TextBlock_Supply_SelectExplain:SetText(HeroData.Desc)
    end

    -- 【刷新技能列表】
    -- OnHeroFocused 回调没运行完时 Manager 中的 FocusedHeroID 缓存还没更新，因此必须缓存这份数据用于刷新
    local NumNeedsToRefresh = HeroSelectionManager:GetUGCHeroAbilityLabelDataSize(HeroID)
    self.CachedHeroAbilityLabelData = HeroSelectionManager:GetUGCHeroAbilityLabelData(HeroID)
    self.CachedHeroUIData = HeroSelectionManager:GetUGCHeroUIData(HeroID)
    self.UGC_ReuseList2_Skill:Reload(NumNeedsToRefresh)
end

return UGC_HeroSelection_Main_UIBP
