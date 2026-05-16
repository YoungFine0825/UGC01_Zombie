UGCGameSystem.UGCRequire("ExtendResource.ShopV2.OfficialPackage." .. "Script.Common.Common");

---@type UKismetMathLibrary
KismetMathLibrary = KismetMathLibrary == nil and nil or KismetMathLibrary

local Delegate = UGCGameSystem.UGCRequire("common.Delegate");

ShopV2Manager = ShopV2Manager or
{
    ShopComponentClass = nil;

    bBlockRepeatPurchase = false;

    LocalComponent = nil;

    ProductIDGroupByTabID = nil;

    VirtualItemManager = nil;
    CommodityOperationManager = nil;

    OnItemNumChangeDelegate = Delegate.New();

    bSelectMode = false;
    bConfirmedLock = false;
    PendingLockList = nil;
    PendingLockNum = 0;

    OrderedLockList = nil;
    RandomRefreshRule = nil;
    ItemQuality = nil;
}

function ShopV2Manager:RegisterComponentClass(CompClass)

    if CompClass ~= nil then
        self.ComponentClass = CompClass;
    end
end

function ShopV2Manager:RegisterMainUI(MainUI)
    
    if self.MainUI == nil then
        self.MainUI = MainUI;
    end
end

function ShopV2Manager:UnregisterMainUI()
    
    self.MainUI = nil;
end

function ShopV2Manager:GetCommodityOperationManager()

    if not UE.IsValid(self.CommodityOperationManager) then
        self.CommodityOperationManager = UGCGamePartSystem.CommodityOperationManager.GetGlobalActor();
    end

    return self.CommodityOperationManager;
end

function ShopV2Manager:GetVirtualItemManager()
    
    if not UE.IsValid(self.VirtualItemManager) then
        self.VirtualItemManager = UGCGamePartSystem.VirtualItemManager.GetGlobalActor();
    end

    return self.VirtualItemManager;
end

function ShopV2Manager:GetProductData(ProductID)
    
    return self:GetCommodityOperationManager():GetProductData(ProductID);
end

function ShopV2Manager:GetItemData(ItemID)
    
    return self:GetVirtualItemManager():GetItemData(ItemID);
end

function ShopV2Manager:GetIsLocked(LockID, PlayerController)
    
    return self:GetShopV2Component(PlayerController):GetIsLocked(LockID);
end

function ShopV2Manager:GetLockedNum(PlayerController)
    
    return self:GetShopV2Component(PlayerController).LockedNum;
end

function ShopV2Manager:GetLimitPurchasedTimes(ProductID, PlayerController)
    
    return self:GetCommodityOperationManager():GetLimitPurchasedTimes(ProductID, PlayerController);
end

function ShopV2Manager:GetCountDownTime(PlayerController)
    
    local EndTime = self:GetShopV2Component(PlayerController).RandomRefreshEndTime;
    local CountDownTime = EndTime - Common.GetCurrentTime();
    CountDownTime = math.max(0, CountDownTime);

    print(string.format("[ShopV2Manager:GetRandomRefreshEndTime] CountDownTime=%d", CountDownTime));

    if self:GetShopV2Component().bActive == false then
        CountDownTime = 0;
    end

    return CountDownTime;
end

function ShopV2Manager:CanShowRandomTabEntry()
    
    local Comp = self:GetShopV2Component();
    if Comp == nil then
        return false;
    end

    return Comp.bActive == true and Common.GetCurrentTime() < Comp.RandomRefreshEndTime;
end

function ShopV2Manager:GetQualityTexturePath(ItemID, bBigSize)
    
    if self.ItemQuality == nil then
        self:GetShopV2Component():ReadItemQualityTable();
    end

    local QualityRank = self.ItemQuality[ItemID];
    if QualityRank == nil or QualityRank < 0 or QualityRank > 6 then
        QualityRank = 0;
    end

    local Path = bBigSize == true and UGCItemSystem.GetBigQualityTexturePath(QualityRank) or UGCItemSystem.GetQualityTexturePath(QualityRank);

    return Path;
