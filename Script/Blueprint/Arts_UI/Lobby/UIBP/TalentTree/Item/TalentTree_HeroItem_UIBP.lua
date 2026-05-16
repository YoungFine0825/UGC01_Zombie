---@class TalentTree_HeroItem_UIBP_C:UUserWidget
---@field Button_Select UButton
---@field CanvasPanel_Lock UCanvasPanel
---@field CanvasPanel_Select UCanvasPanel
---@field Image_Hero UImage
---@field TextBlock_HeroName UTextBlock
--Edit Below--

local TalentTree_HeroItem_UIBP = 
{ 
    bInitDoOnce = false,
    HeroID = 0, 
} 


function TalentTree_HeroItem_UIBP:Construct()
    self.Button_Select.OnClicked:Add(self.OnSelectClicked, self)
    
    ugcprint("TalentTree_HeroItem_UIBP:Construct()")
end

function TalentTree_HeroItem_UIBP:OnUpdate(Data)
    ugcprint("TalentTree_HeroItem_UIBP:OnUpdate")
    self.Data = Data
    self.Idx = Data.Idx
    self.HeroData = self.Data.HeroData

    if self.HeroData then
        self.TextBlock_HeroName:SetText(self.HeroData.Name) 
        self.HeroID = self.HeroData.ID   
        if self.HeroData.Icon then
            self.Image_Hero:SetBrushFromTexture(self.HeroData.Icon, false)    
        end
    end

    if self.Data.isSelected then
        self.CanvasPanel_Select:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.CanvasPanel_Select:SetVisibility(ESlateVisibility.Collapsed)
    end

    if self.Data.isLocked then
        self.CanvasPanel_Lock:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.CanvasPanel_Lock:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function TalentTree_HeroItem_UIBP:OnSelectClicked()
    ugcprint(string.format("TalentTree_HeroItem_UIBP:OnSelectClicked, HeroIdx = %d.", self.Idx))
    TalentTreeManager:SelectHero(self.Idx)
end

return TalentTree_HeroItem_UIBP