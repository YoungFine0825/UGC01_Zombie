---@class UGC_GameKilldata_Item_UIBP_C:UUserWidget
---@field Button_Select UButton
---@field Canvas_ScoreFloat UCanvasPanel
---@field TextBlock_1 UTextBlock
---@field TextBlock_BossValue UTextBlock
---@field TextBlock_NPCValue UTextBlock
---@field TextBlock_Pass UTextBlock
--Edit Below--
local PromiseFuture = require("common.PromiseFuture")
---@type UGC_GameKilldata_Item_UIBP_C
local UGC_GameKillData_Item_UIBP = { 
	bInitDoOnce = false, 
	ResultTabWeak = nil,
	HasToggleResultTab = false,
	HasCreatedResultTab = false, 
	TotalMonsterKill = 0,
	BossKill = 0,
	CurLevel = 1,
	TickWorldTime = 0,
	TotalScore = 0,
	ScoreFloatUIClass = nil
}

---@class UGC_GameKilldata_Item_UIBP_C.ScoreFloatTip
---@field weight UGC_ScoreFloat_Item_UIBP_C
---@field duration number
---@field playedTime number

---@type UGC_GameKilldata_Item_UIBP_C.ScoreFloatTip[]
UGC_GameKillData_Item_UIBP.m_freeScoreFloatTips = {}
---@type UGC_GameKilldata_Item_UIBP_C.ScoreFloatTip[]
UGC_GameKillData_Item_UIBP.m_playingScoreFloatTips = {}

function UGC_GameKillData_Item_UIBP:Construct()
	self:LuaInit()
	self.bCanEverTick = true
end

function UGC_GameKillData_Item_UIBP:Destruct()
	self.ScoreFloatUIClass = nil
	for k,v in pairs(self.m_freeScoreFloatTips) do
		v.weight = nil
	end
	for k,v in pairs(self.m_playingScoreFloatTips) do
		v.weight = nil
	end
	self.m_freeScoreFloatTips = {}
	self.m_playingScoreFloatTips = {}
	GameplaySystem.EventSystem:UnlistenAll(self)
end


function UGC_GameKillData_Item_UIBP:Tick(MyGeometry, InDeltaTime)
	if #self.m_playingScoreFloatTips > 0 then
		for i = #self.m_playingScoreFloatTips,1,-1 do
			local tip = self.m_playingScoreFloatTips[i]
			tip.playedTime = tip.playedTime + InDeltaTime
			if tip.playedTime >= tip.duration then
				if tip.weight then
					tip.weight:RemoveFromParent()
					tip.weight:SetVisibility(ESlateVisibility.Collapsed)
				end
				tip.content = nil
				tip.color = nil
				table.remove(self.m_playingScoreFloatTips,i)
				table.insert(self.m_freeScoreFloatTips,tip)
			end
		end
	end
end

-- [Editor Generated Lua] function define Begin:
function UGC_GameKillData_Item_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
	self.Button_Select.OnClicked:Add(self.Button_Select_OnClicked, self);
	-- [Editor Generated Lua] BindingEvent End;

	PromiseFuture.New():Set(
        function (PromiseFuture)
            while true do
                local PS = UGCGameSystem.GetLocalPlayerState()
                if PS then
                    PS.PlayerGameGameRecordDataDelegate:Add(self.UpdateGameKill, self)
					self:UpdateGameKill(PS)
                    return
                end
                PromiseFuture:Yield()
            end
        end
    ):AutoResume(self, 0.2, 5)

	GameplaySystem.EventSystem:Listen(GameplayEvents.Client.OnGameStateChanged,self,self.OnGameStateChanged)
	GameplaySystem.EventSystem:Listen(GameplayEvents.Client.OnRoundFlowChanged,self,self.OnRoundFlowChanged)
	GameplaySystem.EventSystem:Listen(GameplayEvents.Client.OnLocalPlayerGainScore,self,self.OnLocalPlayerGainScore)
	self.ScoreFloatUIClass = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Game/UIBP/Item/UGC_ScoreFloat_Item_UIBP.UGC_ScoreFloat_Item_UIBP_C'))
end
-- [Editor Generated Lua] function define End;

function UGC_GameKillData_Item_UIBP:CreateMainResultTab(bShow)
    ugcprint("UGC_GameKillData_Item_UIBP:CreateMainResultTab");

    if self:GetMainResultTab() == nil then
        local WidgetPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Game/UIBP/UGC_ResultTab_UIBP.UGC_ResultTab_UIBP_C')
		local UISlotName = 'UI.UISlot.MainUISlot_High'
		local ZOrder = 0;
		local AnchorData = UGCObjectUtility.NewStruct("AnchorData")
		local Anchors = UGCObjectUtility.NewStruct("Anchors")
		Anchors.Maximum = Vector2D.New(1.0, 1.0);
		Anchors.Minimum = Vector2D.New(0, 0);
		AnchorData.Anchors = Anchors
		
		UGCWidgetManagerSystem.AddChildToUISlotByPath(WidgetPath, UISlotName, ZOrder, AnchorData):Then(
			function (Result)
				local UI = Result:Get()
				self.HasCreatedResultTab = true;
				self.ResultTabWeak = UGCObjectUtility.MakeWeakObjectPtr(UI);
				self:ShowHideResultTab(bShow)
			end
		):Else(
			function ()
				ugcprint("UGC_GameKillData_Item_UIBP:CreateMainResultTab Failed")
			end
		)
    end
end