end

function ShopV2Manager:GetQualityBarTexturePath(ItemID)

    if self.ItemQuality == nil then
        self:GetShopV2Component():ReadItemQualityTable();
    end

    local QualityRank = self.ItemQuality[ItemID];
    if QualityRank == nil or QualityRank < 0 or QualityRank > 6 then
        QualityRank = 0;
    end

    local Path = UGCItemSystem.GetQualityBarTexturePath(QualityRank);
    return Path;
end

function ShopV2Manager:AddPendingLock(LockID)

    if self.PendingLockList == nil then
        self.PendingLockList = {};
    end

    table.insert(self.PendingLockList, LockID);
    self.PendingLockNum = self.PendingLockNum + 1;
    self.MainUI.ShopGoods:SetSelectedNum(self.PendingLockNum);
end

function ShopV2Manager:RemovePendingLock(LockID)
    
    if self.PendingLockList == nil then
        return;
    end

    for i, ID in ipairs(self.PendingLockList) do
        if ID == LockID then
            table.remove(self.PendingLockList, i);
            self.PendingLockNum = self.PendingLockNum - 1;
            self.MainUI.ShopGoods:SetSelectedNum(self.PendingLockNum);
            return;
        end
    end
end

function ShopV2Manager:ClearPendingLock()
    
    if self.PendingLockList == nil then
        return;
    end

    self.PendingLockList = {};
    self.PendingLockNum = 0;
end

function ShopV2Manager:ConfirmLocks()
    
    self:GetShopV2Component():ConfirmLocks(self.PendingLockList);
    self.PendingLockList = nil;
    self.PendingLockNum = 0;
    self.bConfirmedLock = true;
end

function ShopV2Manager:CancelLocks()
    
    self:GetShopV2Component():ConfirmLocks({});
    self.PendingLockList = nil;
    self.PendingLockNum = 0;
    self.bConfirmedLock = false;
end

function ShopV2Manager:CanAfford(ProductID, Num, PlayerController)
    
    return self:GetCommodityOperationManager():CanAfford(ProductID, Num, PlayerController);
end

--- 获取玩家的 SignInEventComponent
--- 生效范围：客户端&&服务器
---@param PlayerController UGCPlayerController_C @玩家控制器，客户端可以不传入，默认客户端的主控玩家控制器
---@return ShopV2Component_C @商城V2组件
function ShopV2Manager:GetShopV2Component(PlayerController)

    if PlayerController == nil and UGCGameSystem.IsServer() == false then
        if self.LocalComponent == nil then
            if self.ComponentClass ~= nil and UGCGameSystem.GameState ~= nil then
                local PlayerController = UGCGameSystem.GetLocalPlayerController();
                self.LocalComponent = PlayerController:GetComponentByClass(self.ComponentClass);
            else
                print("[ShopV2Manager:GetShopV2Component] Cannot get local component!");
            end
        end
           
        return self.LocalComponent;
    end

    if self.ComponentClass ~= nil then
        return PlayerController:GetComponentByClass(self.ComponentClass);
    else
        print("[ShopV2Manager:GetShopV2Component] ComponentClass is nil!");
        return nil;
    end
end

function ShopV2Manager:OpenMainUI(TabID)
    
    if self.MainUI == nil then
        print("[ShopV2Manager:OpenMainUI] MainUI is nil!");
        return;
    end

    self:GetCommodityOperationManager().LimitProductUpdateDelegate:Add(self.RefreshProducts, self);
    self:GetCommodityOperationManager().BuyProductResultDelegate:Add(self.OnBuyProductResult, self);
    self:GetVirtualItemManager().AddItemResultDelegate:Add(self.OnAddVirtualItem, self);
    -- self:GetVirtualItemManager().OnVirtualItemNumUpdatedDelegate:Add(self.OnVirtualItemNumUpdate, self);
    self:GetVirtualItemManager().OnItemNumUpdatedDelegate:Add(self.OnVirtualItemNumUpdate, self);

    if TabID ~= nil then
        self.MainUI.SelectedTabID = TabID;
        self.MainUI.ShopGoods.TabID = TabID;
    end

    self.MainUI:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
    self.MainUI:RefreshTabs();
    self.MainUI:CheckRefreshTime();

    if self.MainUI.EquipmentUI == nil then
        self.MainUI.EquipmentUI = UGCBackpackSystemV2.CreateEquipmentFullScreenUI(self.MainUI.ShopGoods.EquipmentRoot)
    end

    if self:IsSelectingRandomTab() == true then
        self.MainUI.ShopGoods:BindEquipmentClickEvent();
        self.MainUI.EquipmentUI:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
        self.MainUI.EquipmentUI:Update();
    else
        self.MainUI.EquipmentUI:SetVisibility(ESlateVisibility.Collapsed);
    end
    
    self.OnItemNumChangeDelegate();
