---@class UGC_Result_MoreTips_UIBP_C:UUserWidget
---@field Sendtips UCanvasPanel
---@field TextBlock_Tips UTextBlock
---@field UGC_ReuseList2 UUGC_ReuseList2_C
--Edit Below--
local UGC_Result_MoreTips_UIBP = { bInitDoOnce = false } 


function UGC_Result_MoreTips_UIBP:Construct()
	self:LuaInit();
	
end

function UGC_Result_MoreTips_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	
	self.UGC_ReuseList2.OnUpdateItem:Add(self.UGC_ReuseList2_OnUpdateItem, self);
	
end

function UGC_Result_MoreTips_UIBP:SetTips(MoreData)
    self.MoreData = MoreData
    self.UGC_ReuseList2:Reload(#self.MoreData)
end

function UGC_Result_MoreTips_UIBP:UGC_ReuseList2_OnUpdateItem(Widget, Idx)
    local Data = self.MoreData[Idx+1]
    Widget.TextBlock_Title:SetText(tostring(Data.title))
    Widget.TextBlock_Number:SetText(tostring(Data.data))
	return nil;
end


return UGC_Result_MoreTips_UIBP
