---@class UGC_Avator_Item_UIBP_C:UUserWidget
---@field Common_Avatar_BP UCommon_Avatar_BP_C
---@field ProgressBar_Exp UProgressBar
---@field TextBlock_NowExp UTextBlock
---@field TextBlock_PlayerLevel UTextBlock
---@field TextBlock_PlayerName UTextBlock
---@field TextBlock_TargetExp UTextBlock
---@field WidgetSwitcher_Gendar UWidgetSwitcher
--Edit Below--

---@type UGC_Avator_Item_UIBP_C
local UGC_Avator_Item_UIBP = {}


function UGC_Avator_Item_UIBP:Construct()
	
end

function UGC_Avator_Item_UIBP:Destruct()

end

function UGC_Avator_Item_UIBP:OnUpdate(Data)
    self.Data = Data

    ---@type FPlayerAccountInfo
    local PlayerAccountInfo = self.Data.PlayerAccountInfo

    self.TextBlock_PlayerName:SetText(PlayerAccountInfo.PlayerName or "nil")
    self.TextBlock_PlayerLevel:SetText("Lv. " .. self.Data.Level or 0)

    self.TextBlock_NowExp:SetText(tostring(self.Data.NowExp or 2))
    self.TextBlock_TargetExp:SetText(tostring(self.Data.TargetExp or 10))
    self.ProgressBar_Exp:SetPercent(self.Data.ExpRatio or 0.2)

    -- 刷新头像
    self.Common_Avatar_BP:InitView(1, PlayerAccountInfo.UID, PlayerAccountInfo.IconURL, PlayerAccountInfo.Gender,
            PlayerAccountInfo.SegmentLevel, PlayerAccountInfo.PlayerLevel, true, true)
end

return UGC_Avator_Item_UIBP