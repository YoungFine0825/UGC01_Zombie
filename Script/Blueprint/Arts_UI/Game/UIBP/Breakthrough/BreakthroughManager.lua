
---@type UUserWidget
UserWidget = UserWidget == nil and nil or UserWidget

BreakthroughManager = BreakthroughManager or 
{   
    WidgetPath = {
        RespawnUIPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Game/UIBP/Breakthrough/UGC_Countdown_Popups_UIBP.UGC_Countdown_Popups_UIBP_C'),
        ResultUIPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Game/UIBP/Breakthrough/Breakthrough_Result_UIBP.Breakthrough_Result_UIBP_C'),
        TipsUIPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Game/UIBP/Breakthrough/UGC_Result_MoreTips_UIBP.UGC_Result_MoreTips_UIBP_C'),
    },
    ResultPlayerState = {}
}

function BreakthroughManager:OpenRespawnUI(ModeID)
    ugcprint("BreakthroughManager:OpenRespawnUI"..tostring(ModeID))
    if self:CheckModeID(ModeID) then
        if self.RespawnUI then
            self.RespawnUI:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else
            print("[BreakthroughManager:OpenRespawnUI]: OpenRespawnUI")
            self.RespawnUI = self:OpenMainUI(self.WidgetPath.RespawnUIPath)
            local AnchorData = UGCObjectUtility.NewStruct("AnchorData")
            local Anchors = UGCObjectUtility.NewStruct("Anchors");
            Anchors.Minimum = Vector2D.New(0, 0);
            Anchors.Maximum = Vector2D.New(1, 1);
            AnchorData.Anchors = Anchors;
            UGCWidgetManagerSystem.AddChildToUISlotByWidget(self.RespawnUI,"UI.UISlot.MainUISlot_High", 10, AnchorData)
        end
        print("[BreakthroughManager:OpenRespawnUI]: OpenRespawnUIDone")
        self.RespawnUI:Refresh()
    end
end

function BreakthroughManager:RefreshRespawnUICountDown(CountDown)
    if self.RespawnUI == nil or self.RespawnUI:GetVisibility() == ESlateVisibility.Collapsed then
        return
    end

    self.RespawnUI:RefreshCountDown(CountDown)
end

function BreakthroughManager:CloseRespawnUI()
    if self.RespawnUI == nil then
        return
    end
    self.RespawnUI:OnRespawn()
    self.RespawnUI:SetVisibility(ESlateVisibility.Collapsed)
end

function BreakthroughManager:ShowMoreTips(MoreData)
    if self.TipsUI_BP then
        self.TipsUI_BP:LuaInit()
        self.TipsUI_BP:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.TipsUI_BP = self:OpenMainUI(self.WidgetPath.TipsUIPath)
    end
    local AnchorData = UGCObjectUtility.NewStruct("AnchorData")
    local Anchors = UGCObjectUtility.NewStruct("Anchors");
    Anchors.Minimum = Vector2D.New(0, 0);
    Anchors.Maximum = Vector2D.New(1, 1);
    AnchorData.Anchors = Anchors;
    UGCWidgetManagerSystem.AddChildToUISlotByWidget(self.TipsUI_BP,"UI.UISlot.MainUISlot_High", 50, AnchorData)
    self.TipsUI_BP:SetTips(MoreData)

end

function BreakthroughManager:OpenBattleResultUI(ModeID,State,IsShowUnlock)
    ugcprint("BreakthroughManager:OpenBattleResultUI"..tostring(ModeID)..tostring(State)..tostring(IsShowUnlock))
    if self:CheckModeID(ModeID) then
        if self.Battle_MainUI_BP then
            self.Battle_MainUI_BP:LuaInit()
            self.Battle_MainUI_BP:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else
            self.Battle_MainUI_BP = self:OpenMainUI(self.WidgetPath.ResultUIPath) 
        end
        local AnchorData = UGCObjectUtility.NewStruct("AnchorData")
        local Anchors = UGCObjectUtility.NewStruct("Anchors");
        Anchors.Minimum = Vector2D.New(0, 0);
        Anchors.Maximum = Vector2D.New(1, 1);
        AnchorData.Anchors = Anchors;
        UGCWidgetManagerSystem.AddChildToUISlotByWidget(self.Battle_MainUI_BP,"UI.UISlot.MainUISlot_High", 10, AnchorData)
        self.Battle_MainUI_BP:SetPlayerData(ModeID,State,IsShowUnlock)
    end
end

function BreakthroughManager:RefreshBattleResultUI()
    if self.Battle_MainUI_BP then
        self.Battle_MainUI_BP:RefreshPlayerInfo()
    else
        ugcprint("BreakthroughManager:RefreshBattleResultUI: Battle_MainUI_BP is nil")
    end
    
end

function BreakthroughManager:CheckModeID(ModeID)
    local GameModeConfigTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCGameModeConfig.UGCGameModeConfig'))
    for _, GameModeConfig in pairs(GameModeConfigTable) do
        if GameModeConfig.ModeID == ModeID then
            return true
        end
    end
    return false
end

function BreakthroughManager:OpenMainUI(Path)
    local pc = UGCGameSystem.GetLocalPlayerController();
    local MainUI = UGCObjectUtility.LoadClass(Path)
    local MainUI_BP = UserWidget.NewWidgetObjectBP(pc,MainUI);
    return MainUI_BP
end

function BreakthroughManager:AddOrUpdateResultPlayerState(InPlayerState)
    print("[BreakthroughManager:AddOrUpdateResultPlayerState]: AddOrUpdateResultPlayerState : " .. InPlayerState.PlayerKey)
    for _, PlayerState in pairs(self.ResultPlayerState) do
        if PlayerState.UID == InPlayerState.UID then
            return
        end
    end
    table.insert(self.ResultPlayerState, InPlayerState)
end

return BreakthroughManager