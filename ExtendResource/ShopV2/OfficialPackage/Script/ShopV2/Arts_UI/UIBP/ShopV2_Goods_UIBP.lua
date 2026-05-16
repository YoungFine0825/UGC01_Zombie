---@class ShopV2_Goods_UIBP_C:UUserWidget
---@field EquipmentRoot UCanvasPanel
---@field EquipmentTips UUGC_Equip_Tips_UIBP_C
---@field FreeRefresh UHorizontalBox
---@field FreeRefresh1 UHorizontalBox
---@field LockButton UButton
---@field LockButtonSwitcher UWidgetSwitcher
---@field LockCancelButton UButton
---@field LockConfirmButton UButton
---@field LockConfirmButton1 UButton
---@field LockedNumText UTextBlock
---@field LockedNumText1 UTextBlock
---@field LocknRefreshButtonSwitcher UWidgetSwitcher
---@field LocknRefreshPanel UCanvasPanel
---@field LocknRefreshPanel2 UCanvasPanel
---@field LockSelectModeButton UButton
---@field LockStateSwitcher UWidgetSwitcher
---@field MaxLockNumText UTextBlock
---@field MaxRefreshCountText UTextBlock
---@field MaxRefreshCountText1 UTextBlock
---@field RefreshButton UNewButton
---@field RefreshButton1 UButton
---@field RefreshButtonSwitcher UWidgetSwitcher
---@field RefreshButtonSwitcher1 UWidgetSwitcher
---@field RefreshCurrencyIcon UImage
---@field RefreshCurrencyIcon1 UImage
---@field RefreshDisabledButton UButton
---@field RefreshDisabledButton1 UButton
---@field RefreshDisabledCurrencyIcon UImage
---@field RefreshDisabledCurrencyIcon1 UImage
---@field RefreshDisabledPriceText UTextBlock
---@field RefreshDisabledPriceText1 UTextBlock
---@field RefreshedCountText UTextBlock
---@field RefreshedCountText1 UTextBlock
---@field RefreshFreeButton UButton
---@field RefreshFreeButton1 UButton
---@field RefreshPriceText UTextBlock
---@field RefreshPriceText1 UTextBlock
---@field ReturnButton UButton
---@field SelectedNumText UTextBlock
---@field ShopEmptyInfo UCanvasPanel
---@field ShopEmptyInfoText UTextBlock
---@field ShopItemDetailPanel UShopV2_Goods_Panel_UIBP_C
---@field ShopItemsList UUGC_ReuseList2_C
---@field Stats UDepot_TotalAttributeBut_UIBP_C
--Edit Below--
local ShopV2_Goods_UIBP = 
{ 
    bInitDoOnce = false;
    TabID = 0;
    CurrentProducts = {};
    LimitProducts = {};
    LastSelectedProductID = 0;
    SelectedProductID = 0;

    ProductIDsInTab = nil;
    LockIDs = nil;
}; 

function ShopV2_Goods_UIBP:Construct()
	
    self.ShopItemsList.OnUpdateItem:Add(self.OnUpdateItem, self);

    local PriceButton = self.ShopItemDetailPanel.BuyButton.PriceButton;
    local FreeButton  = self.ShopItemDetailPanel.BuyButton.FreeButton;
    local SoldOutButton = self.ShopItemDetailPanel.BuyButton.SoldOutButton;
    PriceButton.OnClicked:Add(self.ShopItemDetailPanel.BuyButton.OnClick, self.ShopItemDetailPanel.BuyButton);
    FreeButton.OnClicked:Add(self.ShopItemDetailPanel.BuyButton.OnClick, self.ShopItemDetailPanel.BuyButton);
    SoldOutButton.OnClicked:Add(self.ShopItemDetailPanel.BuyButton.OnClick, self.ShopItemDetailPanel.BuyButton);

    self.LockSelectModeButton.OnClicked:Add(self.SwitchToLockSelectMode, self);
    self.LockConfirmButton.OnClicked:Add(self.ConfirmLockProducts, self);
    self.LockCancelButton.OnClicked:Add(self.SwitchToRefreshMode, self);
    self.ReturnButton.OnClicked:Add(self.CleanTips, self);

    self.RefreshButton.OnClicked:Add(self.RefreshRandomProducts, self);
    self.RefreshFreeButton.OnClicked:Add(self.RefreshRandomProducts, self);
    self.RefreshDisabledButton.OnClicked:Add(self.OnRefreshDisableButtonClick, self);

    self.Stats.OpenButton.OnClicked:Add(self.OnStatsButtonClick, self);