end

-- function ShopV2Manager:ClearEquipSlotSelected()
--     print_dev("[ShopV2Manager:ClearEquipSlotSelected] ClearEquipSlotSelected!");
--     if self.MainUI == nil or self.MainUI.EquipmentUI == nil then
--         print_dev("[ShopV2Manager:ClearEquipSlotSelected] MainUI or EquipmentUI is nil!");
--         return;
--     end

--     -- 武器栏
--     local EquipUI = self.MainUI.EquipmentUI.Equip_WepSet_Item_UIBP;
--     if EquipUI then
--         log_tree_dev("[ShopV2Manager:ClearEquipSlotSelected] EquipWidgetMap:", EquipUI.EquipWidgetMap);

--         for _, Widget in pairs(EquipUI.EquipWidgetMap) do
--             if Widget and Widget.HideSelected then
--                 Widget:HideSelected()
--             end
--         end
--     else
--         print_dev("[ShopV2Manager:ClearEquipSlotSelected] EquipUI is nil!");
--     end

--     -- 装备栏
--     local CommonList = self.MainUI.EquipmentUI.ReuseList2_EquipType
--     if CommonList then
--         local EquipWidgets = {}
--         CommonList:GetAllWidgetItems(EquipWidgets)

--         print_dev("[ShopV2Manager:ClearEquipSlotSelected] EquipWidgets:" .. #EquipWidgets);

--         for _, CommonEquipUI in pairs(EquipWidgets) do
--             if CommonEquipUI.HideSelected then
--                 CommonEquipUI:HideSelected()
--             end
--         end
--     else
--         print_dev("[ShopV2Manager:ClearEquipSlotSelected] CommonList is nil!");
--     end
-- end

-- function ShopV2Manager:ShowEquipSlotSelected(SlotName)
--     print_dev("[ShopV2Manager:ShowEquipSlotSelected] SlotName:" .. SlotName);
--     if self.MainUI == nil or self.MainUI.EquipmentUI == nil then
--         print_dev("[ShopV2Manager:ShowEquipSlotSelected] MainUI or EquipmentUI is nil!");
--         return;
--     end

--     -- 武器栏
--     local EquipUI = self.MainUI.EquipmentUI.Equip_WepSet_Item_UIBP;
--     if EquipUI then
--         log_tree_dev("[ShopV2Manager:ShowEquipSlotSelected] EquipWidgetMap:", EquipUI.EquipWidgetMap);

--         local Widget = EquipUI.EquipWidgetMap[SlotName];
--         if Widget and Widget.ShowSelected then
--             Widget:ShowSelected()
--         end
--     else
--         print_dev("[ShopV2Manager:ShowEquipSlotSelected] EquipUI is nil!");
--     end

--     -- 装备栏
--     local CommonList = self.MainUI.EquipmentUI.ReuseList2_EquipType
--     if CommonList then
--         local EquipWidgets = {}
--         CommonList:GetAllWidgetItems(EquipWidgets)

--         print_dev("[ShopV2Manager:ShowEquipSlotSelected] EquipWidgets:" .. #EquipWidgets);

--         for _, CommonEquipUI in pairs(EquipWidgets) do
--             if CommonEquipUI.SlotName == SlotName and CommonEquipUI.ShowSelected then
--                 CommonEquipUI:ShowSelected()
--             end
--         end
--     else
--         print_dev("[ShopV2Manager:ShowEquipSlotSelected] CommonList is nil!");
--     end
-- end

-- function ShopV2Manager:GetEquipSlotWidgetBySlotName(SlotName)
--     print_dev("[ShopV2Manager:GetEquipSlotWidgetBySlotName] SlotName=" .. SlotName);
--     if self.MainUI == nil or self.MainUI.EquipmentUI == nil then
--         print_dev("[ShopV2Manager:GetEquipSlotWidgetBySlotName] MainUI or EquipmentUI is nil!");
--         return;
--     end

--     -- 武器栏
--     local EquipUI = self.MainUI.EquipmentUI.Equip_WepSet_Item_UIBP;
--     if EquipUI then
--         log_tree_dev("[ShopV2Manager:GetEquipSlotWidgetBySlotName] EquipWidgetMap:", EquipUI.EquipWidgetMap);

--         if EquipUI.EquipWidgetMap[SlotName] then
--             return EquipUI.EquipWidgetMap[SlotName]
--         end
--     end

--     print_dev("[ShopV2Manager:GetEquipSlotWidgetBySlotName] EquipUI.EquipWidgetMap Isn't Exist!");

--     -- 通用装备栏
--     local CommonList = self.MainUI.EquipmentUI.ReuseList2_EquipType
--     if CommonList then
--         local EquipWidgets = {}
--         CommonList:GetAllWidgetItems(EquipWidgets)

--         print_dev("[ShopV2Manager:GetEquipSlotWidgetBySlotName] EquipWidgets:" .. #EquipWidgets);

--         for _, CommonEquipUI in pairs(EquipWidgets) do
--             if CommonEquipUI.SlotName == SlotName then
--                 return CommonEquipUI
--             end
--         end
--     else
--         print_dev("[ShopV2Manager:GetEquipSlotWidgetBySlotName] CommonList is nil!");
--     end

--     print_dev("[ShopV2Manager:GetEquipSlotWidgetBySlotName] CommonEquipUI Isn't Exist!");
-- end

-- function ShopV2Manager:GetAllCommonEquippmentWidgets()
--     print_dev("[ShopV2Manager:GetAllCommonEquippmentWidgets]");
--     if self.MainUI == nil or self.MainUI.EquipmentUI == nil then
--         print_dev("[ShopV2Manager:GetAllCommonEquippmentWidgets] MainUI or EquipmentUI is nil!");
--         return;
--     end

--     -- 通用装备栏
--     local CommonList = self.MainUI.EquipmentUI.ReuseList2_EquipType
--     if CommonList then
--         local EquipWidgets = {}
--         CommonList:GetAllWidgetItems(EquipWidgets)

--         print_dev("[ShopV2Manager:GetEquipSlotWidgetBySlotName] EquipWidgets:" .. #EquipWidgets);

--         return EquipWidgets 
--     end
-- end

function ShopV2Manager:CloseMainUI()

    if self.MainUI == nil then
        print("[ShopV2Manager:OpenMainUI] MainUI is nil!");
        return;
    end

    self:GetCommodityOperationManager().LimitProductUpdateDelegate:Remove(self.RefreshProducts, self);
    self:GetCommodityOperationManager().BuyProductResultDelegate:Remove(self.OnBuyProductResult, self);
    self:GetVirtualItemManager().AddItemResultDelegate:Remove(self.OnAddVirtualItem, self);
    self:GetVirtualItemManager().OnItemNumUpdatedDelegate:Remove(self.OnVirtualItemNumUpdate, self);

    if self.MainUI then
        self.MainUI:SetVisibility(ESlateVisibility.Collapsed);
    end
    
    if self.MainUI.PurchasePanel then
        self.MainUI.PurchasePanel:SetVisibility(ESlateVisibility.Collapsed);
    end
    
    if self.MainUI.ShopGoods then
        self.MainUI.ShopGoods:UnbindEquipmentClickEvent();
    end
end

function ShopV2Manager:IsMainUIOpenned()
    
    if self.MainUI == nil then
        return false;
    end

    return self.MainUI:GetVisibility() == ESlateVisibility.SelfHitTestInvisible;
end

function ShopV2Manager:OpenPurchaseUI(ProductID)
    
    self.MainUI:ShowPurchasePanel(ProductID);
end

function ShopV2Manager:SetEntryButtonVisibility(Visibility)
    
    if self.MainUI == nil or self.MainUI.EntryButton == nil then
        return;
    end

    self.MainUI.EntryButton:SetVisibility(Visibility);
    if Visibility ~= ESlateVisibility.Collapsed then
        self.MainUI.EntryButton:CheckTime();
    end
end

function ShopV2Manager:IsSelectingRandomTab()
    
    if self.MainUI == nil or self.MainUI:GetIsVisible() == false then
        return false;
    end

    return self:IsRandomTabID(self.MainUI.SelectedTabID);
end

function ShopV2Manager:IsSelectingTab(TabID)
    
    if self.MainUI == nil or self.MainUI:GetIsVisible() == false then
        return false;
    end

    return self.MainUI.SelectedTabID == TabID;
end

function ShopV2Manager:RefreshProducts()

    if self.MainUI == nil or self.MainUI:GetIsVisible() == false then
        return;
    end

    self.MainUI.ShopGoods:RefreshCurrentList(false);
end

function ShopV2Manager:RefreshProductDetail()
    
    if self.MainUI == nil or self.MainUI:GetIsVisible() == false then
        return;
    end

    self.MainUI.ShopGoods:RefreshCurrentProductDetailPanel();
end

function ShopV2Manager:ResetSelectedProductID()
    
    if self.MainUI == nil or self.MainUI:GetIsVisible() == false then
        return;
    end

    self.MainUI.ShopGoods.LastSelectedProductID = 0;
    self.MainUI.ShopGoods.SelectedProductID = 0;
end

function ShopV2Manager:ShowPurchaseTip(Message)

    if self.MainUI == nil then
        return;
    end

    self.MainUI:ShowPurchaseTip(Message);
end

function ShopV2Manager:ShowItemGetPopup(ItemID, Num)
    
    if self.MainUI == nil then
        return;
    end

    self.MainUI:ShowItemGet(ItemID, Num);
end

function ShopV2Manager:RefreshCountDown(Time)
    
    if self.MainUI == nil then
        return;
    end

    self.MainUI:RefreshCountDown(Time);
end

function ShopV2Manager:GetProductCurrencyIconPath(ProductID)
    
    local ProductData = self:GetCommodityOperationManager():GetProductData(ProductID);

    if ProductData.CurrencyType == ECurrencyType.OasisCoin then
        return UGCObjectUtility.GetPathBySoftObjectPath(self.MainUI.OasisIconPath);
    end

    if ProductData.CurrencyType == ECurrencyType.OtherCoin then
        local VirtualItemManager = UGCBlueprintFunctionLibrary.GetGamePartGlobalActor(UGCGameSystem.GameState, "VirtualItemManager");
        return VirtualItemManager:GetItemData(ProductData.CostID).ItemIcon;
    end

    return nil;
end

function ShopV2Manager:OnVirtualItemNumUpdate()
    
    -- self:RefreshProductDetail();
    self:RefreshProducts();
    self.OnItemNumChangeDelegate();
end

function ShopV2Manager:SelectShopTab(TabID)
    
    self.MainUI:SelectTab(TabID);
end

function ShopV2Manager:SelectProduct(ProductID)

    self.MainUI:SelectProduct(ProductID);
end

function ShopV2Manager:SetCountDownVisibility(Visibility)

    self.MainUI.CountDown:SetVisibility(Visibility);

    if Visibility ~= ESlateVisibility.Collapsed then
        self.MainUI:RefreshCountDown(ShopV2Manager:GetCountDownTime());
    end
end
 
function ShopV2Manager:GetIndexProductID(Index, PlayerController)
    
    local ShopV2Comp = self:GetShopV2Component(PlayerController);
    return ShopV2Comp:GetIndexProductID(Index+1);
end

--- 获取到截止日期的剩余天数
--- 生效范围：服务器&&客户端
---@param EndTime int
---@return int
function ShopV2Manager:GetRemainingDays(EndTime)
    
    local RemainingSec = EndTime - UGCGameSystem.GetServerTimeSec();

    return RemainingSec > 0 and math.floor(RemainingSec/3600/24) or 0; 
end

function ShopV2Manager:GetDiscountPrice(ProductID)
    
    return UGCCommoditySystem.GetSellingPriceAfterDiscount(ProductID);
end

--- 检查商品的是否能够上架
--- 生效范围：服务器&&客户端
---@param ProductID int
---@return bool
function ShopV2Manager:IsProductValid(ProductID)

    local ProductData = self:GetCommodityOperationManager():GetProductData(ProductID);
    
    if ProductData == nil then
        return false;
    end

    if ProductData.AvailableForSale == EAvailableForSale.NotForSale then
        return false;
    end

    if ProductData.StoreID == EStoreId.Lobby then
        return false;
    end

    local CurrentTime = UGCGameSystem.GetServerTimeSec();
    local ListingTime = ProductData.ListingTime;
    
    return CurrentTime >= ListingTime;
end

function ShopV2Manager:IsPermanentDiscount(EndTime)
    
    local Date = os.date("*t", EndTime);

    return Date.year >= 3000;
end

---发起购买非绿洲币商品
---生效范围：客户端
---@param ProductID int
---@param Num int 购买商品数量
---@param CurrentPrice int 商品价格
function ShopV2Manager:BuyProduct(ProductID, Num, CurrentPrice)

    self:GetCommodityOperationManager():BuyProduct(ProductID, CurrentPrice, Num);
end

function ShopV2Manager:RefreshRandomProduct()
    
    self:GetShopV2Component():RefreshRandomProducts();
end

---获取对应页签的所有商品ID
---@param TabID int @页签ID
---@param bRefresh bool @是否刷新全部商品（会添加满足上架条件的商品）
---@return Array @排序后同一页签下的商品ID数组
function ShopV2Manager:GetProductIDsInTab(TabID, bRefresh)

    if self.ProductIDGroupByTabID == nil or bRefresh == true then
        print("[ShopV2Manager:GetProductIDsInTab] Group ProductID by TabID");
        self:GroupProductIDByTabID();
    end

    if self.ProductIDGroupByTabID[tostring(TabID)] == nil then
        print("[ShopV2Manager:GetProductIDsInTab] No products in TabID");
        return {};
    end

    return self.ProductIDGroupByTabID[tostring(TabID)];
end

function ShopV2Manager:GroupProductIDByTabID()

    print("[ShopV2Manager:GroupProductIDByTabID] Start group ProductID by TabID");

    local ProductDatas = self:GetCommodityOperationManager():GetAllProductData();
    self.ProductIDGroupByTabID = {};

    for ProductID, ProductData in pairs(ProductDatas) do
       --- 按照 TabID 分组
        local TabID = tostring(ProductData.TabID);
        self.ProductIDGroupByTabID[TabID] = self.ProductIDGroupByTabID[TabID] or {};
        --- 只添加有效的商品到分组
        if self:IsProductValid(ProductData.ProductID) == true then
            table.insert(self.ProductIDGroupByTabID[TabID], ProductID);
        end 
    end

    local function Compare(ProductIDA, ProductIDB)
    
        local ProductDataA = ShopV2Manager:GetCommodityOperationManager():GetProductData(ProductIDA);
        local ProductDataB = ShopV2Manager:GetCommodityOperationManager():GetProductData(ProductIDB);
    
        if ProductDataA.SortPriority ~= ProductDataB.SortPriority then
            return ProductDataA.SortPriority < ProductDataB.SortPriority;
        end
        
        -- 优先级一样按照 ID 排序
        return ProductDataA.ProductID < ProductDataB.ProductID;
    end

    --- 商品排序，优先级越小的越靠前
    for _, Tab in pairs(self.ProductIDGroupByTabID) do
        table.sort(Tab, Compare);
    end

    return self.ProductIDGroupByTabID;
end

function ShopV2Manager:OnAddVirtualItem(Result)

    if Result.bSucceeded == false then
        return;
    end

    for ItemID, Num in pairs(Result.ItemList) do
        self:ShowItemGetPopup(ItemID, Num);
        return;
    end
end

function ShopV2Manager:OnBuyProductResult(Result)
    
    self.bBlockRepeatPurchase = false;
end

---生效范围：客户端&服务器
---@param PlayerController UUGCPlayerController @玩家控制器，客户端可以不传入，默认客户端的主控玩家控制器
---@param DropGroupID int @随机商品的DropGroupID
function ShopV2Manager:ActivateRandomRefreshTab(PlayerController, DropGroupID)
    
    if UGCGameSystem.GameState:HasAuthority() == true then
        self:GetShopV2Component(PlayerController):Server_ActivateRandomRefresh(DropGroupID);
    else
        self:GetShopV2Component(PlayerController):ActivateRandomRefresh(DropGroupID);
    end
end

---生效范围：客户端&服务器
---@param PlayerController UUGCPlayerController @玩家控制器，客户端可以不传入，默认客户端的主控玩家控制器
function ShopV2Manager:DeactivateRandomRefreshTab(PlayerController)
    
    if UGCGameSystem.GameState:HasAuthority() == true then
        self:GetShopV2Component(PlayerController):Server_DeactivateRandomRefresh();
    else
        self:GetShopV2Component(PlayerController):DeactivateRandomRefresh();
    end
end

function ShopV2Manager:UpdateRandomRefreshTab()
    
    if self.MainUI == nil 
    or self.MainUI:GetVisibility() == ESlateVisibility.Collapsed 
    or self.MainUI.EnableRandomTab == false then
        return;
    end

    self.MainUI:RefreshTabs();
end

function ShopV2Manager:IsRandomTabID(TabID)

    if self.MainUI == nil or self.MainUI.EnableRandomTab == false then
        return false;
    end
    
    return TabID == self.MainUI.RandomTabInfo.TabID;
end

---生效范围：客户端
function ShopV2Manager:GetValidRandomProductIDs(bRefresh)
    
    local ProductIDs = self:GetShopV2Component().ValidRandomProductIDs;

    if ProductIDs == nil then
        ProductIDs = {};
    end

    return ProductIDs;
end

function ShopV2Manager:GetFreeRefreshCount(PlayerController)
    
    return self:GetShopV2Component(PlayerController):GetFreeRefreshCount();
end

function ShopV2Manager:GetValidLockIDs(PlayerController)
    
    local LockIDs = self:GetShopV2Component(PlayerController).ValidLockIDs;

    if LockIDs == nil then
        print("[ShopV2Manager:GetValidLockIDs] LockIDs is nil!");
        LockIDs = {};
    end

    return LockIDs;
end

function ShopV2Manager:GetLockRefreshRule(PlayerController)
    
    return self:GetShopV2Component(PlayerController).LockRefreshRule;
end

function ShopV2Manager:CheckCanLock(PlayerController)
    
    local Comp = self:GetShopV2Component(PlayerController);

    if Comp == nil then
        return false;
    end

    return Comp.CanLock;
end

function ShopV2Manager:GetMaxRandomRefreshNum()
    
    if self.RandomRefreshRule == nil then
        return 0;
    end

    if self.RandomRefreshRule[1].Price > 0 then
        return 0;
    end

    return self.RandomRefreshRule[1].RefreshNum;
end

function ShopV2Manager:GetMaxLockNum(PlayerController)

    return self:GetShopV2Component(PlayerController).MaxLockNum;
end

function ShopV2Manager:GetRefreshPrice(PlayerController)

    return self:GetShopV2Component(PlayerController):GetRandomRefreshPrice();
end

function ShopV2Manager:GetRefreshCostID(PlayerController)
    
    return self:GetShopV2Component(PlayerController).CostID;
end