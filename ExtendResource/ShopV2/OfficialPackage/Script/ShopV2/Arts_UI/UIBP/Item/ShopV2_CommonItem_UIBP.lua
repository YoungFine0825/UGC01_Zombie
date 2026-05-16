---@class ShopV2_CommonItem_UIBP_C:UUserWidget
---@field BuyButton UButton
---@field CanvasPanel_CheckTips UCanvasPanel
---@field CountDown UCanvasPanel
---@field CountDownText UTextBlock
---@field CurrencyIcon UImage
---@field CurrentPriceText UTextBlock
---@field DiscountLabel UCanvasPanel
---@field DiscountText UTextBlock
---@field ItemButton UButton
---@field ItemIcon UImage
---@field LimitPurchaseNumText UTextBlock
---@field LimitPurchaseTypeText UTextBlock
---@field LockIcon UCanvasPanel
---@field NotAvailableMask UImage
---@field OriginalPrice UCanvasPanel
---@field OriginalPriceText UTextBlock
---@field PriceTypeSwitcher UWidgetSwitcher
---@field QualityBackground UImage
---@field QualityBar UImage
---@field SelectHighlight UCanvasPanel
--Edit Below--
local ShopV2_CommonItem_UIBP = 
{ 
    bInitDoOnce = false;
    ProductID = 0;
    bSoldOut = false;
    bDiscount = false;

    bSelected = false;

    LockID = 0;
};

function ShopV2_CommonItem_UIBP:Construct()
	
    self.ItemButton.OnClicked:Add(self.OnItemButtonClick, self);
    self.BuyButton.OnClicked:Add(self.OnBuyButtonClick, self);
end

function ShopV2_CommonItem_UIBP:Destruct()
    self.ItemButton.OnClicked:Remove(self.OnItemButtonClick, self);
    self.BuyButton.OnClicked:Remove(self.OnBuyButtonClick, self);
end

function ShopV2_CommonItem_UIBP:Reset()
    
    self.LimitPurchaseTypeText:SetVisibility(ESlateVisibility.Collapsed);
    self.LimitPurchaseNumText:SetVisibility(ESlateVisibility.Collapsed);
    self.DiscountLabel:SetVisibility(ESlateVisibility.Collapsed);
    self.NotAvailableMask:SetVisibility(ESlateVisibility.Collapsed);
    self.OriginalPrice:SetVisibility(ESlateVisibility.Collapsed);
    self.CountDown:SetVisibility(ESlateVisibility.Collapsed);

    self.bDiscount = false;
    self.bSoldOut  = false;
end