end

function ShopV2_Goods_UIBP:Destruct()
    self.CurrentProducts = nil
    self.LimitProducts = nil

    local PriceButton = self.ShopItemDetailPanel.BuyButton.PriceButton;
    local FreeButton  = self.ShopItemDetailPanel.BuyButton.FreeButton;
    local SoldOutButton = self.ShopItemDetailPanel.BuyButton.SoldOutButton;
    PriceButton.OnClicked:Remove(self.ShopItemDetailPanel.BuyButton.OnClick, self.ShopItemDetailPanel.BuyButton);
    FreeButton.OnClicked:Remove(self.ShopItemDetailPanel.BuyButton.OnClick, self.ShopItemDetailPanel.BuyButton);
    SoldOutButton.OnClicked:Remove(self.ShopItemDetailPanel.BuyButton.OnClick, self.ShopItemDetailPanel.BuyButton);

    self.LockSelectModeButton.OnClicked:Remove(self.SwitchToLockSelectMode, self);
    self.LockConfirmButton.OnClicked:Remove(self.ConfirmLockProducts, self);
    self.LockCancelButton.OnClicked:Remove(self.SwitchToRefreshMode, self);
    self.ReturnButton.OnClicked:Remove(self.CleanTips, self);

    self.RefreshButton.OnClicked:Remove(self.RefreshRandomProducts, self);
    self.RefreshFreeButton.OnClicked:Remove(self.RefreshRandomProducts, self);
    self.RefreshDisabledButton.OnClicked:Remove(self.OnRefreshDisableButtonClick, self);

    self.Stats.OpenButton.OnClicked:Remove(self.OnStatsButtonClick, self);

    if UE.IsValid(self.ShopItemsList) then
        self.ShopItemsList:Clear()
    end
end

function ShopV2_Goods_UIBP:RefreshProductList(TabID, bCheckListingTime)
    
    print("[ShopV2_Goods_UIBP:RefreshProductList] Start refresh product list");

    local bRefreshCurrent = self.TabID == TabID;
    self.TabID = TabID;
    self.CurrentProducts = {};
    self.LimitProducts = {};

    if ShopV2Manager:IsRandomTabID(TabID) == true then
        self.LockIDs = ShopV2Manager:GetValidLockIDs();
        self.ProductIDsInTab = ShopV2Manager:GetValidRandomProductIDs();
        self.LocknRefreshPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
        self.LockButtonSwitcher:SetActiveWidgetIndex(ShopV2Manager.bConfirmedLock == true and 0 or 1);
        ShopV2Manager:SetCountDownVisibility(ESlateVisibility.HitTestInvisible);
        self:RefreshLocknRefreshPanel();
    else
        self.ProductIDsInTab = ShopV2Manager:GetProductIDsInTab(TabID, bCheckListingTime);
        ShopV2Manager:SetCountDownVisibility(ESlateVisibility.Collapsed);
        self.LocknRefreshPanel:SetVisibility(ESlateVisibility.Collapsed);
    end
    
    local Num = #self.ProductIDsInTab;
    if Num > 0 then
        self.SelectedProductID = self.ProductIDsInTab[1]; 
    end

    if bRefreshCurrent == true then
        for Idx, ProductID in ipairs(self.ProductIDsInTab) do
            if self.LastSelectedProductID == ProductID then
                self.SelectedProductID = ProductID;
                break;
            end
        end
    end

    self.LastSelectedProductID = self.SelectedProductID;
    self.ShopItemsList:Reload(Num);

    if Num == 0 then
        self.ShopEmptyInfo:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
    else
        self.ShopEmptyInfo:SetVisibility(ESlateVisibility.Collapsed);
    end
end

function ShopV2_Goods_UIBP:RefreshCurrentList(bCheckListingTime)
    
    self:RefreshProductList(self.TabID, bCheckListingTime);
end

function ShopV2_Goods_UIBP:RefreshProductDetailPanel(ProductID)

    if ShopV2Manager:IsSelectingRandomTab() == true then
        self.ShopItemDetailPanel:SetVisibility(ESlateVisibility.Collapsed);
        self.Stats:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
        return;
    end

    self.ShopItemDetailPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
    self.Stats:SetVisibility(ESlateVisibility.Collapsed);
    self.ShopItemDetailPanel:Refresh(ProductID);
end

function ShopV2_Goods_UIBP:RefreshCurrentProductDetailPanel()
    
    self.ShopItemDetailPanel:Refresh(self.SelectedProductID);
end

