---@class TalentTree_Main_UIBP_C:UUserWidget
---@field Button_Close UButton
---@field Button_CloseRep UButton
---@field Button_CloseTip UButton
---@field Button_Confirm UButton
---@field Button_Reset UButton
---@field Button_ShouQi UButton
---@field Button_ZhanKai UButton
---@field CanvasPanel_ShouQi UCanvasPanel
---@field CanvasPanel_Upgrade UCanvasPanel
---@field Image_Hero UImage
---@field ScaleBox_IPX UScaleBox
---@field TalentTree_TalentLayer01 TalentTree_TalentLayer_UI_C
---@field TalentTree_TalentLayer02 TalentTree_TalentLayer_UI_C
---@field TalentTree_TalentLayer03 TalentTree_TalentLayer_UI_C
---@field TalentTree_TalentLayer04 TalentTree_TalentLayer_UI_C
---@field TalentTree_TalentLayer05 TalentTree_TalentLayer_UI_C
---@field TextBlock_Tag UTextBlock
---@field TextBlock_TFDS UTextBlock
---@field UGC_ReuseList2_Hero UGC_ReuseList2_C
---@field UGC_ReuseList2_HeroChoice UGC_ReuseList2_C
---@field UGC_ReuseList2_Tab UGC_ReuseList2_C
---@field WidgetSwitcher_Confirm UWidgetSwitcher
---@field WidgetSwitcher_HeroBox UWidgetSwitcher
--Edit Below--
local TalentTree_Main_UIBP = { bInitDoOnce = false } 

UGCGameSystem.UGCRequire("Script.Blueprint.Arts_UI.Lobby.TalentTreeManager")

function TalentTree_Main_UIBP:Construct()
	ugcprint("TalentTree_Main_UIBP:Construct")

    self.Button_Close.OnClicked:Add(self.OnCloseClicked, self)
    self.Button_Reset.OnClicked:Add(self.OnResetClicked, self)
    self.Button_ShouQi.OnClicked:Add(self.OnShouQiClicked, self)
    self.Button_ZhanKai.OnClicked:Add(self.OnZhankaiClicked, self)
    self.Button_CloseTip.OnClicked:Add(self.OnCloseTipClicked, self)

    self.UGC_ReuseList2_Hero.OnAfterNewItem:Add(self.UGC_ReuseList2_Hero_OnAfterNewItem, self)
    self.UGC_ReuseList2_HeroChoice.OnAfterNewItem:Add(self.UGC_ReuseList2_HeroChoice_OnAfterNewItem, self)
    self.UGC_ReuseList2_Tab.OnAfterNewItem:Add(self.UGC_ReuseList2_Tab_OnAfterNewItem, self)


    TalentTreeManager.OnTalentPointsUpdate:Add(self.OnTalentPointsUpdate, self)
    TalentTreeManager.OnTabSelected:Add(self.OnTabSelected, self)
    TalentTreeManager.OnHeroSelected:Add(self.OnHeroSelected, self)
    TalentTreeManager.OnTalentInfoUpdate:Add(self.OnTalentInfoUpdate, self)

    self.CurrentCategoryID = 1

    Common.LoadObjectAsync(UGCGameSystem.GetUGCResourcesFullPath('Asset/WwiseEvent/UGCEditor_Reset.UGCEditor_Reset'),
    function (Object)
        if Object ~= nil and self ~= nil then
            self.ResetSound = Object
        end
    end
    )

    Common.LoadObjectAsync(UGCGameSystem.GetUGCResourcesFullPath('Asset/WwiseEvent/UGCEditor_LeftCheck.UGCEditor_LeftCheck'),
    function (Object)
        if Object ~= nil and self ~= nil then
            self.LeftCheckSound = Object
        end
    end
    )

    Common.LoadObjectAsync(UGCGameSystem.GetUGCResourcesFullPath('Asset/WwiseEvent/UGCEditor_RightCheck.UGCEditor_RightCheck'),
    function (Object)
        if Object ~= nil and self ~= nil then
            self.RightCheckSound = Object
        end
    end
    )

    UICommonFunctionLibrary.SetAdaptation(self.ScaleBox_IPX, self)
end

function TalentTree_Main_UIBP:Destruct()
    self.Button_Close.OnClicked:Remove(self.OnCloseClicked, self)

    self.UGC_ReuseList2_Hero.OnAfterNewItem:Remove(self.UGC_ReuseList2_Hero_OnAfterNewItem, self)
    self.UGC_ReuseList2_HeroChoice.OnAfterNewItem:Remove(self.UGC_ReuseList2_HeroChoice_OnAfterNewItem, self)
    self.UGC_ReuseList2_Tab.OnAfterNewItem:Remove(self.UGC_ReuseList2_Tab_OnAfterNewItem, self)
end

