---@class Depot_TotalAttributeBut_UIBP_C:UUserWidget
---@field OpenButton UButton
---@field StatsPanel Depot_TotalAttribute_Tips_UIBP_C
---@field WidgetSwitcher_BG UWidgetSwitcher
--Edit Below--
local Depot_TotalAttributeBut_UIBP = { bInitDoOnce = false } 


function Depot_TotalAttributeBut_UIBP:Construct()
	self:LuaInit();
	
end



function Depot_TotalAttributeBut_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	
	self.OpenButton.OnClicked:Add(self.OpenButton_OnClicked, self);
	
end

function Depot_TotalAttributeBut_UIBP:OpenButton_OnClicked()
    if self.StatsPanel:GetVisibility() == ESlateVisibility.Collapsed then
        self.StatsPanel:RefreshData()
        self.StatsPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.StatsPanel:SetVisibility(ESlateVisibility.Collapsed)
    end
	return nil;
end


return Depot_TotalAttributeBut_UIBP