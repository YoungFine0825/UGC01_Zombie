---@class ShopV2_PurchasePopups_UIBP_C:UUserWidget
---@field BuyButton UButton
---@field CloseButton UButton
---@field Common_PopupsBg_Medium_UIBP UCommon_PopupsBg_Medium_UIBP_C
---@field CountDownText UTextBlock
---@field CountText UTextBlock
---@field CurrencyIcon UImage
---@field DecreaseButton UButton
---@field DescText UTextBlock
---@field Image_Bg_Quality UImage
---@field Image_Quality UImage
---@field Increase100Button UButton
---@field Increase10Button UButton
---@field IncreaseButton UButton
---@field ProductIcon UImage
---@field ProductName UTextBlock
---@field TotalPriceText UTextBlock
--Edit Below--

local ShopV2_PurchasePopups_UIBP = 
{ 
    bInitDoOnce = false;
    ProductData = nil;
    Count = 1;
    CurrentPrice = 0;
} 

function ShopV2_PurchasePopups_UIBP:Construct()
	
    self.BuyButton.OnClicked:Add(self.OnBuyClick, self);
    self.IncreaseButton.OnClicked:Add(self.OnIncreaseClick, self);
    self.Increase10Button.OnClicked:Add(self.OnIncrease10Click, self);
    self.Increase100Button.OnClicked:Add(self.OnIncrease100Click, self);
    self.DecreaseButton.OnClicked:Add(self.OnDecreaseClick, self);
    self.CloseButton.OnClicked:Add(self.OnCloseClick, self);
end

function ShopV2_PurchasePopups_UIBP:Destruct()
    
    self.BuyButton.OnClicked:Remove(self.OnBuyClick, self);
    self.IncreaseButton.OnClicked:Remove(self.OnIncreaseClick, self);
    self.Increase10Button.OnClicked:Remove(self.OnIncrease10Click, self);
    self.Increase100Button.OnClicked:Remove(self.OnIncrease100Click, self);
    self.DecreaseButton.OnClicked:Remove(self.OnDecreaseClick, self);
    self.CloseButton.OnClicked:Remove(self.OnCloseClick, self);
end

function ShopV2_PurchasePopups_UIBP:Refresh(ProductID)
    
    self.ProductData = ShopV2Manager:GetProductData(ProductID);
    local ItemData = ShopV2Manager:GetItemData(self.ProductData.ItemID);

    self.Count = 1;
    
    self.ProductName:SetText(self.ProductData.ProductName);
    Common.LoadObjectAsync(ItemData.ItemIcon, 
        function (IconTexture)
            if self ~= nil and UE.IsValid(self) then 
                self.ProductIcon:SetBrushFromTexture(IconTexture);
            end
        end
    )

    local Path = ShopV2Manager:GetProductCurrencyIconPath(ProductID);
    if Path ~= nil then
        Common.LoadObjectAsync(Path, 
            function (IconTexture)
                if self ~= nil and UE.IsValid(self) then 
                    self.CurrencyIcon:SetBrushFromTexture(IconTexture);
                end
            end
        ) 
    end
    
    if self.ProductData.AvailableForSale == EAvailableForSale.LimitedTimeSale then
        local RemainingDays = ShopV2Manager:GetRemainingDays(self.ProductData.DelistingTime);
        self.CountDownText:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
        self.CountDownText:SetText(string.format("剩%d天下架", RemainingDays));
    else
        self.CountDownText:SetVisibility(ESlateVisibility.Collapsed);
    end

    self.DescText:SetText(ItemData.ItemDesc);
    
    self:RefreshNumAndPrice();
end

function ShopV2_PurchasePopups_UIBP:RefreshNumAndPrice()

    self.CurrentPrice = ShopV2Manager:GetDiscountPrice(self.ProductData.ProductID);
    self.CountText:SetText(tostring(self.Count))
    self.TotalPriceText:SetText(tostring(self.CurrentPrice * self.Count));
end

function ShopV2_PurchasePopups_UIBP:ChangeCount(Amount)

    local Tmp = self.Count + Amount;
    
    if Tmp <= 0 then
        Tmp = 1;
    end
    
    --- 超出已有金币数
    if ShopV2Manager:CanAfford(self.ProductData.ProductID, Tmp) == false then
        ShopV2Manager:ShowPurchaseTip("超出已有资金");
        return;
    end

    --- 超出购买限制
    local PlayerController = UGCGameSystem.GetLocalPlayerController();
    if self.ProductData.LimitType ~= ELimitType.NotLimited and 
    ShopV2Manager:GetLimitPurchasedTimes(self.ProductData.ProductID) + Tmp > self.ProductData.PurchaseLimit then
        ShopV2Manager:ShowPurchaseTip("超出限购次数");
        return;
    end

    self.Count = Tmp;
    self:RefreshNumAndPrice();
end

function ShopV2_PurchasePopups_UIBP:OnBuyClick()
    
    if self.CurrentPrice ~= ShopV2Manager:GetDiscountPrice(self.ProductData.ProductID) then
        ShopV2Manager:ShowPurchaseTip("购买失败，价格已更新");
    elseif ShopV2Manager:IsProductValid(self.ProductData.ProductID) == false then
        ShopV2Manager:ShowPurchaseTip("购买失败，商品未上架");
    else
        ShopV2Manager:BuyProduct(self.ProductData.ProductID, self.Count, self.CurrentPrice);
    end

    self:SetVisibility(ESlateVisibility.Collapsed);
end

function ShopV2_PurchasePopups_UIBP:OnIncreaseClick()
    
    self:ChangeCount(1);
end

function ShopV2_PurchasePopups_UIBP:OnDecreaseClick()
    
    self:ChangeCount(-1);
end

function ShopV2_PurchasePopups_UIBP:OnIncrease10Click()
    
    self:ChangeCount(10);
end

function ShopV2_PurchasePopups_UIBP:OnIncrease100Click()
    
    self:ChangeCount(100);
end

function ShopV2_PurchasePopups_UIBP:OnCloseClick()
    
    self:SetVisibility(ESlateVisibility.Collapsed);
    ShopV2Manager.bBlockRepeatPurchase = false;
end

return ShopV2_PurchasePopups_UIBP