function TalentTree_Main_UIBP:UpdateMode()
    local ModeID = self.Data.ModeID or LobbyModel:GetCurrentSelectedModeID()
    local ModeConfig = LobbyModel:GetModelConfig(ModeID)
end

function TalentTree_Main_UIBP:OnOpen(Data)
    LobbyUtils.SetOtherWidgetHidden(true)
    TalentTreeManager.OnMainWidgetOpened()
    TalentTreeManager:SaveTempTalentInfo()
    TalentTreeManager:UpdateSelectedHero()
    TalentTreeManager:SelectHero(TalentTreeManager:GetSelectedHeroIdx())
    TalentTreeManager:SelectTab(1)
end

function TalentTree_Main_UIBP:OnClose()
    
end

function TalentTree_Main_UIBP:OnUpdate(Data)
    ugcprint("TalentTree_Main_UIBP:OnUpdate")
    self.Data = Data
    self.CanvasPanel_Upgrade:SetVisibility(ESlateVisibility.Collapsed)
    
    self:UpdateHero()
    self:UpdateCategory()
    self:UpdateLayers()
    self:UpdateTalentPoints()
end

---更新英雄信息
function TalentTree_Main_UIBP:UpdateHero()
    ugcprint("TalentTree_Main_UIBP:UpdateHero")
    local _, Length = TalentTreeManager:GetUGCHeroDataMap()

    if Length <= 5 then
        self.CanvasPanel_ShouQi:SetVisibility(ESlateVisibility.Collapsed)
    end

    ---@see TalentTree_Main_UIBP#UGC_ReuseList2_Hero_OnAfterNewItem
    self.UGC_ReuseList2_Hero:Reload(Length)
    self.UGC_ReuseList2_HeroChoice:Reload(Length)

    local SelectedHeroIdx = TalentTreeManager:GetSelectedHeroIdx()
    local SelectedHeroData = TalentTreeManager:GetHeroDataByIdx(SelectedHeroIdx)
    self.Image_Hero:SetBrushFromTexture(SelectedHeroData.HeroPortrait, false)
end

-- 更新英雄列表回调
function TalentTree_Main_UIBP:UGC_ReuseList2_Hero_OnAfterNewItem(Widget, Idx)
    ugcprint("TalentTree_Main_UIBP:UGC_ReuseList2_Hero_OnAfterNewItem")
    Idx = Idx + 1

    local HeroData = TalentTreeManager:GetHeroDataByIdx(Idx)
    local isSelected = (Idx == TalentTreeManager:GetSelectedHeroIdx())
    local isLocked = HeroSelectionManager:IsHeroLocked(HeroData.ID)
    
    ---@see TalentTree_HeroItem_UIBP_C#UGC_ReuseList2_Hero_OnAfterNewItem
    Widget:OnUpdate({
        Idx = Idx,
        HeroData = HeroData,
        isSelected = isSelected,
        isLocked = isLocked,
    })
end

function TalentTree_Main_UIBP:UGC_ReuseList2_HeroChoice_OnAfterNewItem(Widget, Idx)
    ugcprint("TalentTree_Main_UIBP:UGC_ReuseList2_HeroChoice_OnAfterNewItem")
    Idx = Idx + 1

    local HeroData = TalentTreeManager:GetHeroDataByIdx(Idx)
    local isSelected = (Idx == TalentTreeManager:GetSelectedHeroIdx())
    
    ---@see TalentTree_HeroItem_UIBP_C#UGC_ReuseList2_HeroChoice_OnAfterNewItem
    Widget:OnUpdate({
        Idx = Idx,
        HeroData = HeroData,
        isSelected = isSelected
    })
end

-- 更新类别信息
function TalentTree_Main_UIBP:UpdateCategory()
    -- ugcprint("TalentTree_Main_UIBP:UpdateCategory")
    local _, Length = TalentTreeManager:GetTalentCategoryDataMap()

    ---@see TalentTree_Main_UIBP#UGC_ReuseList2_Tab_OnAfterNewItem
    self.UGC_ReuseList2_Tab:Reload(Length)
end

-- 更新类别列表回调
function TalentTree_Main_UIBP:UGC_ReuseList2_Tab_OnAfterNewItem(Widget, Idx)
    -- ugcprint("TalentTree_Main_UIBP:UGC_ReuseList2_Tab_OnAfterNewItem")
    Idx = Idx + 1
    local CategoryData = TalentTreeManager:GetCategoryDataByIdx(Idx)
    local isSelected = (Idx == TalentTreeManager:GetSelectedTabIdx())

    if CategoryData.IsGeneral then
        Widget:OnUpdate({
        Idx = Idx,
        Name = CategoryData.Name,
        isSelected = isSelected
        })
        Idx = Idx + 1
    else
        local HeroData = TalentTreeManager:GetHeroDataByHeroID(CategoryData.HeroID)
        Widget:OnUpdate({
        Idx = Idx,
        Name = HeroData.Name,
        isSelected = isSelected
        })
    end
end

