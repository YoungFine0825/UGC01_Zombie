---@class UGC_ResultTab_UIBP_C:UUserWidget
---@field Button_Close UButton
---@field TextBlock_0 UTextBlock
---@field TextBlock_BossTitle UTextBlock
---@field TextBlock_EliteMonsterTitle UTextBlock
---@field TextBlock_ModeTitle UTextBlock
---@field TextBlock_Player UTextBlock
---@field TextBlock_TitleHeadshot UTextBlock
---@field TextBlock_TitleKill UTextBlock
---@field TextBlock_TitleScore UTextBlock
---@field UGC_ReuseList2 UGC_ReuseList2_C
--Edit Below--
local PromiseFuture = require("common.PromiseFuture")
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
local UGC_ResultTab_UIBP = { 
    bInitDoOnce = false,
    CurShow = false,
	PlayerInfoList = {},
	TeamMatePlayerStateList = {},
} 


function UGC_ResultTab_UIBP:Construct()
	self:LuaInit();
	
end

-- [Editor Generated Lua] function define Begin:
function UGC_ResultTab_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
	self.Button_Close.OnClicked:Add(self.Button_Close_OnClicked, self);
	self.UGC_ReuseList2.OnUpdateItem:Add(self.UGC_ReuseList2_OnUpdateItem, self);
	-- [Editor Generated Lua] BindingEvent End;

	-- 获取队友PlayerState
	PromiseFuture.New():Set(
        function (PromiseFuture)
            while true do
                local PS = UGCGameSystem.GetLocalPlayerState()
                if PS then
                    self:ReLoad(PS)
                    return
                end
                PromiseFuture:Yield()
            end
        end
    ):AutoResume(self, 0.2, 5)
    
end

function UGC_ResultTab_UIBP:Button_Close_OnClicked()
    self:ShowHideUI(false)
	return nil;
end

function UGC_ResultTab_UIBP:ShowHideUI(Show)
    self.CurShow = Show
    if Show then
		self.UGC_ReuseList2:Refresh()
		self:UpdateLevelInfo()
        self:SetVisibility(ESlateVisibility.Visible)
    else
        self:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UGC_ResultTab_UIBP:UpdateLevelInfo()
	ugcprint("UGC_ResultTab_UIBP:UpdateLevelInfo")
	--local level = UGCLevelFlowSystem.GetCurrentLevelStage(UGCGameSystem.GetLocalPlayerController()) or 1
	--local ModeID = UGCMultiMode.GetModeID()
	--local Name = UGCGameData.GetGameModeName(ModeID)
	--if Name then
	--	self.TextBlock_ModeTitle:SetText(string.format("%s--第%s关", Name, level))
	--end
end

function UGC_ResultTab_UIBP:ReLoad(PS)
	if PS == nil then
		return
	end
	PS:GetTeamMatePlayerStateList(self.TeamMatePlayerStateList, false)

	for i = 1, #self.TeamMatePlayerStateList do
		self.PlayerInfoList[i] = {}
		self.PlayerInfoList[i].Score = 0
		self.PlayerInfoList[i].Kill = 0
		self.PlayerInfoList[i].Headshot = 0
	end

	self.UGC_ReuseList2:Reload(#self.TeamMatePlayerStateList)
end

function UGC_ResultTab_UIBP:UGC_ReuseList2_OnUpdateItem(Widget, Idx)
	ugcprint("UGC_ResultTab_UIBP:UGC_ReuseList2_OnUpdateItem Index = "..Idx)
    if not Widget then
        return
    end
	---@type UGCPlayerState_C
    local PlayerState = self.TeamMatePlayerStateList[Idx + 1]
    if not PlayerState then
        ugcprint("UGC_ResultTab_UIBP:UGC_ReuseList2_OnUpdateItem not RankData")
        return
    end
	local PlayerInfo = self.PlayerInfoList[Idx + 1]
	if not PlayerInfo then
		ugcprint("UGC_ResultTab_UIBP:UGC_ReuseList2_OnUpdateItem not PlayerInfo")
        return
	end

	Widget.Common_Avatar:InitView(1, PlayerState.UID, PlayerState.IconURL, PlayerState.Gender, PlayerState.FrameLevel, PlayerState.PlayerLevel, true, false);
	local sex = UGCPlayerStateSystem.GetPlayerPlatformGender(PlayerState.PlatformGender, PlayerState.UID)
	Widget.BattleGenderUI_Sex:SetGender(sex, tostring(PlayerState.UID))
	Widget.TextBlock_Rank:SetText(tostring(Idx + 1))
	Widget.Text_PlayerName:SetText(tostring(PlayerState.PlayerName))

	local playerStat = PlayerState:GetInGameStatDataComponent()
	PlayerInfo.Score = playerStat:GetStatData(EPlayerInGameStatKeys.TotalScore,0)
	PlayerInfo.Kill = playerStat:GetStatData(EPlayerInGameStatKeys.TotalKill,0)
	PlayerInfo.Headshot = playerStat:GetStatData(EPlayerInGameStatKeys.TotalHeadshot,0)

	Widget.TextBlock_Score:SetText(tostring(PlayerInfo.Score))
	Widget.TextBlock_Kill:SetText(tostring(PlayerInfo.Kill))
	Widget.TextBlock_Headshot:SetText(tostring(PlayerInfo.Headshot))
	--Widget.TextBlock_EliteMonster:SetText(tostring(PlayerInfo.EliteMonsterKill))
	--Widget.TextBlock_Boss:SetText(tostring(PlayerInfo.BossKill))

	--Widget.Experience.TextBlock_experience:SetText(tostring(PlayerState.UGCPlayerLevel))
	--Widget.Experience.TextBlock_CurrentValue:SetText(tostring(PlayerState.PlayerExp))
	--local cfg = UGCGameData.GetLevelConfig(PlayerState.UGCPlayerLevel)
	--if cfg then
	--	Widget.Experience.TextBlock_TotalValue:SetText(tostring(cfg.Exp))
	--	local Percent = PlayerState.PlayerExp / cfg.Exp
	--	Widget.Experience.ProgressBar_Grade:SetPercent(Percent)
	--end
end

-- [Editor Generated Lua] function define End;

return UGC_ResultTab_UIBP