---@param Item Shop_CommonItem_UIBP_C
---@param Idx number
function ShopV2_Goods_UIBP:OnUpdateItem(Item, Idx)

    local ProductID = self.ProductIDsInTab[Idx+1];

    if ShopV2Manager:IsRandomTabID(self.TabID) == true then
        Item:RandomRefresh(self.LockIDs[Idx+1], ProductID);
    else
        Item:NormalRefresh(ProductID);
    end

    if self.SelectedProductID == ProductID then
        -- Item:Select();

        -- --- 属性对比
        -- if ShopV2Manager:IsSelectingRandomTab() == true then
        --     self:ShowComparison(self.SelectedProductID);
        -- end

        if ShopV2Manager:IsSelectingRandomTab() == false then
            Item:Select();
        end

        self:RefreshProductDetailPanel(self.SelectedProductID);
    else
        Item:Deselect();
    end

    self.CurrentProducts[ProductID] = Item;

    if ShopV2Manager:GetProductData(ProductID).LimitType ~= ELimitType.NotLimited then
        self.LimitProducts[ProductID] = Item;
    end
end

function ShopV2_Goods_UIBP:RefreshLocknRefreshPanel()

    if self.LocknRefreshButtonSwitcher:GetActiveWidgetIndex() == 2 then
        self:SetSelectedNum(ShopV2Manager.PendingLockNum)
        return;
    end

    local MaxLockNum = ShopV2Manager:GetMaxLockNum();
    local LockedNum = ShopV2Manager:GetLockedNum();
    self.LockedNumText:SetText(MaxLockNum > 0 and string.format("%d/%d", LockedNum, MaxLockNum) or string.format("%d", LockedNum));

    local Price = ShopV2Manager:GetRefreshPrice();
    if Price == 0 then
        self.LocknRefreshButtonSwitcher:SetActiveWidgetIndex(0);
        self.FreeRefresh:SetVisibility(ESlateVisibility.HitTestInvisible);

        local MaxFreeRefreshNum = ShopV2Manager:GetMaxRandomRefreshNum();
        self.MaxRefreshCountText:SetText(tostring(MaxFreeRefreshNum));
    
        local FreeRefreshCount = ShopV2Manager:GetFreeRefreshCount();
        FreeRefreshCount = math.min(FreeRefreshCount, MaxFreeRefreshNum);
        self.RefreshedCountText:SetText(tostring(FreeRefreshCount));
    else
        self.LocknRefreshButtonSwitcher:SetActiveWidgetIndex(1);
        self.FreeRefresh:SetVisibility(ESlateVisibility.Collapsed);
    
        local CostID = ShopV2Manager:GetRefreshCostID();
        local ItemData = ShopV2Manager:GetItemData(CostID);
        if ShopV2Manager:GetVirtualItemManager():GetItemNum(CostID) < Price then
            self.RefreshButtonSwitcher:SetActiveWidgetIndex(1);
            self.RefreshDisabledPriceText:SetText(tostring(Price));
            
            Common.LoadObjectAsync(ItemData.ItemIcon, 
                function (IconTexture)
                    if self ~= nil and IconTexture ~= nil then
                        self.RefreshDisabledCurrencyIcon:SetBrushFromTexture(IconTexture);
                    end
                end
            );
        else
            self.RefreshButtonSwitcher:SetActiveWidgetIndex(0);
            self.RefreshPriceText:SetText(tostring(Price));
    
            Common.LoadObjectAsync(ItemData.ItemIcon, 
                function (IconTexture)
                    if self ~= nil and IconTexture ~= nil then
                        self.RefreshCurrencyIcon:SetBrushFromTexture(IconTexture);
                    end
                end
            );
        end
    end
    
    if ShopV2Manager:CheckCanLock(UGCGameSystem.GetLocalPlayerController()) == true then
        self.LockSelectModeButton:SetVisibility(ESlateVisibility.Visible);
    else
        self.LockSelectModeButton:SetVisibility(ESlateVisibility.Collapsed);
    end
end

function ShopV2_Goods_UIBP:SelectProduct(ProductID)
    
    self.CurrentProducts[ProductID]:Select();

    --- 属性对比
    if ShopV2Manager:IsSelectingRandomTab() == true then
        self:ShowComparison(ProductID);
    end

    if ProductID == self.SelectedProductID then
        return;
    end

    if self.CurrentProducts[self.SelectedProductID] then
        self.CurrentProducts[self.SelectedProductID]:Deselect(); 
    end

    self.SelectedProductID = ProductID;
    self.LastSelectedProductID = ProductID;

    self:RefreshProductDetailPanel(ProductID);
