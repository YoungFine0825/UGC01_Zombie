---@class UGC_GameKilldata_Item_UIBP_C:UUserWidget
---@field Button_Select UButton
---@field TextBlock_1 UTextBlock
---@field TextBlock_BossValue UTextBlock
---@field TextBlock_NPCValue UTextBlock
---@field TextBlock_Pass UTextBlock
--Edit Below--
local PromiseFuture = require("common.PromiseFuture")
local UGC_GameKillData_Item_UIBP = { 
	bInitDoOnce = false, 
	ResultTabWeak = nil,
	HasToggleResultTab = false,
	HasCreatedResultTab = false, 
	TotalMonsterKill = 0,
	BossKill = 0,
	CurLevel = 1,
	TickWorldTime = 0,
} 


function UGC_GameKillData_Item_UIBP:Construct()
	self:LuaInit();
	self.bCanEverTick = true
end


function UGC_GameKillData_Item_UIBP:Tick(MyGeometry, InDeltaTime)
	self.TickWorldTime = self.TickWorldTime + InDeltaTime
	if self.TickWorldTime >= 1 then
		local WorldT = 0.0
		local PS = UGCGameSystem.GetLocalPlayerState()
		if PS then
			WorldT = UGCGameSystem.GetServerTimeSec() - PS.GameStartTime
		end
		
        -- if GameState then 
        --     WorldT = GameState:GetServerWorldTimeSeconds()
        -- end
		local Time = self:TansformTime(WorldT)
		ugcprint("UGC_GameKillData_Item_UIBP:Tick "..tostring(Time));
		self.TextBlock_1:SetText(tostring(Time))
		
		self.TickWorldTime = 0
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
					self:UpdateGameKill(PS.GameRecordData)
                    return
                end
                PromiseFuture:Yield()
            end
        end
    ):AutoResume(self, 0.2, 5)
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
				self.ResultTabWeak = UGCGameSystem.MakeWeakObjectPtr(UI);
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

function UGC_GameKillData_Item_UIBP:UpdateGameKill(GameRecordData)
	if GameRecordData then
		self.TotalMonsterKill = GameRecordData.TotalMonsterKill or 0
		if GameRecordData.TotalMonsterKillByType then
			self.BossKill = GameRecordData.TotalMonsterKillByType.Boss or 0
		end
		self.CurLevel = GameRecordData.CurrentStage or 1
	end
	self.TextBlock_BossValue:SetText(tostring(self.TotalMonsterKill))
	self.TextBlock_NPCValue:SetText(tostring(self.BossKill))
	self:UpdateLevel(self.CurLevel)
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

return UGC_GameKillData_Item_UIBP
