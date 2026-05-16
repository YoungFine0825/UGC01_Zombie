---@class TalentTree_Popup_UIBP_C:UUserWidget
---@field Button_Close UButton
---@field Button_QueRen UButton
---@field Button_QuXiao UButton
---@field TextBlock_TipsContent UTextBlock
--Edit Below--
local TalentTree_Popup_UIBP = { bInitDoOnce = false } 

function TalentTree_Popup_UIBP:Construct()
	self.Button_QuXiao.OnClicked:Add(self.Button_QuXiao_OnClicked, self)
    self.Button_QueRen.OnClicked:Add(self.Button_QueRen_OnClicked, self)
    self.Button_Close.OnClicked:Add(self.Button_Close_OnClicked, self)
end

function TalentTree_Popup_UIBP:OnUpdate(popupType)
    self.PopupType = popupType
    if popupType == ETalentPopup.Reset then
        self.TextBlock_TipsContent:SetText("是否重置当前页签的天赋树?")
    elseif popupType == ETalentPopup.Confirm then
        self.TextBlock_TipsContent:SetText("该天赋不允许重置，确认升级后将不会返还天赋点")
    end
end

function TalentTree_Popup_UIBP:Button_QuXiao_OnClicked()
    TalentTreeManager:ClosePopup()
end

function TalentTree_Popup_UIBP:Button_Close_OnClicked()
    TalentTreeManager:ClosePopup()
end

function TalentTree_Popup_UIBP:Button_QueRen_OnClicked()
    if self.PopupType == ETalentPopup.Reset then
        TalentTreeManager:ResetTalent()
    else
        TalentTreeManager:CloseTalentTip()
    end
    
    TalentTreeManager:ClosePopup()
end

return TalentTree_Popup_UIBP