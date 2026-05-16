---@class UGC_Game_Teleport_Main_UBP_C:UUserWidget
---@field CountDown UGC_Game_TeleportCountdownTips_UBP_C
---@field Notify UGC_Game_Teleport_EnterTips_UBP_C
---@field TeleportButton UGC_Game_Teleport_EnterBut_UBP_C
--Edit Below--
local UGC_Game_Teleport_Main_UBP = { bInitDoOnce = false } 

function UGC_Game_Teleport_Main_UBP:Construct()
	PortalManager.OnCountDownUpdate:Add(self.RefreshCountDown , self)

    self.TeleportButton.Button.OnClicked:Add(self.OnTeleportButtonClick, self)
end

function UGC_Game_Teleport_Main_UBP:Destruct()
    PortalManager.OnCountDownUpdate:Remove(self.RefreshCountDown, self)
end

function UGC_Game_Teleport_Main_UBP:RefreshCountDown(CountDown, InPortalPlayerKeys)
    self.CountDown:SetVisibility(ESlateVisibility.Collapsed)
    self.TeleportButton:SetVisibility(ESlateVisibility.Collapsed)
    self.Notify:SetVisibility(ESlateVisibility.Collapsed)

    if CountDown > 0 then
        local PC = UGCGameSystem.GetLocalPlayerController()
        self.CountDown:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.CountDown.CountDownText:SetText(CountDown)
        
        for _, PlayerKey in ipairs(InPortalPlayerKeys) do
            if UGCGameSystem.GetPlayerKeyByPlayerController(PC) == PlayerKey then
                self.CountDown.WaitingTipText:SetText("等待所有玩家到达传送门进入下一关")
                return
            end
        end

        self.TeleportButton:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.CountDown.WaitingTipText:SetText("传送门已出现，请尽快前往进入下一关卡")
    end
end

function UGC_Game_Teleport_Main_UBP:OnTeleportButtonClick()
    PortalManager:RequestTeleportToPortal()
end

return UGC_Game_Teleport_Main_UBP