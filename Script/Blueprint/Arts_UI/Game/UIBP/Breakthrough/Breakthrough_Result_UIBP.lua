---@class Breakthrough_Result_UIBP_C:UUserWidget
---@field BattleDetail UCanvasPanel
---@field Button_Back UButton
---@field Button_Share UButton
---@field CanvasPanel_DataList UCanvasPanel
---@field HorizontalBox_2 UHorizontalBox
---@field Image_Logo UImage
---@field Rank UCanvasPanel
---@field Text_BackNumber UTextBlock
---@field TextBlock_0 UTextBlock
---@field TextBlock_Difficulty UTextBlock
---@field TextBlock_GameMode UTextBlock
---@field TextBlock_Result UTextBlock
---@field TextBlock_UnlockMap UTextBlock
---@field TextBlock_UnlockTitle UTextBlock
---@field UGC_ReuseList2_Player UGC_ReuseList2_C
---@field WaitingNode UCanvasPanel
---@field WidgetSwitcher_Rank UWidgetSwitcher
--Edit Below--
local Breakthrough_Result_UIBP = { bInitDoOnce = false } 



function Breakthrough_Result_UIBP:Construct()
	self:LuaInit();
end


function Breakthrough_Result_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	self.Button_Back.OnClicked:Add(self.Button_Back_OnClicked, self);
	self.Button_Share.OnClicked:Add(self.Button_Share_OnClicked, self);
	self.UGC_ReuseList2_Player.OnUpdateItem:Add(self.UGC_ReuseList2_Player_OnUpdateItem, self);
	
end
function Breakthrough_Result_UIBP:SetPlayerData(ModeID,State,IsShowUnlock)
	self.ModeID = ModeID
	self.State = State
    self.IsShowUnlock = IsShowUnlock
    self:SetModeName()
    self:SetState()
    self:SetBackButtonCountDown()
    self:SetPlayerInfo()
end

function Breakthrough_Result_UIBP:SetPlayerInfo()
    if #BreakthroughManager.ResultPlayerState ~= 0 then
        self.WaitingNode:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.WaitingNode:SetVisibility(ESlateVisibility.Visible)
    end
    self.UGC_ReuseList2_Player:Reload(#BreakthroughManager.ResultPlayerState)
end

function Breakthrough_Result_UIBP:RefreshPlayerInfo()
    self.UGC_ReuseList2_Player:Reload(#BreakthroughManager.ResultPlayerState)
    print("[Breakthrough_Result_UIBP:RefreshPlayerInfo]:Reloaded")
end

function Breakthrough_Result_UIBP:SetModeName()
    local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
	local Name = UGCGameData.GetGameModeName(self.ModeID)
    self.TextBlock_GameMode:SetText(Name)
end

function Breakthrough_Result_UIBP:SetState()
    self.TextBlock_UnlockMap:SetVisibility(ESlateVisibility.Collapsed)
    self.TextBlock_UnlockTitle:SetVisibility(ESlateVisibility.Collapsed)
    self.TextBlock_Difficulty:SetVisibility(ESlateVisibility.Collapsed)
    if not self.State then
        self:SetDefeatState()
    else
        self:SetWinState()
    end
end

function Breakthrough_Result_UIBP:SetUnlockLevelName()

    local NextModeID = 0

    local GameModeConfigTable = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCGameModeConfig.UGCGameModeConfig'))

    local CurrentConfig = nil
    for _, config in pairs(GameModeConfigTable) do
        if config.ModeID == self.ModeID then
            CurrentConfig = config
            break
        end
    end
    
    if not CurrentConfig or not CurrentConfig.UnlockMode then
        return
    end

    for _, unlockID in ipairs(CurrentConfig.UnlockMode) do
        NextModeID = unlockID
    end

    if NextModeID ~= 0 then
        local Name = ""
        local NextDefficulty = ""
        for _, GameModeConfig in pairs(GameModeConfigTable) do
            if GameModeConfig.ModeID == NextModeID then
                NextDefficulty = GameModeConfig.Difficulty
                Name = GameModeConfig.ModeName
                break
            end
        end
        self.TextBlock_UnlockMap:SetText(tostring(Name))
        self.TextBlock_Difficulty:SetText(tostring(NextDefficulty))
        self.TextBlock_UnlockTitle:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.TextBlock_UnlockMap:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.TextBlock_Difficulty:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

function Breakthrough_Result_UIBP:SetBackButtonCountDown()
	local CountDownTime = 121
	local SetCountDown = function()
		CountDownTime =  CountDownTime - 1
		if CountDownTime > 0 then
			self.Text_BackNumber:SetText(tostring(CountDownTime))
		else
			self:ReturnToLobby()
            self:CloseUI()  
		end
	end
	UGCTimerUtility.CreateLuaTimer(1,SetCountDown,true,"Result_CountDownTime",0)
end

function Breakthrough_Result_UIBP:SetWinState()
    self.WidgetSwitcher_Rank:SetActiveWidgetIndex(0)
    if self.IsShowUnlock then
        self:SetUnlockLevelName()
    end
end

function Breakthrough_Result_UIBP:SetDefeatState()
    self.WidgetSwitcher_Rank:SetActiveWidgetIndex(1) 
end

function Breakthrough_Result_UIBP:Button_Back_OnClicked()
    self:ReturnToLobby()
	self:CloseUI()
	return nil;
end


function Breakthrough_Result_UIBP:ReturnToLobby()
    UGCMultiMode.RequestMatch(1001, nil, self)
	return nil;
end

function Breakthrough_Result_UIBP:CloseUI()
	self:SetVisibility(ESlateVisibility.Collapsed)
    UGCTimerUtility.RemoveLuaTimerByName("Result_CountDownTime")
end

function Breakthrough_Result_UIBP:Button_Share_OnClicked()
    local CloseCallBack = function ()
        self.HorizontalBox_2:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.Image_Logo:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.Button_Back:SetVisibility(ESlateVisibility.Visible)
        self.Button_Share:SetVisibility(ESlateVisibility.Visible)
    end
    self.HorizontalBox_2:SetVisibility(ESlateVisibility.Collapsed)
    self.Image_Logo:SetVisibility(ESlateVisibility.Collapsed)
    self.Button_Back:SetVisibility(ESlateVisibility.Collapsed)
    self.Button_Share:SetVisibility(ESlateVisibility.Collapsed)
    UGCWidgetManagerSystem.Share(CloseCallBack)
	return nil;
end

function Breakthrough_Result_UIBP:GetAllPlayerInfo()
    local AllPlayerStates =UGCTeamSystem.GetAllTeammatePlayerState(false)
    ugcprint("[Breakthrough_Result_UIBP:GetAllPlayerInfo] : ".. tostring(#AllPlayerStates))
    return AllPlayerStates
end

function Breakthrough_Result_UIBP:UGC_ReuseList2_Player_OnUpdateItem(Widget, Idx)
    -- local PlayerInfos = self:GetAllPlayerInfo()
    ugcprint("[Breakthrough_Result_UIBP:UGC_ReuseList2_Player_OnUpdateItem] : ".. tostring(Idx))
    Widget:UpdateItem(BreakthroughManager.ResultPlayerState[Idx+1])
end


return Breakthrough_Result_UIBP