function UGC_GameKillData_Item_UIBP:Button_Select_OnClicked()
	ugcprint("UGC_GameKillData_Item_UIBP:Button_Select_OnClicked");
    self.HasToggleResultTab = true;
    local MainResultTab = self:GetMainResultTab();
    if MainResultTab then
        self:ShowHideResultTab(not MainResultTab.CurShow)
    else
        self:CreateMainResultTab(true);
    end
	return nil;
end

function UGC_GameKillData_Item_UIBP:ShowHideResultTab(Show)
    ugcprint("UGC_GameKillData_Item_UIBP:ShowHideResultTab Show:" .. tostring(Show))
	local MainResultTab = self:GetMainResultTab();
    if MainResultTab then
        MainResultTab:ShowHideUI(Show)
    elseif Show then
		self:CreateMainResultTab(true);
	end
end

function UGC_GameKillData_Item_UIBP:GetMainResultTab()
    if self.ResultTabWeak and self.ResultTabWeak:IsValid() then
        return self.ResultTabWeak:Get();
    end
    
    ugcprint("UGC_GameKillData_Item_UIBP:GetMainResultTab nil");
    return nil;
end

function UGC_GameKillData_Item_UIBP:UpdateLevel(level)
    ugcprint("UGC_GameKillData_Item_UIBP:UpdateLevel "..tostring(level))
	self.TextBlock_Pass:SetText(tostring(level))
end

---@param UGCPlayerState UGCPlayerState_C
function UGC_GameKillData_Item_UIBP:UpdateGameKill(UGCPlayerState)
	local playerStat = UGCPlayerState:GetInGameStatDataComponent()
	self.TotalKill = playerStat:GetStatData(EPlayerInGameStatKeys.TotalKill)
	self.CurLevel = 1
	self.TotalScore = playerStat:GetStatData(EPlayerInGameStatKeys.TotalScore)
	self.TextBlock_BossValue:SetText(tostring(self.TotalScore))
end

---@private
function UGC_GameKillData_Item_UIBP:OnGameStateChanged()
	--当前回合数
	local gameState = GameplaySystem.GetGameplayStateComponent()
	if gameState.GameStateInfo.GameState == EGameState.ReadyToStart then
		self:OnRoundFlowChanged()
	elseif gameState.GameStateInfo.GameState == EGameState.Gaming then
		self:OnRoundFlowChanged()
	end
end

---@private
function UGC_GameKillData_Item_UIBP:OnRoundFlowChanged()
	--当前回合数
	local gameState = GameplaySystem.GetGameplayStateComponent()
	local curRound = gameState.RoundFlowInfo.CurRoundNum
	self.TextBlock_Pass:SetText(tostring(curRound))
end

function UGC_GameKillData_Item_UIBP:TansformTime(Time)
	local str = ""
	local Hour = math.floor(Time / 3600)
	local Mins = math.floor(Time / 60)
	local Secs = math.floor(Time % 60)
	if Hour >= 10 then
		str = str..tostring(Hour)..":"
	elseif Hour > 0 then
		str = str.."0"..tostring(Hour)..":"
	else
		str = str.."00:"
	end

	if Mins > 10 then
		str = str..tostring(Mins)..":"
	elseif Mins > 0 then
		str = str.."0"..tostring(Mins)..":"
	else
		str = str.."00:"
	end

	if Secs < 10 then
		str = str.."0"..tostring(Secs)
	else
		str = str..tostring(Secs)
	end
	
	return str
end

---@private
function UGC_GameKillData_Item_UIBP:OnLocalPlayerGainScore(score,isHeadshot)
	if not self.ScoreFloatUIClass then return end
	local pc = UGCGameSystem.GetLocalPlayerController()
	---@type UGC_GameKilldata_Item_UIBP_C.ScoreFloatTip
	local scoreTip = nil
	if #self.m_freeScoreFloatTips > 0 then
		scoreTip = self.m_freeScoreFloatTips[1]
		table.remove(self.m_freeScoreFloatTips,1)
	else
		local newItem = UserWidget.NewWidgetObjectBP(pc, self.ScoreFloatUIClass)
		scoreTip = {
			weight = newItem,
			playedTime = 0,
			duration = 0,
		}
	end
	if scoreTip.weight == nil then
		return
	end
	---@type UGC_ScoreFloat_Item_UIBP_C
	local tipWeight = scoreTip.weight
	-- 挂到容器，落点在锚点附近 + 随机偏移，避免连发重叠
	local slot = self.Canvas_ScoreFloat:AddChildToCanvas(tipWeight)
	if slot then
		slot:SetAutoSize(true)
		slot:SetAlignment(Vector2D.New(0.5, 0.5))
		local rx = (math.random() - 0.5) * 30   -- 横向 ±60
		local ry = (math.random() - 0.5) * 40
		slot:SetPosition(Vector2D.New(rx, ry))
	end
	--
	tipWeight:SetVisibility(ESlateVisibility.HitTestInvisible)
	-- 文本与配色（爆头给个醒目色）
	tipWeight.Text_Score:SetText("+" .. tostring(score))
	if isHeadshot then
		tipWeight.Text_Score:SetColorAndOpacity(LinearColor.New(1.0, 0.85, 0.2, 1.0)) -- 金色
	else
		tipWeight.Text_Score:SetColorAndOpacity(LinearColor.New(1.0, 1.0, 1.0, 1.0))
	end

	-- 播动画，结束后销毁（用时长定时器，简单稳健）
	tipWeight:PlayAnimation(tipWeight.Anim_Float, 0, 1, 0, 1.0)
	scoreTip.duration = 1.1
	scoreTip.playedTime = 0
	table.insert(self.m_playingScoreFloatTips,scoreTip)
end

return UGC_GameKillData_Item_UIBP
