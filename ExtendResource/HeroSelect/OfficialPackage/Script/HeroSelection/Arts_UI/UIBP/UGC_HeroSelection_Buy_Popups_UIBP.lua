---@class UGC_HeroSelection_Buy_Popups_UIBP_C:UUserWidget
---@field BtnClose UButton
---@field Button_HeroBuy UButton
---@field Common_PopupsBg_Medium_UIBP UCommon_PopupsBg_Medium_UIBP_C
---@field Common_UIPopupBG UCommon_UIPopupBG_C
---@field HeroName UTextBlock
---@field Image_BgQuality UImage
---@field Image_Icon UImage
---@field IsOwned UTextBlock
---@field Money_Type_Img UImage
---@field Text UTextBlock
---@field Text_PriceNum UTextBlock
---@field TextBlock_HeroDescribe UTextBlock
---@field Title UTextBlock
--Edit Below--


local Delegate = UGCGameSystem.UGCRequire("common.Delegate")


---@type UGC_HeroSelection_Buy_Popups_UIBP_C
local UGC_HeroSelection_Buy_Popups_UIBP = { bInitDoOnce = false }

function UGC_HeroSelection_Buy_Popups_UIBP:Construct()
	self:LuaInit()

end

function UGC_HeroSelection_Buy_Popups_UIBP:Destruct()

end


-- [Editor Generated Lua] function define Begin:
function UGC_HeroSelection_Buy_Popups_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
	self.Button_HeroBuy.OnClicked:Add(self.Button_HeroBuy_OnClicked, self);
	self.BtnClose.OnClicked:Add(self.BtnClose_OnClicked, self);
	-- [Editor Generated Lua] BindingEvent End;
end

function UGC_HeroSelection_Buy_Popups_UIBP:Button_HeroBuy_OnClicked()
    HeroSelectionManager:PurchaseHero(self.HeroData.ID)
    ---@type HeroSelectionViewModel
    local VM = UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionViewModel")
    VM.bBuyPopupOpened:set(false)
end

function UGC_HeroSelection_Buy_Popups_UIBP:BtnClose_OnClicked()
    ---@type HeroSelectionViewModel
    local VM = UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionViewModel")
    VM.bBuyPopupOpened:set(false)
end

-- [Editor Generated Lua] function define End;


function UGC_HeroSelection_Buy_Popups_UIBP:SetData(Data)
    self.Data = Data

    ---@type Hero
    self.HeroData = self.Data.HeroData
    ---@type HeroUI
    self.HeroUIData = self.Data.HeroUIData
    ---@type HeroCoinInfo
    self.HeroPurchaseInfo = self.Data.HeroPurchaseInfo

    if self.HeroData then
        self.HeroName:SetText(self.HeroData.Name or self.HeroData.ID or "None")
        self.Image_Icon:SetBrushFromTexture(self.HeroData.Icon, true)
    else
        ugcprint("[HeroSelection] UGC_HeroSelection_Buy_Popups_UIBP:SetData(Data): HeroData is nil")
    end

    if self.HeroUIData then
        self.TextBlock_HeroDescribe:SetText(self.HeroUIData.HeroDetail3)
    else
        ugcprint("[HeroSelection] UGC_HeroSelection_Buy_Popups_UIBP:SetData(Data): HeroUIData is nil")
    end

    if self.HeroPurchaseInfo then
        self.Text_PriceNum:SetText(self.HeroPurchaseInfo.CoinNumber_Discount)
        self.Money_Type_Img:SetBrushFromTexture(self.HeroPurchaseInfo.CoinIcon, true)
    else
        ugcprint("[HeroSelection] UGC_HeroSelection_Buy_Popups_UIBP:SetData(Data): HeroPurchaseInfo is nil")
    end

    local ColorTable = {
        [true] = {SpecifiedColor= {R=0.039546,G=0.045186,B=0.082283,A=1.000000},ColorUseRule=UseColor_Specified},
        [false] = {SpecifiedColor= {R=1.000000,G=0.000000,B=0.000000,A=1.000000},ColorUseRule=UseColor_Specified},
    }

    local bCanAfford = HeroSelectionManager:IsHeroCanAfford(self.HeroData.ID)
    self.Text_PriceNum:SetColorAndOpacity(ColorTable[bCanAfford])
end

function UGC_HeroSelection_Buy_Popups_UIBP:Reset()
    self.Data = nil
    self.HeroData = nil
    self.HeroUIData = nil
    self.HeroPurchaseInfo = nil


    self.HeroName:SetText("None")
    self.Image_Icon:SetBrushFromTexture(nil, true)
    self.TextBlock_HeroDescribe:SetText("None")
    self.Text_PriceNum:SetText("None")
    self.Money_Type_Img:SetBrushFromTexture(nil, true)
end

return UGC_HeroSelection_Buy_Popups_UIBP