end

function ShopV2_Goods_UIBP:SetSelectedNum(Num)

    local MaxLockNum = ShopV2Manager:GetMaxLockNum();
    self.SelectedNumText:SetText(MaxLockNum > 0 and string.format("%d/%d", Num, MaxLockNum) or string.format("%d", Num));
end

function ShopV2_Goods_UIBP:ConfirmLockProducts()
    
    ShopV2Manager:ConfirmLocks();
    self:SwitchToRefreshMode();
end 

function ShopV2_Goods_UIBP:RefreshRandomProducts()
    
    self.SelectedProductID = -1;
    ShopV2Manager:RefreshRandomProduct();
    ShopV2Manager:ClearPendingLock();

    self:CleanTips();
end

function ShopV2_Goods_UIBP:OnRefreshDisableButtonClick()
    
    ShopV2Manager:ShowPurchaseTip("资金不足");
end

function ShopV2_Goods_UIBP:SwitchToLockSelectMode()

    ShopV2Manager:CancelLocks();
    ShopV2Manager.bSelectMode = true;
    self.LockStateSwitcher:SetActiveWidgetIndex(1);
    self.LocknRefreshButtonSwitcher:SetActiveWidgetIndex(2);
    self.FreeRefresh:SetVisibility(ESlateVisibility.Collapsed);
    self:SetSelectedNum(0);
end

function ShopV2_Goods_UIBP:SwitchToRefreshMode()
    
    ShopV2Manager:ClearPendingLock();
    ShopV2Manager.bSelectMode = false;
    self.LockStateSwitcher:SetActiveWidgetIndex(0);
    self.LocknRefreshButtonSwitcher:SetActiveWidgetIndex(0);
    
    self:RefreshCurrentList(false);
    self:RefreshLocknRefreshPanel();
end

function ShopV2_Goods_UIBP:ShowComparison(SelectedProductID)

    self.Stats.StatsPanel:SetVisibility(ESlateVisibility.Collapsed);
    self.EquipmentTips:SetVisibility(ESlateVisibility.SelfHitTestInvisible);

    local VirtualItemID = ShopV2Manager:GetProductData(SelectedProductID).ItemID;
    local ClassicItemID = UGCGamePartSystem.VirtualItemManager.GetGlobalActor():GetClassicItemID(VirtualItemID);

    local EquipDefineID = nil;

    UGCBackpackSystemV2.ClearEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI)

    --ShopV2Manager:ClearEquipSlotSelected();
    local PC = UGCGameSystem.GetLocalPlayerController()
    if PC then
        local EquipSlots = UGCBackpackSystemV2.GetEquipSlots(PC);
        for _, SlotName in pairs(EquipSlots) do
            if UGCBackpackSystemV2.ItemCanEquipToSlot(PC, ClassicItemID, SlotName) then
                EquipDefineID = UGCBackpackSystemV2.GetEquippedItemBySlotName(PC, SlotName);

                UGCBackpackSystemV2.ShowEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI, SlotName)

                --ShopV2Manager:ShowEquipSlotSelected(SlotName);
                break;
            end
        end
    end

    if EquipDefineID ~= nil and EquipDefineID.TypeSpecificID ~= 0 then
        self.EquipmentTips:SetData({{ItemDefineID=EquipDefineID, ItemID=EquipDefineID.TypeSpecificID}}, {{ItemID=ClassicItemID}});
    else
        self.EquipmentTips:SetData({}, {{ItemID=ClassicItemID}});
        UGCBackpackSystemV2.ClearEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI)
        --ShopV2Manager:ClearEquipSlotSelected();
    end
end

function ShopV2_Goods_UIBP:BindEquipmentClickEvent()
    
    local PC = UGCGameSystem.GetLocalPlayerController();
    if PC ~= nil then
        local EquipSlots = UGCBackpackSystemV2.GetEquipSlots(PC);

        local MainWeaponSlot = UGCBackpackSystemV2.GetEquipSlotWidgetBySlotName(ShopV2Manager.MainUI.EquipmentUI, "EquipmentSlot.Core.MainSlot1");
        local SecondaryWeaponSlot = UGCBackpackSystemV2.GetEquipSlotWidgetBySlotName(ShopV2Manager.MainUI.EquipmentUI, "EquipmentSlot.Core.MainSlot2");

        MainWeaponSlot.UGCCommonDragDropItem.OnDragClicked:Add(self.OnMainWeaponClicked, self);
        SecondaryWeaponSlot.UGCCommonDragDropItem.OnDragClicked:Add(self.OnSecondaryWeaponClicked, self);
    end
