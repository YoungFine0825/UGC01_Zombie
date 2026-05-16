---@class ShopV2_CommonButton_UIBP_C:UUserWidget
---@field BuyButtonSwitcher UWidgetSwitcher
---@field CurrencyIcon UImage
---@field CurrentPriceText UTextBlock
---@field FreeButton UButton
---@field OriginalPrice UCanvasPanel
---@field OriginalPriceText UTextBlock
---@field PriceButton UButton
---@field SoldOutButton UButton
--Edit Below--
local ShopV2_CommonButton_UIBP = 
{ 
    bInitDoOnce = false;
    ProductID = 0;
}; 

function ShopV2_CommonButton_UIBP:Construct()
    
    -- Bug 超过两层的 WBP 的 Construct 不会被触发
    -- self.PriceButton.OnClick:Add(self.OnClick, self);
    -- self.FreeButton.OnClick:Add(self.OnClick, self);
end

function ShopV2_CommonButton_UIBP:Reset()
    
    self.OriginalPrice:SetVisibility(ESlateVisibility.Collapsed);
end

function ShopV2_CommonButton_UIBP:Refresh(ProductID)
    
    self.ProductID = ProductID;
    local ProductData = ShopV2Manager:GetProductData(ProductID);
    local CurrentPrice = UGCCommoditySystem.GetSellingPriceAfterDiscount(ProductID);
    local CurrentTime = UGCGameSystem.GetServerTimeSec();

    self:Reset();

    local PurchasedTimes = ShopV2Manager:GetLimitPurchasedTimes(ProductID);
    local bValid = ProductData.ListingTime <= CurrentTime and ProductData.DelistingTime > CurrentTime;
    if ProductData.LimitType ~= ELimitType.NotLimited and PurchasedTimes >= ProductData.PurchaseLimit then
        self.BuyButtonSwitcher:SetActiveWidgetIndex(2);
        return;
    elseif bValid == false then
        self.BuyButtonSwitcher:SetActiveWidgetIndex(2);
        return;
    elseif CurrentPrice == 0 then
        self.BuyButtonSwitcher:SetActiveWidgetIndex(1);
        return;
    else
        self.BuyButtonSwitcher:SetActiveWidgetIndex(0);
    end

    --- 不能购买时字体红色
    self.CurrentPriceText:SetText(tostring(CurrentPrice));

    if ShopV2Manager:CanAfford(ProductData.ProductID, 1) == false then
        self.CurrentPriceText:SetColorRGBStr("FF0000");
    else
        self.CurrentPriceText:SetColorRGBStr("FFFFFF")
    end

    local IconPath = ShopV2Manager:GetProductCurrencyIconPath(ProductID);
    if IconPath ~= nil then
        Common.LoadObjectAsync(IconPath, 
            function (IconTexture)
                if self ~= nil and UE.IsValid(self) then 
                    self.CurrencyIcon:SetBrushFromTexture(IconTexture)
                end
            end
        ) 
    end

    if CurrentPrice ~= ProductData.SellingPrice then
        self.OriginalPrice:SetVisibility(ESlateVisibility.HitTestInvisible);
        self.OriginalPriceText:SetText(ProductData.SellingPrice);
    end
end

function ShopV2_CommonButton_UIBP:OnClick()

    if ShopV2Manager.bBlockRepeatPurchase == true then
        return;
    end

    if LobbyModel ~= nil and LobbyModel.bIsMatching then
        UGCWidgetManagerSystem.ShowTipsUI("当前正在匹配，无法发起购买")
        return;
    end

    if self.BuyButtonSwitcher:GetActiveWidgetIndex() == 2 then
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

function ShopV2_CommonButton_UIBP:ShouldBlockRepeatPurchase(Value)
    
    ShopV2Manager.bBlockRepeatPurchase = Value;
end

return ShopV2_CommonButton_UIBP;
