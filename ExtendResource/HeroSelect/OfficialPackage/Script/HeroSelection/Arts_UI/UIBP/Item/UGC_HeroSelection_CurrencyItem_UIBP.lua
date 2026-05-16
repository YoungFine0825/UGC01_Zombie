---@class UGC_HeroSelection_CurrencyItem_UIBP_C:UUserWidget
---@field Image_Currency_Icon UImage
---@field Image_Currency_Status UImage
---@field NewButton_Currency_Increase UNewButton
---@field NewButton_Currency_Tips UNewButton
---@field TextBlock_Currency_Amount UTextBlock
---@field ItemID int32
---@field CurrencyIconTexture UTexture2D
--Edit Below--

---@type HeroSelectionShopProxy
local HeroSelectionShopProxy = UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionShopProxy")


---@type UGC_HeroSelection_CurrencyItem_UIBP_C
local UGC_HeroSelection_CurrencyItem_UIBP = { bInitDoOnce = false }


local OASIS_ID = -1


function UGC_HeroSelection_CurrencyItem_UIBP:Construct()
	self:LuaInit()
	self:Refresh()
	-- 设置货币图标
	self.Image_Currency_Icon:SetBrushFromTexture(self.CurrencyIconTexture, false);

	if self:IsOasisCoin() then
		UGCCommoditySystem.UGCCommodityPlayerDataChangedDelegate:Add(self.Refresh, self)
	else
		HeroSelectionShopProxy.OnCoinNumChanged:Add(self.Refresh, self)
	end
end

function UGC_HeroSelection_CurrencyItem_UIBP:Destruct()
	if self:IsOasisCoin() then
		UGCCommoditySystem.UGCCommodityPlayerDataChangedDelegate:Remove(self.Refresh, self)
	else
		HeroSelectionShopProxy.OnCoinNumChanged:Remove(self.Refresh, self)
	end
end

function UGC_HeroSelection_CurrencyItem_UIBP:Refresh()
	local CoinNum
	if self:IsOasisCoin() then
		CoinNum = UGCCommoditySystem.GetTicket()
	else
		CoinNum = HeroSelectionShopProxy:GetRemainCoinNumber(self.ItemID)
	end
	self.TextBlock_Currency_Amount:SetText(tostring(CoinNum))
end

-- [Editor Generated Lua] function define Begin:
function UGC_HeroSelection_CurrencyItem_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
	self.NewButton_Currency_Increase.OnClicked:Add(self.NewButton_Currency_Increase_OnClicked, self);
	-- [Editor Generated Lua] BindingEvent End;
end

function UGC_HeroSelection_CurrencyItem_UIBP:NewButton_Currency_Increase_OnClicked(key)
	HeroSelectionShopProxy:OpenShopPanel()
end

-- [Editor Generated Lua] function define End;

function UGC_HeroSelection_CurrencyItem_UIBP:IsOasisCoin()
	return self.ItemID == OASIS_ID
end

return UGC_HeroSelection_CurrencyItem_UIBP