end

function ShopV2_Goods_UIBP:UnbindEquipmentClickEvent()
    
    local PC = UGCGameSystem.GetLocalPlayerController();
    if PC ~= nil then
        local EquipSlots = UGCBackpackSystemV2.GetEquipSlots(PC);

        local MainWeaponSlot = UGCBackpackSystemV2.GetEquipSlotWidgetBySlotName(ShopV2Manager.MainUI, "EquipmentSlot.Core.MainSlot1");
        local SecondaryWeaponSlot = UGCBackpackSystemV2.GetEquipSlotWidgetBySlotName("EquipmentSlot.Core.MainSlot2");

        if MainWeaponSlot then
            MainWeaponSlot.UGCCommonDragDropItem.OnDragClicked:Remove(self.OnMainWeaponClicked, self);
        end

        if SecondaryWeaponSlot then
            SecondaryWeaponSlot.UGCCommonDragDropItem.OnDragClicked:Remove(self.OnSecondaryWeaponClicked, self);
        end
    end
end

function ShopV2_Goods_UIBP:OnMainWeaponClicked()
    UGCBackpackSystemV2.ClearEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI)
    --ShopV2Manager:ClearEquipSlotSelected();
    self.Stats.StatsPanel:SetVisibility(ESlateVisibility.Collapsed);

    local PC = UGCGameSystem.GetLocalPlayerController()
    local EquipDefineID = UGCBackpackSystemV2.GetEquippedItemBySlotName(PC, "EquipmentSlot.Core.MainSlot1");

    if EquipDefineID ~= nil and EquipDefineID.TypeSpecificID ~= 0 then
        self.EquipmentTips:SetData({{ItemDefineID=EquipDefineID, ItemID=EquipDefineID.TypeSpecificID}}, {});
        self.EquipmentTips:SetVisibility(ESlateVisibility.SelfHitTestInvisible);

        local SlotName = "EquipmentSlot.Core.MainSlot1"
        UGCBackpackSystemV2.ShowEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI, SlotName)
        --ShopV2Manager:ShowEquipSlotSelected("EquipmentSlot.Core.MainSlot1");
        self.CurrentProducts[self.SelectedProductID]:Deselect();
    end
end

function ShopV2_Goods_UIBP:OnSecondaryWeaponClicked()
    UGCBackpackSystemV2.ClearEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI)
    --ShopV2Manager:ClearEquipSlotSelected();
    self.Stats.StatsPanel:SetVisibility(ESlateVisibility.Collapsed);
    
    local PC = UGCGameSystem.GetLocalPlayerController();
    local EquipDefineID = UGCBackpackSystemV2.GetEquippedItemBySlotName(PC, "EquipmentSlot.Core.MainSlot2");

    if EquipDefineID ~= nil and EquipDefineID.TypeSpecificID ~= 0 then
        self.EquipmentTips:SetData({{ItemDefineID=EquipDefineID, ItemID=EquipDefineID.TypeSpecificID}}, {});
        self.EquipmentTips:SetVisibility(ESlateVisibility.SelfHitTestInvisible);

        local SlotName = "EquipmentSlot.Core.MainSlot1"
        UGCBackpackSystemV2.ShowEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI, SlotName)
        --ShopV2Manager:ShowEquipSlotSelected("EquipmentSlot.Core.MainSlot2");
        self.CurrentProducts[self.SelectedProductID]:Deselect();
    end
end

function ShopV2_Goods_UIBP:OnStatsButtonClick()
    
    self.Stats.StatsPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
    self.EquipmentTips:SetVisibility(ESlateVisibility.Collapsed);
    UGCBackpackSystemV2.ClearEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI)
    --ShopV2Manager:ClearEquipSlotSelected();

    self.Stats.StatsPanel:RefreshData();
end

function ShopV2_Goods_UIBP:CleanTips()
    
    if ShopV2Manager:IsSelectingRandomTab() == false then
        return;
    end
    UGCBackpackSystemV2.ClearEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI)
    --ShopV2Manager:ClearEquipSlotSelected();
    self.stats.StatsPanel:SetVisibility(ESlateVisibility.Collapsed);
    self.EquipmentTips:SetVisibility(ESlateVisibility.Collapsed);
    if self.SelectedProductID ~= -1 then
        self.CurrentProducts[self.SelectedProductID]:Deselect();
    end
end

return ShopV2_Goods_UIBP;