function ShopV2_CommonItem_UIBP:Refresh(ProductID)
    
    self.ProductID = ProductID;
    local ProductData = ShopV2Manager:GetProductData(ProductID);

    local IconPath = ShopV2Manager:GetItemData(ProductData.ItemID).ItemIcon;
    
    Common.LoadObjectAsync(IconPath, 
        function (IconTexture)
            if self ~= nil and UE.IsValid(self) then
                self.ItemIcon:SetBrushFromTexture(IconTexture);
            end
        end
    )

    --- 显示品质
    Common.LoadObjectAsync(ShopV2Manager:GetQualityTexturePath(ProductData.ItemID, false), 
        function (IconTexture)
            if self ~= nil and UE.IsValid(self) then
                self.QualityBackground:SetBrushFromTexture(IconTexture);
            end
        end
    );

    Common.LoadObjectAsync(ShopV2Manager:GetQualityBarTexturePath(ProductData.ItemID),
        function (IconTexture)
            if self ~= nil and UE.IsValid(self) then
                self.QualityBar:SetBrushFromTexture(IconTexture);
            end
        end
    );
    
    --- 是否限购
    if ProductData.LimitType ~= ELimitType.NotLimited then
        self.LimitPurchaseTypeText:SetVisibility(ESlateVisibility.HitTestInvisible);
        self.LimitPurchaseNumText:SetVisibility(ESlateVisibility.HitTestInvisible);
        local Text;
        if ProductData.LimitType == ELimitType.DailyLimit then
            Text = "每日限购";
        elseif ProductData.LimitType == ELimitType.WeeklyLimit then
            Text = "每周限购";
        else
            Text = "永久限购";
        end
        self.LimitPurchaseTypeText:SetText(Text);

        --- 已购买数量
        local PlayerController = UGCGameSystem.GetLocalPlayerController();
        local PurchasedNum = ShopV2Manager:GetLimitPurchasedTimes(ProductID);
        self.LimitPurchaseNumText:SetText(tostring(PurchasedNum) .. "/" .. ProductData.PurchaseLimit);
        self.bSoldOut = PurchasedNum >= ProductData.PurchaseLimit;
    end

    local CurrentTime = UGCGameSystem.GetServerTimeSec();
    if CurrentTime >= ProductData.DelistingTime then
        self.bSoldOut = true;
    end

    --- 显示价格
    if self.bSoldOut == true then
        self.PriceTypeSwitcher:SetActiveWidgetIndex(1);     --- 售罄
    elseif ProductData.SellingPrice == 0 then
        self.PriceTypeSwitcher:SetActiveWidgetIndex(2);     --- 免费
    else
        self.PriceTypeSwitcher:SetActiveWidgetIndex(0);     --- 价格
        self:RefreshPrice(ProductData);
    end

    --- 售罄则显示灰色 Mask
    if self.bSoldOut == true then
        self.NotAvailableMask:SetVisibility(ESlateVisibility.HitTestInvisible);
        return;     --- 售罄不显示倒计时，直接 return
    end
    
    --- 显示倒计时（单位：天）
    --- 优先显示折扣剩余时间
    if self.bDiscount == true and ShopV2Manager:IsPermanentDiscount(ProductData.DiscountEndTime) == false then
        local RemainingDays = ShopV2Manager:GetRemainingDays(ProductData.DiscountEndTime);
        self.CountDown:SetVisibility(ESlateVisibility.HitTestInvisible);
        self.CountDownText:SetText(string.format("折扣剩%d天", RemainingDays)); 
    elseif ProductData.AvailableForSale == EAvailableForSale.LimitedTimeSale then
        local RemainingDays = ShopV2Manager:GetRemainingDays(ProductData.DelistingTime);
        self.CountDown:SetVisibility(ESlateVisibility.HitTestInvisible);
        self.CountDownText:SetText(string.format("剩%d天下架", RemainingDays));
    end
end

function ShopV2_CommonItem_UIBP:NormalRefresh(ProductID)
    
    --- 统一 Collapse 然后 Refresh 按照情况显示，让逻辑更清晰
    self:Reset();
    self.LockIcon:SetVisibility(ESlateVisibility.Collapsed);
    self.LockID = 0;
    self:Refresh(ProductID);
end

--- 限时随机商城刷新
function ShopV2_CommonItem_UIBP:RandomRefresh(LockID, ProductID)

    -- 统一 Collapse 然后 Refresh 按照情况显示，让逻辑更清晰
    self:Reset();
    self.LockIcon:SetVisibility(ESlateVisibility.Collapsed);

    if LockID == nil or ProductID == nil or LockID == 0 or ProductID == 0 then
        print("[ShopV2_CommonItem_UIBP:RandomRefresh] Invalid LockID or ProductID");
        return;
    end

    local ProductID = ProductID;
    self.LockID = LockID;

    -- 显示锁图标
    if ShopV2Manager:GetIsLocked(self.LockID) == true then
        self.LockIcon:SetVisibility(ESlateVisibility.HitTestInvisible);
    end

    self:Refresh(ProductID);
end

