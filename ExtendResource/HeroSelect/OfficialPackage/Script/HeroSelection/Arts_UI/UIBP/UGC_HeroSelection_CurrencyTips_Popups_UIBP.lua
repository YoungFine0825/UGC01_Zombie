---@class UGC_HeroSelection_CurrencyTips_Popups_UIBP_C:UUserWidget
---@field Button_Cancel UButton
---@field Button_CloseUI UButton
---@field Button_Recharge UButton
---@field Common_PopupsBg_Small_UIBP UCommon_PopupsBg_Small_UIBP_C
---@field Image_1 UImage
---@field Text_cancel UTextBlock
---@field Text_Content UUTRichTextBlock
---@field Text_ok UTextBlock
---@field TextBlock_Title UTextBlock
---@field UGC_Common_UIPopupBG UUGC_Common_UIPopupBG_C
--Edit Below--


---@type HeroSelectionShopProxy
local HeroSelectionShopProxy = UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionShopProxy")


---@type UGC_HeroSelection_CurrencyTips_Popups_UIBP_C
local UGC_HeroSelection_CurrencyTips_Popups_UIBP = { bInitDoOnce = false } 


function UGC_HeroSelection_CurrencyTips_Popups_UIBP:Construct()
	self:LuaInit();
	
end

function UGC_HeroSelection_CurrencyTips_Popups_UIBP:Destruct()

end

-- [Editor Generated Lua] function define Begin:
function UGC_HeroSelection_CurrencyTips_Popups_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
	self.Button_Recharge.OnClicked:Add(self.Button_Recharge_OnClicked, self);
	self.Button_Cancel.OnClicked:Add(self.Button_Cancel_OnClicked, self);
	-- [Editor Generated Lua] BindingEvent End;
end

function UGC_HeroSelection_CurrencyTips_Popups_UIBP:Button_Recharge_OnClicked()
	HeroSelectionShopProxy:OpenShopPanel()

	---@type HeroSelectionViewModel
	local VM = UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionViewModel")
	VM.bCurrencyTipsPopupOpened:set(false)
end

function UGC_HeroSelection_CurrencyTips_Popups_UIBP:Button_Cancel_OnClicked()
	---@type HeroSelectionViewModel
	local VM = UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionViewModel")
	VM.bCurrencyTipsPopupOpened:set(false)
end

-- [Editor Generated Lua] function define End;

return UGC_HeroSelection_CurrencyTips_Popups_UIBP
