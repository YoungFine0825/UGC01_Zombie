---@class ShopV2_MainUI_UIBP_C:UUserWidget
---@field CloseButton UButton
---@field CountDown UHorizontalBox
---@field CountDownText UTextBlock
---@field CurrencyBar UHorizontalBox
---@field HelpButton UButton
---@field ShopCurrency_1 UShopV2_Currency_UIBP_C
---@field ShopGoods UShopV2_Goods_UIBP_C
---@field ShopTabMenu UUGC_ReuseList2_C
---@field ShopV2_Currency_UIBP_C_0 UShopV2_Currency_UIBP_C
---@field TitleIcon UImage
---@field TitleText UTextBlock
---@field Tabs TArray<FShopV2_TabInfo__pf3369452713>
---@field bShowOasisCoin bool
---@field SelectedTabID int32
---@field PurchasePanelPath FSoftClassPath
---@field ItemGetUIPath FSoftClassPath
---@field PurchaseTipUIPath FSoftClassPath
---@field EntryButtonPath FSoftClassPath
---@field RuleDescPanelPath FSoftClassPath
---@field OasisIconPath FSoftObjectPath
---@field EnableRandomTab bool
---@field RandomTabInfo FShopV2_TabInfo__pf3369452713
---@field RandomTabIndex int32
--Edit Below--
local ShopV2_MainUI_UIBP = 
{ 
    bInitDoOnce = false;
    bCurrencyBarInited = false;
    
    TabInfos = {};
    TabButtons = {};

    NextCheckRefreshTime = 0;
}

function ShopV2_MainUI_UIBP:Construct()

    -- self:InitTabMenu();
    self:InitCurrencyBar();
    self:BindEvent();

    self:PreLoadUI();

    ShopV2Manager:RegisterMainUI(self);
end

function ShopV2_MainUI_UIBP:Destruct()
    
    if self.CheckRefreshTimer ~= nil then
        UGCTimerUtility.RemoveLuaTimer(self.CheckRefreshTimer)
        self.CheckRefreshTimer = nil        
    end

    ShopV2Manager:UnregisterMainUI();
end

function ShopV2_MainUI_UIBP:BindEvent()
    
    self.ShopTabMenu.OnUpdateItem:Add(self.RefreshTabMenuButton, self);
    self.CloseButton.OnClicked:Add(self.OnCloseButtonClick, self);
    self.HelpButton.OnClicked:Add(self.OnHelpButtonClick, self);
end

function ShopV2_MainUI_UIBP:PreLoadUI()
    
    Common.LoadObjectWithSoftPathAsync(self.PurchasePanelPath, 
        function (Object)
            if self ~= nil and Object ~= nil then
                local PlayerController = UGCGameSystem.GetLocalPlayerController();
                self.PurchasePanel = UserWidget.NewWidgetObjectBP(PlayerController, Object);
                if self.PurchasePanel == nil then
                    print("ShopV2_MainUI_UIBP:PreLoadUI PurchasePanel is nil")
                    return
                end
                self.PurchasePanel:AddToViewport(15000);
                self.PurchasePanel:SetVisibility(ESlateVisibility.Collapsed);
            else
                print("ShopV2_MainUI_UIBP:PreLoadUI Load PurchasePanel failed")
            end
        end
    );

    Common.LoadObjectWithSoftPathAsync(self.ItemGetUIPath, 
        function (Object)
            if self ~= nil and Object ~= nil then
                local PlayerController = UGCGameSystem.GetLocalPlayerController();
                self.ItemGetUI = UserWidget.NewWidgetObjectBP(PlayerController, Object);
                if self.ItemGetUI == nil then
                    print("ShopV2_MainUI_UIBP:PreLoadUI ItemGetUI is nil")
                    return
                end
                self.ItemGetUI:AddToViewport(20000);
                self.ItemGetUI:SetVisibility(ESlateVisibility.Collapsed);
            else
                print("ShopV2_MainUI_UIBP:PreLoadUI Load ItemGetUI failed")
            end
        end
    );

    Common.LoadObjectWithSoftPathAsync(self.PurchaseTipUIPath, 
        function (Object)
            if self ~= nil and Object ~= nil then
                local PlayerController = UGCGameSystem.GetLocalPlayerController();
                self.PurchaseTipUI = UserWidget.NewWidgetObjectBP(PlayerController, Object);
                if self.PurchaseTipUI == nil then
                    print("ShopV2_MainUI_UIBP:PreLoadUI PurchaseTipUI is nil")
                    return
                end
                self.PurchaseTipUI:AddToViewport(20000);
                self.PurchaseTipUI:SetVisibility(ESlateVisibility.Collapsed);
            else
                print("ShopV2_MainUI_UIBP:PreLoadUI Load PurchaseTipUI failed")
            end
        end
    );

    Common.LoadObjectWithSoftPathAsync(self.RuleDescPanelPath, 
        function (Object)
            if self ~= nil and Object ~= nil then
                local PlayerController = UGCGameSystem.GetLocalPlayerController();
                self.RuleDescUI = UserWidget.NewWidgetObjectBP(PlayerController, Object);
                if self.RuleDescUI == nil then
                    print("ShopV2_MainUI_UIBP:PreLoadUI RuleDescUI is nil")
                    return
                end
                self.RuleDescUI:AddToViewport(18000);
                self.RuleDescUI:SetVisibility(ESlateVisibility.Collapsed);
            else
                print("ShopV2_MainUI_UIBP:PreLoadUI Load RuleDescUI failed")
            end
        end
    );

    if self.EnableRandomTab == true then
        Common.LoadObjectWithSoftPathAsync(self.EntryButtonPath, 
            function (Object)
                if self ~= nil or Object ~= nil then
                    local PlayerController = UGCGameSystem.GetLocalPlayerController();
                    self.EntryButton = UserWidget.NewWidgetObjectBP(PlayerController, Object);
                    self.EntryButton.RandomTabID = self.RandomTabInfo.TabID;
                    local AnchorData = UGCObjectUtility.NewStruct("AnchorData")
                    AnchorData.Offsets.Left=0
                    AnchorData.Offsets.Top=0
                    AnchorData.Offsets.Right=0
                    AnchorData.Offsets.Bottom=0
                    AnchorData.Anchors.Minimum.X = 0
                    AnchorData.Anchors.Minimum.Y = 0
                    AnchorData.Anchors.Maximum.X = 1
                    AnchorData.Anchors.Maximum.Y = 1
                    UGCWidgetManagerSystem.AddChildToUISlotByWidget(self.EntryButton, "UI.UISlot.MainUISlot_Low", 100, AnchorData);
                    self.EntryButton:SetVisibility(ShopV2Manager:CanShowRandomTabEntry() == true and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed);
                end
            end
        );
    end
