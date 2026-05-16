---@class Breakthrough_ResultList_UIBP_C:UUserWidget
---@field BattleGenderUI_Gender UBattleGenderUI
---@field Breakthrough_Result_Num_1 Breakthrough_Result_Num_UIBP_C
---@field Breakthrough_Result_Num_2 Breakthrough_Result_Num_UIBP_C
---@field Breakthrough_Result_Num_3 Breakthrough_Result_Num_UIBP_C
---@field Breakthrough_Result_Num_4 Breakthrough_Result_Num_UIBP_C
---@field Breakthrough_Result_Num_5 Breakthrough_Result_Num_UIBP_C
---@field Breakthrough_Result_Num_6 Breakthrough_Result_Num_UIBP_C
---@field Breakthrough_Result_Num_7 Breakthrough_Result_Num_UIBP_C
---@field Button_AddFriend UButton
---@field Button_like UNewButton
---@field Button_More UButton
---@field CanvasPanel_PlayerName UCanvasPanel
---@field Common_Avatar Common_Avatar_C
---@field LikeEachotherNum UTextBlock
---@field likeNum UTextBlock
---@field text_alreadyLiked UTextBlock
---@field TextBlock_PlayerName UTextBlock
---@field WidgetSwitcher_nice UWidgetSwitcher
--Edit Below--
local Breakthrough_ResultList_UIBP = 
{ 
	bInitDoOnce = false;
	PlayerInfo = nil;
	TipsUI_BP = nil;
} 


function Breakthrough_ResultList_UIBP:Construct()
	self:LuaInit();
	
end



function Breakthrough_ResultList_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	self.Button_AddFriend.OnClicked:Add(self.Button_AddFriend_OnClicked, self);
	self.Button_More.OnPressed:Add(self.Button_More_OnPressed, self);
	self.Button_More.OnReleased:Add(self.Button_More_OnReleased, self);
	self.Button_like.OnClicked:Add(self.Button_like_OnClicked, self);

end

function Breakthrough_ResultList_UIBP:UpdateItem(PlayerState)
	self.PlayerState = PlayerState
    self:SetPlayersInfo()
end

function Breakthrough_ResultList_UIBP:SetPlayersInfo()
    self:SetBaseInfo()
	self:SetBattleInfo()
end

function Breakthrough_ResultList_UIBP:SetBaseInfo()
	local PlayerState = self.PlayerState
	local isSelf = self:isSelf()
	if isSelf then
		self.WidgetSwitcher_nice:SetVisibility(ESlateVisibility.Collapsed)
		self.Button_AddFriend:SetVisibility(ESlateVisibility.Collapsed)
	else
		self.WidgetSwitcher_nice:SetVisibility(ESlateVisibility.Visible)
		self.Button_AddFriend:SetVisibility(ESlateVisibility.Visible)
	end
	ugcprint("Breakthrough_ResultList_UIBP:SetBaseInfo".. tostring(PlayerState.UID))
	self.Common_Avatar:InitView(1, PlayerState.UID, PlayerState.IconURL, PlayerState.Gender, PlayerState.FrameLevel, PlayerState.PlayerLevel, true, isSelf);
	local sex = UGCPlayerStateSystem.GetPlayerPlatformGender(PlayerState.PlatformGender, PlayerState.UID)
	self.BattleGenderUI_Gender:SetGender(sex, tostring(PlayerState.UID))
	self.TextBlock_PlayerName:SetText(tostring(PlayerState.PlayerName))
end

function Breakthrough_ResultList_UIBP:isSelf()
	local playerstate = UGCGameSystem.GetLocalPlayerState()
	local UID = playerstate.UID
	if UID == self.PlayerState.UID then
		return true	
	end
	return false
end