-- 更新天赋层数
function TalentTree_Main_UIBP:UpdateLayers()
    local SortedLayers = TalentTreeManager:GetLayerData(self.CurrentCategoryID)

    -- 先将所有Widget都设置为隐藏
    local LayerIndex = 1
    while self["TalentTree_TalentLayer" .. string.format("%02d", LayerIndex)] do
        local LayerWidgetName = string.format("TalentTree_TalentLayer%02d", LayerIndex)
        local LayerWidget = self[LayerWidgetName]
        if LayerWidget then
            LayerWidget:SetVisibility(ESlateVisibility.Collapsed)
            LayerWidget:ResetTalents()
        end
        LayerIndex = LayerIndex + 1
    end

    for Idx, SortedLayer in ipairs(SortedLayers) do
        local LayerWidgetName = string.format("TalentTree_TalentLayer%02d", Idx)
        local LayerWidget = self[LayerWidgetName]
        if LayerWidget then
            if SortedLayer and #SortedLayer.TalentIDs then
                LayerWidget:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
                LayerWidget:OnUpdate({
                Idx = Idx,
                LayerNum = Idx,
                LimitParameter = SortedLayer.LimitParameter,
                Description = SortedLayer.Description,
                UnlockDescription = SortedLayer.UnlockDescription,
                CategoryID = self.CurrentCategoryID,
                IsUnlocked = TalentTreeManager:GetUnlockState(self.CurrentCategoryID, Idx),
                
                LayerTalentData = TalentTreeManager:GetLayerTalentData(self.CurrentCategoryID, Idx),
            })
            else
                LayerWidget:SetVisibility(ESlateVisibility.Collapsed)
            end
        else
            ugcprint(string.format("[TalentTree] Layer widget %s not found for layer %d", LayerWidgetName, Idx))
        end
    end
end

-- 更新天赋点显示
function TalentTree_Main_UIBP:UpdateTalentPoints()
    ugcprint("TalentTree_Main_UIBP:UpdateTalentPoints")
    local TalentPoints = TalentTreeManager:GetTalentPoints()
    self.TextBlock_TFDS:SetText(TalentPoints)
end

function TalentTree_Main_UIBP:OnCloseClicked()
    ugcprint("TalentTree_Main_UIBP:OnCloseClicked")
    TalentTreeManager:CloseMainWidget()    
end

function TalentTree_Main_UIBP:OnResetClicked()
    ugcprint("TalentTree_Main_UIBP:OnResetClicked")
    TalentTreeManager:OpenPopup(ETalentPopup.Reset)

    if self.ResetSound ~= nil then
        UGCSoundManagerSystem.PlaySound2D(self.ResetSound)
    end
end

function TalentTree_Main_UIBP:OnShouQiClicked()
    self.WidgetSwitcher_HeroBox:SetActiveWidgetIndex(0)
end

function TalentTree_Main_UIBP:OnZhankaiClicked()
    self.WidgetSwitcher_HeroBox:SetActiveWidgetIndex(1)
end

function TalentTree_Main_UIBP:OnCloseTipClicked()
    local CategoryData = TalentTreeManager:GetCategoryDataByCategoryID(self.CurrentCategoryID)
    if not CategoryData.CanReset then
        TalentTreeManager:CancelChanges()
    end
    TalentTreeManager:CloseTalentTip()
end

-- 玩家点击页签回调
function TalentTree_Main_UIBP:OnTabSelected(TabIdx)
    ugcprint("TalentTree_Main_UIBP:OnTabSelected")
    local CategoryData = TalentTreeManager:GetCategoryDataByIdx(TabIdx)
    self.CurrentCategoryID = CategoryData.ID

    if CategoryData.CanReset then
        self.WidgetSwitcher_Confirm:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.WidgetSwitcher_Confirm:SetVisibility(ESlateVisibility.Collapsed)
    end

    if CategoryData.IsGeneral then
        self.WidgetSwitcher_HeroBox:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.WidgetSwitcher_HeroBox:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end

    self:UpdateCategory()

    if self.RightCheckSound ~= nil then
        UGCSoundManagerSystem.PlaySound2D(self.RightCheckSound)
    end
end

-- 玩家点击英雄回调
function TalentTree_Main_UIBP:OnHeroSelected(HeroIdx)
    self.CurrentHeroIdx = HeroIdx
    self:UpdateHero()

    if self.LeftCheckSound ~= nil then
        UGCSoundManagerSystem.PlaySound2D(self.LeftCheckSound)
    end
end

function TalentTree_Main_UIBP:OnTalentPointsUpdate(TalentPoints)
    ugcprint("TalentTree_Main_UIBP:OnTalentPointsUpdate")
    self.TextBlock_TFDS:SetText(TalentPoints)
end

function TalentTree_Main_UIBP:OnTalentInfoUpdate()
    self:UpdateLayers()
end

return TalentTree_Main_UIBP