end

function ShopV2_MainUI_UIBP:RefreshTabs()
    
    local bHasSelectedTabID = false;
    self.TabInfos = {};

    for i, Tab in ipairs(self.Tabs) do
        local TabInfo = {};
        TabInfo.TabID       = Tab.TabID;
        TabInfo.TabName     = Tab.TabName;
        TabInfo.TabShopName = Tab.TabShopName;
        TabInfo.TabShopDesc = Tab.TabShopDesc;
        table.insert(self.TabInfos, TabInfo);

        if TabInfo.TabID == self.SelectedTabID then
            bHasSelectedTabID = true;
        end
    end

    if self.EnableRandomTab == true and ShopV2Manager:GetCountDownTime() > 0 then
        local TabInfo = {};
        TabInfo.TabID = self.RandomTabInfo.TabID;
        TabInfo.TabName = self.RandomTabInfo.TabName;
        TabInfo.TabShopName = self.RandomTabInfo.TabShopName;
        TabInfo.TabShopDesc = self.RandomTabInfo.TabShopDesc;
        table.insert(self.TabInfos, self.RandomTabIndex+1, TabInfo);

        if TabInfo.TabID == self.SelectedTabID then
            bHasSelectedTabID = true;
        end
    end

    if bHasSelectedTabID == false then
        self.SelectedTabID = self.TabInfos[1].TabID;
    end

    self.ShopTabMenu:Reload(#self.TabInfos);
end

function ShopV2_MainUI_UIBP:InitCurrencyBar()
    
    if self.bShowOasisCoin == true then
        UGCCommoditySystem.ShowRechargeEntryUI():Then(
            function (Result)
                local UI = Result:Get();

                if UI ~= nil then
                    UI:RemoveFromParent();
                    UI:SetVisibility(ESlateVisibility.Visible);
                    self.CurrencyBar:AddChild(UI);
                    self.bCurrencyBarInited = true;
                end
            end
        );
    end    
end

function ShopV2_MainUI_UIBP:ShowPurchasePanel(ProductID)
    
    self.PurchasePanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
    self.PurchasePanel:Refresh(ProductID);
end

function ShopV2_MainUI_UIBP:ShowPurchaseTip(Message)

    self.PurchaseTipUI:SetVisibility(ESlateVisibility.HitTestInvisible);
    self.PurchaseTipUI:ShowMessageTip(Message);
end

function ShopV2_MainUI_UIBP:ShowItemGet(ItemID, Num)

    self.ItemGetUI:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
    self.ItemGetUI:Popup(ItemID, Num);
end

function ShopV2_MainUI_UIBP:SetupShopTabInfo(TabInfo)
   
    self.HelpButton:SetVisibility(TabInfo.TabShopDesc ~= "" and ESlateVisibility.Visible or ESlateVisibility.Collapsed);
    self.RuleDescUI.Desc = TabInfo.TabShopDesc;
    self.TitleText:SetText(TabInfo.TabShopName);
end

function ShopV2_MainUI_UIBP:RefreshTabMenuButton(TabButton, Idx)
    
    TabButton:SetupTabInfo(self.TabInfos[Idx+1]);

    if TabButton.TabID == self.SelectedTabID then
        TabButton:Select();
        self:SetupShopTabInfo(self.TabInfos[Idx+1]);
        self.ShopGoods:RefreshProductList(self.SelectedTabID, false);
    else
        if ShopV2Manager:IsRandomTabID(self.SelectedTabID) == true then
            TabButton:SetVisibility(ESlateVisibility.Collapsed);
        else
            TabButton:Deselect(self.TabInfos[Idx+1].Tab);
        end
    end

    self.TabButtons[TabButton.TabID] = TabButton;
end

function ShopV2_MainUI_UIBP:SelectTab(TabID)
    
    if TabID == self.SelectedTabID then
        return;
    end

    self.TabButtons[TabID]:Select();
    self.TabButtons[self.SelectedTabID]:Deselect();
    self.SelectedTabID = TabID;

    self:SetupShopTabInfo(self.TabButtons[TabID].TabInfo);
    for i = 1, self.CurrencyBar:GetChildrenCount() do
        self.CurrencyBar:GetChildAt(i-1):Refresh();
    end

    self.ShopGoods:RefreshProductList(TabID, false);
    ShopV2Manager:ClearPendingLock();
end

function ShopV2_MainUI_UIBP:SelectProduct(ProductID)

    self.ShopGoods:SelectProduct(ProductID);
end

function ShopV2_MainUI_UIBP:OnCloseButtonClick()

    ShopV2Manager:CloseMainUI();
    self.ShopGoods:CleanTips();
    
    if self.CheckRefreshTimer ~= nil then
        UGCTimerUtility.RemoveLuaTimer(self.CheckRefreshTimer);
        self.CheckRefreshTimer = nil; 
    end

    if ShopV2Manager:GetLockRefreshRule() == ShopV2_LockRefreshRule.CloseShop then
        ShopV2Manager:CancelLocks();
    end
end

function ShopV2_MainUI_UIBP:OnHelpButtonClick()
    
    self.RuleDescUI:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
    self.RuleDescUI:Refresh();
end

function ShopV2_MainUI_UIBP:CheckRefreshTime()
    
    print("[ShopV2_MainUI_UIBP:CheckRefreshTime] Start check time");

    --每小时刷新上下架状态
    local CurrentTime = Common.GetCurrentTime();
    if CurrentTime >= self.NextCheckRefreshTime then
        self.ShopGoods:RefreshCurrentList(true);

        local CurrentDate = Common.GetCurrentDate();
        local NextCheckRefreshTime = os.time({year=CurrentDate.year, month=CurrentDate.month, day=CurrentDate.day, hour=CurrentDate.hour});
        self.NextCheckRefreshTime = NextCheckRefreshTime + 60 * 60 + 1;
    end

    --限时商城倒计时
    if ShopV2Manager:IsSelectingRandomTab() == true then
        local CountDownTime = ShopV2Manager:GetCountDownTime();
        if CountDownTime > 0 then
            self:RefreshCountDown(CountDownTime);
        else
            ---关闭限时商城
            self:RefreshTabs();
        end
    end

    self.CheckRefreshTimer = UGCTimerUtility.CreateLuaTimer(1,
        function ()
            if self ~= nil then
                self:CheckRefreshTime();
            end
        end,
        false
    );
end

function ShopV2_MainUI_UIBP:RefreshCountDown(Time)

    if self.CountDown:GetVisibility() == ESlateVisibility.Collapsed then
        return;
    end

    local Day = math.floor(Time/86400);
    Time = Time % 86400;

    local Hour = math.floor(Time/3600);
    Time = Time % 3600;

    local Min = math.floor(Time/60);
    local Sec = Time % 60;

    local Text = "";
    if Day > 0 then
        Text = string.format("%d天%d小时", Day, Hour);
    elseif Hour > 0 then
        Text = string.format("%d小时%d分钟", Hour, Min);
    else
        Text = string.format("%d分钟%d秒", Min, Sec);
    end

    self.CountDownText:SetText(Text);
end

return ShopV2_MainUI_UIBP;