function Breakthrough_ResultList_UIBP:SetBattleInfo()
	local Score = self.PlayerState.GameRecordData
	-- Debug log: 检查 GameTime 为 0 的问题
	print(string.format("[Breakthrough_ResultList_UIBP:SetBattleInfo] UID=%s, GameTime=%s, GameStartTime=%s", 
		tostring(self.PlayerState.UID), 
		tostring(Score.GameTime), 
		tostring(self.PlayerState.GameStartTime)))
	self.Breakthrough_Result_Num_1.TextBlock_DamageNum:SetText(tostring(math.floor(Score.TotalDamage)))
	self.Breakthrough_Result_Num_2.TextBlock_DamageNum:SetText(tostring(math.floor(Score.TotalCriticalHit)))
	self.Breakthrough_Result_Num_3.TextBlock_DamageNum:SetText(tostring(math.floor(Score.TotalMonsterKillByType.Monster)))
	self.Breakthrough_Result_Num_4.TextBlock_DamageNum:SetText(tostring(math.floor(Score.TotalMonsterKillByType.EliteMonster)))
	self.Breakthrough_Result_Num_5.TextBlock_DamageNum:SetText(tostring(math.floor(Score.TotalMonsterKillByType.Boss)))
	local time = self:TansformTime(Score.GameTime)
	print(string.format("[Breakthrough_ResultList_UIBP:SetBattleInfo] time=%s", tostring(time)))
	self.Breakthrough_Result_Num_6.TextBlock_DamageNum:SetText(time)
	self.Breakthrough_Result_Num_7.TextBlock_DamageNum:SetText(tostring(math.floor(Score.PlayerExp)))
	self:SetLikeInfo()
end

function Breakthrough_ResultList_UIBP:SetLikeInfo()
	if(self:isSelf())then
		return
	end
	local localPS = UGCGameSystem.GetLocalPlayerState()
	if not localPS then
		print("[Breakthrough_ResultList_UIBP:SetLikeInfo]localPS is nil")
		return
	end

	-- 未点赞
	if not localPS.GameRecordData.Likes[self.PlayerState.PlayerKey] then
		self.WidgetSwitcher_nice:SetActiveWidgetIndex(0)
		self.likeNum:SetText(tostring(self.PlayerState.GameRecordData.LikeNum))
	-- 已点赞
	elseif not localPS.GameRecordData.ReceivedLikes[self.PlayerState.PlayerKey] then
		self.WidgetSwitcher_nice:SetActiveWidgetIndex(2)
		self.text_alreadyLiked:SetText(tostring(self.PlayerState.GameRecordData.LikeNum))
	-- 互相点赞
	else
		self.WidgetSwitcher_nice:SetActiveWidgetIndex(1)
		self.LikeEachotherNum:SetText(tostring(self.PlayerState.GameRecordData.LikeNum))
	end
end

function Breakthrough_ResultList_UIBP:Button_AddFriend_OnClicked()
	local UID = self.PlayerState.UID
	UGCGameSystem.AddFriend(UID)
end

function Breakthrough_ResultList_UIBP:TansformTime(Time)
	local str = ""
	local Hour = math.floor(Time / 3600)
	local Mins = math.floor(Time / 60)
	local seds = Time % 60
	if Hour > 0 then
		str = str..tostring(Hour).."时"
	end
	if Mins > 0 then
		str = str..tostring(Mins).."分"
	end
	str = str..tostring(seds).."秒"
	return str
end

function Breakthrough_ResultList_UIBP:Button_like_OnClicked()
	local localPC = UGCGameSystem.GetLocalPlayerController()
	print("[Breakthrough_ResultList_UIBP:Button_like_OnClicked] PlayerKey is "..self.PlayerState.PlayerKey)
	UnrealNetwork.CallUnrealRPC(localPC, localPC, "RPC_Server_LikeOther", self.PlayerState.PlayerKey)
	return nil;
end


function Breakthrough_ResultList_UIBP:Button_More_OnPressed()
	local MoreData = {}
	local Data = {}
	Data.data = math.floor(self.PlayerState.GameRecordData.TotalMonsterKill)
	Data.title = "总击杀怪物"
	table.insert(MoreData,Data)
	BreakthroughManager:ShowMoreTips(MoreData)
	return nil;
end

function Breakthrough_ResultList_UIBP:Button_More_OnReleased()
	if BreakthroughManager.TipsUI_BP then
		BreakthroughManager.TipsUI_BP:SetVisibility(ESlateVisibility.Collapsed)
	end
	return nil;
end


return Breakthrough_ResultList_UIBP