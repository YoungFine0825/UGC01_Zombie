---@class TalentTree_TalentLayer_UI_C:UUserWidget
---@field TextBlock_ConditionalContent UTextBlock
---@field TextBlock_Description UTextBlock
---@field UGC_ReuseList2_Talent UGC_ReuseList2_C
---@field WidgetSwitcher_LockState UWidgetSwitcher
--Edit Below--
local TalentTree_TalentLayer_UI = { bInitDoOnce = false } 

function TalentTree_TalentLayer_UI:Construct()
    self.UGC_ReuseList2_Talent.OnAfterNewItem:Add(self.UGC_ReuseList2_Talent_OnAfterNewItem, self)

    self.CurrentCategoryID = 1
end

function TalentTree_TalentLayer_UI:UpdateTalents()
    local TalentIDs, Length = TalentTreeManager:GetLayerTalentIDs(self.CurrentCategoryID, self.Data.LayerNum)
    -- ugcprint(string.format("TalentTree_TalentLayer_UI:UpdateTalents, Idx = %d, Length = %d.", self.Idx, Length))
    self.UGC_ReuseList2_Talent:Reload(Length)
end

function TalentTree_TalentLayer_UI:ResetTalents()
    self.UGC_ReuseList2_Talent:Reload(0)
end

function TalentTree_TalentLayer_UI:OnUpdate(Data)
    self.Data = Data
    self.Idx = Data.Idx
    self.IsUnlocked = Data.IsUnlocked
    self.CurrentCategoryID = Data.CategoryID

    -- ugcprint(string.format("TalentTree_TalentLayer_UI:OnUpdate, Idx = %d.", self.Idx))
    -- self.TextBlock_LayerNumber:SetText(self.Data.LayerNum)
    -- local UnlockText = string.format("该类别天赋达到%s", self.Data.LimitParameter)

    self.TextBlock_Description:SetText(self.Data.Description)
    self.TextBlock_ConditionalContent:SetText(self.Data.UnlockDescription)
    if self.IsUnlocked then
        self.WidgetSwitcher_LockState:SetActiveWidgetIndex(0)
    else
        self.WidgetSwitcher_LockState:SetActiveWidgetIndex(1)
    end

    self:UpdateTalents()
end

function TalentTree_TalentLayer_UI:UGC_ReuseList2_Talent_OnAfterNewItem(Widget, Idx)
    Idx = Idx + 1
    
    ---@see UGC_ReuseList2_Talent
    Widget:OnUpdate({
        Idx = Idx,
        TalentData = self.Data.LayerTalentData[Idx],
        IsUnlocked = self.IsUnlocked
    })
end

return TalentTree_TalentLayer_UI