---@class UGC_TeamPanel_BlueHp_UIBP_C:UUserWidget
---@field ProgressBar_HP1 UProgressBar
---@field ProgressBar_HP2 UProgressBar
---@field SizeBox_HP UCanvasPanel
---@field TextBlock_CurrentValue UTextBlock
---@field TextBlock_TotalValue UTextBlock
--Edit Below--
local UGC_TeamPanel_BlueHp_UIBP = { 
    bInitDoOnce = false,
    MaxMagic = 100,
    Magic = 100,
} 


function UGC_TeamPanel_BlueHp_UIBP:Construct()
    self:LuaInit()
    self:SetVisibility(ESlateVisibility.Collapsed)
end

function UGC_TeamPanel_BlueHp_UIBP:UpdateMagic()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn then
        self.Magic = math.floor(UGCAttributeSystem.GetGameAttributeValue(PlayerPawn, 'Magic'))
        self.MaxMagic = math.floor(UGCAttributeSystem.GetGameAttributeValue(PlayerPawn, 'MaxMagic'))
    end

    ugcprint("UGC_TeamPanel_BlueHp_UIBP:UpdateMagic Magic"..tostring(self.Magic))
    self.TextBlock_CurrentValue:SetText(tostring(self.Magic))
    self.TextBlock_TotalValue:SetText(tostring(self.MaxMagic))
    local Percent = self.Magic / self.MaxMagic
    self.ProgressBar_HP1:SetPercent(0)
    self.ProgressBar_HP2:SetPercent(Percent)
end

-- [Editor Generated Lua] function define Begin:
function UGC_TeamPanel_BlueHp_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	self.TextBlock_CurrentValue:BindingProperty("Text", self.TextBlock_CurrentValue_Text, self);
	self.TextBlock_TotalValue:BindingProperty("Text", self.TextBlock_TotalValue_Text, self);
	self.ProgressBar_HP2:BindingProperty("Percent", self.ProgressBar_HP2_Percent, self);
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
	-- [Editor Generated Lua] BindingEvent End;
end

function UGC_TeamPanel_BlueHp_UIBP:TextBlock_CurrentValue_Text(ReturnValue)
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn then
        self.Magic = math.floor(UGCAttributeSystem.GetGameAttributeValue(PlayerPawn, 'Magic'))
        return tostring(self.Magic)
    end
	return "100";
end

function UGC_TeamPanel_BlueHp_UIBP:TextBlock_TotalValue_Text(ReturnValue)
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn then
        self.MaxMagic = math.floor(UGCAttributeSystem.GetGameAttributeValue(PlayerPawn, 'MaxMagic'))
        return tostring(self.MaxMagic)
    end
	return "100";
end

function UGC_TeamPanel_BlueHp_UIBP:ProgressBar_HP2_Percent(ReturnValue)
    local Percent = self.Magic / self.MaxMagic
	return Percent;
end

-- [Editor Generated Lua] function define End;

return UGC_TeamPanel_BlueHp_UIBP