function ShopV2_CommonItem_UIBP:RefreshPrice(ProductData)
    
    self.CurrencyIcon:SetVisibility(ESlateVisibility.HitTestInvisible);
    local PlayerController = UGCGameSystem.GetLocalPlayerController();

    --- 显示货币类型
    local Path = ShopV2Manager:GetProductCurrencyIconPath(ProductData.ProductID);
    Common.LoadObjectAsync(Path, 
        function (IconTexture)
            if self ~= nil and UE.IsValid(self) then
                self.CurrencyIcon:SetBrushFromTexture(IconTexture);
            end
        end
    )

    --- 显示价格
    local DiscountPrice = ShopV2Manager:GetDiscountPrice(self.ProductID);
    self.CurrentPriceText:SetText(tostring(DiscountPrice));

    if ShopV2Manager:CanAfford(ProductData.ProductID, 1) == false then
        self.CurrentPriceText:SetColorRGBStr("FF5448");
    else
        self.CurrentPriceText:SetColorRGBStr("FFFFFF")
    end
    
    if ProductData.SellingPrice ~= DiscountPrice then
        self.OriginalPrice:SetVisibility(ESlateVisibility.HitTestInvisible);
        self.OriginalPriceText:SetText(tostring(ProductData.SellingPrice));
        
        --- 显示折扣标签
        self.DiscountLabel:SetVisibility(ESlateVisibility.HitTestInvisible);
        self.DiscountText:SetText(tostring(ProductData.Discount) .. "折");
        self.bDiscount = true;
    end
end

function ShopV2_CommonItem_UIBP:Select()

    self.SelectHighlight:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
    self.bSelected = true;
end

function ShopV2_CommonItem_UIBP:Deselect()
    
    self.SelectHighlight:SetVisibility(ESlateVisibility.Collapsed);
    self.bSelected = false
end

function ShopV2_CommonItem_UIBP:OnItemButtonClick()

    if ShopV2Manager.bSelectMode == true and self.LockID ~= 0 then
        self:SwitchLock();
    end

    ShopV2Manager:SelectProduct(self.ProductID);
end

function ShopV2_CommonItem_UIBP:SwitchLock()

    if ShopV2Manager.bConfirmedLock == false then
        if self.LockIcon:IsVisible() == false then
            if ShopV2Manager.PendingLockNum >= ShopV2Manager:GetMaxLockNum() then
                ShopV2Manager:ShowPurchaseTip("已达到最大锁定数");
                return;
            end

            self.LockIcon:SetVisibility(ESlateVisibility.HitTestInvisible);
            ShopV2Manager:AddPendingLock(self.LockID);
        else
            self.LockIcon:SetVisibility(ESlateVisibility.Collapsed);
            ShopV2Manager:RemovePendingLock(self.LockID);
        end
    else
        ShopV2Manager:ShowPurchaseTip("取消确认锁定才能修改锁定商品");
    end
end

function ShopV2_CommonItem_UIBP:OnBuyButtonClick()
    
    if ShopV2Manager.bBlockRepeatPurchase == true then
        return;
    end

    if LobbyModel ~= nil and LobbyModel.bIsMatching then
        UGCWidgetManagerSystem.ShowTipsUI("当前正在匹配，无法发起购买")
        return;
    end

    if self.PriceTypeSwitcher:GetActiveWidgetIndex() == 1 then
        ShopV2Manager:ShowPurchaseTip("商品已售罄");
        return;
    end

    if ShopV2Manager:CanAfford(self.ProductID, 1) == false then
        ShopV2Manager:ShowPurchaseTip("资金不足");
        return;
    end

    ShopV2Manager.bBlockRepeatPurchase = true;
    local ProductData = ShopV2Manager:GetProductData(self.ProductID);

    if ProductData.CurrencyType == ECurrencyType.OtherCoin then
        ShopV2Manager:OpenPurchaseUI(self.ProductID);
    else
        local ObjectData = ShopV2Manager:GetItemData(ProductData.ItemID);

        local PromiseFuture = UGCCommoditySystem.BuyUGCCommodity2(self.ProductID, ObjectData.ItemIcon, ObjectData.ItemDesc, 1);
        if PromiseFuture ~= nil then
            PromiseFuture:Then(
                function (Result)
                    local UI = Result:Get();
                    UI.ConfirmationOperationDelegate:Add(self.ShouldBlockRepeatPurchase, self);
                end
            )
        end
    end
end

function ShopV2_CommonItem_UIBP:ShouldBlockRepeatPurchase(Value)
    
    ShopV2Manager.bBlockRepeatPurchase = Value;
end

return ShopV2_CommonItem_UIBP
