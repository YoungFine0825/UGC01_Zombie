---@class TalentTree_TabBut_UIBP_C:UUserWidget
---@field Button_Tab UButton
---@field TextBlock_Tab UTextBlock
---@field TextBlock_Tab_Select UTextBlock
---@field WidgetSwitcher_Tab UWidgetSwitcher
--Edit Below--
local TalentTree_TabBut_UIBP = { bInitDoOnce = false } 

function TalentTree_TabBut_UIBP:Construct()
	self.Button_Tab.OnClicked:Add(self.OnTabClicked, self)
end

function TalentTree_TabBut_UIBP:OnUpdate(Data)
    ugcprint("TalentTree_TabBut_UIBP:OnUpdate")
    self.Data = Data
    self.Idx = Data.Idx

    if self.Data.Name then
        self.TextBlock_Tab:SetText(self.Data.Name)
    end

    if self.Data.isSelected then
        self.WidgetSwitcher_Tab:SetActiveWidgetIndex(1)
        self.TextBlock_Tab_Select:SetText(self.Data.Name)
    else
        self.WidgetSwitcher_Tab:SetActiveWidgetIndex(0)
    end
end

-- Tab点击回调
function TalentTree_TabBut_UIBP:OnTabClicked()
    ugcprint("TalentTree_TabBut_UIBP:OnTabClicked")
    TalentTreeManager:SelectTab(self.Idx)
end

return TalentTree_TabBut_UIBP