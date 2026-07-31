---@class UGC_Countdown_Popups_UIBP_C:UUserWidget
---@field Background UImage
---@field BackToLobbyBtn UButton
---@field BlockButton UButton
---@field Button_No UButton
---@field CanvasPanel_limit UCanvasPanel
---@field CoinRespawnButton UButton
---@field CoinRespawnName UTextBlock
---@field CountDownText UTextBlock
---@field CountDownTipNameText UTextBlock
---@field ExpandButton UGC_RevivalBut_Item_UIBP_C
---@field FreeRespawnButton UButton
---@field FreeRespawnName UTextBlock
---@field FreeRespawnNumText UTextBlock
---@field FreeRespawnZeroName UTextBlock
---@field FreeRespawnZeroText UTextBlock
---@field HorizontalBox_Quantity UHorizontalBox
---@field Image_13 UImage
---@field Image_Icon UImage
---@field Image_OasisCoin UImage
---@field NewButton_Close UButton
---@field RespawnBtn UButton
---@field RespawnPanel UCanvasPanel
---@field TextBlock_9 UTextBlock
---@field TextBlock_Consumption UTextBlock
---@field TextBlock_limitcurrent UTextBlock
---@field TextBlock_limitTotal UTextBlock
---@field TextBlock_OasisCoin UTextBlock
---@field TextBlock_ResurrectionTips UTextBlock
---@field WidgetSwitcher_Free UWidgetSwitcher
---@field WidgetSwitcher_Mode UWidgetSwitcher
---@field WidgetSwitcher_Style UWidgetSwitcher
--Edit Below--
local UGC_Countdown_Popups_UIBP = 
{ 
    bInitDoOnce = false;
    listen = false;
    VirtualItemManager = nil;
    bRequestedRespawn = false;
    bSetCoinInfoRegistered = false; -- 防止多次取消注册
} 

local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')

function UGC_Countdown_Popups_UIBP:Construct()
    if self.bInitDoOnce then
		return
	end

	self.bInitDoOnce = true
	self.NewButton_Close.OnClicked:Add(self.NewButton_Close_OnClicked, self)
	self.FreeRespawnButton.OnClicked:Add(self.OnFreeRespawnButtonClick, self)
	self.CoinRespawnButton.OnClicked:Add(self.OnCoinRespawnButtonClick, self)
	self.Button_No.OnClicked:Add(self.Button_No_OnClicked, self)
    self.ExpandButton.GetUpButton.OnClicked:Add(self.Expand, self)
    self.ExpandButton.RespawnButton.OnClicked:Add(self.Expand, self)
    self.RespawnBtn.OnClicked:Add(self.OnClickRespawnBtn, self)
    self.BackToLobbyBtn.OnClicked:Add(self.OnClickBackToLobbyBtn, self)
    self.VirtualItemManager = UGCGamePartSystem.VirtualItemManager.GetGlobalActor()
end

function UGC_Countdown_Popups_UIBP:NewButton_Close_OnClicked()
    self:Collapse()
end

function UGC_Countdown_Popups_UIBP:SetButtonState()
    local PC = UGCGameSystem.GetLocalPlayerController();
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(PC)
    local Config = PlayerState.RespawnConfig
    local freeTimes,totalTimes = Config.CurrentFreeReviveCount,Config.TotalFreeReviveCount
    
    local TotalPaidReviveCount = Config.TotalPaidReviveCount
    local CurrentPaidReviveCount = Config.CurrentPaidReviveCount
    self.TextBlock_limitcurrent:SetText(tostring(CurrentPaidReviveCount))
    self.TextBlock_limitTotal:SetText(tostring(TotalPaidReviveCount))
    if freeTimes == 0 and CurrentPaidReviveCount == 0 then
        self.WidgetSwitcher_Style:SetActiveWidgetIndex(1)
    else
        self.WidgetSwitcher_Style:SetActiveWidgetIndex(0)
        if freeTimes > 0 then
            self.WidgetSwitcher_Free:SetActiveWidgetIndex(0)
            self.FreeRespawnNumText:SetText(tostring(freeTimes).."/"..tostring(totalTimes))

        else
            self.WidgetSwitcher_Free:SetActiveWidgetIndex(1)
            self.FreeRespawnZeroText:SetText("0/"..tostring(totalTimes))
        end
    end
end

function UGC_Countdown_Popups_UIBP:Refresh()
    print("[UGC_Countdown_Popups_UIBP:Refresh]: Refresh")

    self.bRequestedRespawn = false

    --self:SetCoinInfo()
    --self:SetButtonState()

    --local PlayerState = UGCGameSystem.GetLocalPlayerState()
    --if PlayerState.AliveState == UGCGameData.AliveState.Dying then
    --    self.ExpandButton.Switcher:SetActiveWidgetIndex(0)
    --    self.FreeRespawnName:SetText("免费恢复")
    --    self.FreeRespawnZeroName:SetText("免费恢复")
    --    self.CoinRespawnName:SetText("恢复")
    --elseif PlayerState.AliveState == UGCGameData.AliveState.Dead then
    --    self.ExpandButton.Switcher:SetActiveWidgetIndex(1)
    --    self.FreeRespawnName:SetText("免费复活")
    --    self.FreeRespawnZeroName:SetText("免费复活")
    --    self.CoinRespawnName:SetText("复活")
    --end

    self.WidgetSwitcher_Mode:SetActiveWidgetIndex(0)
    self.CountDownTipNameText:SetVisibility(ESlateVisibility.Collapsed)
    
    self.VirtualItemManager.OnItemNumUpdatedDelegate:Add(self.SetCoinInfo, self) --潜规则：死亡时会暂时清空背包，这个时候有可能获取到的金币为0，所以这里需要注册物品改变的回调，当背包物品恢复时，重新设置金币数量
    self.bSetCoinInfoRegistered = true
end

function UGC_Countdown_Popups_UIBP:OnFreeRespawnButtonClick()
    self:RequestRespawn(true)
end

function UGC_Countdown_Popups_UIBP:RequestRespawn(bIsFree)
    if self.bRequestedRespawn then
        return
    end
    self.bRequestedRespawn = true
    local PC = UGCGameSystem.GetLocalPlayerController()
    UnrealNetwork.CallUnrealRPC(PC, PC, "RPC_Server_RequestRespawn", bIsFree)
end

function UGC_Countdown_Popups_UIBP:OnRespawn()
    if not self.bSetCoinInfoRegistered then
        return
    end
    self.VirtualItemManager.OnItemNumUpdatedDelegate:Remove(self.SetCoinInfo, self)
    self.bSetCoinInfoRegistered = false
end

function UGC_Countdown_Popups_UIBP:Close()
    self:SetVisibility(ESlateVisibility.Collapsed)
    self.VirtualItemManager.RemoveItemResultDelegate:Remove(self.RemoveItemResult,self)
    self:Destruct() 
end

function UGC_Countdown_Popups_UIBP:Collapse()
    self.BlockButton:SetVisibility(ESlateVisibility.Collapsed)
    self.Background:SetVisibility(ESlateVisibility.Collapsed)
    self.RespawnPanel:SetVisibility(ESlateVisibility.Collapsed)
    self.ExpandButton:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
end

function UGC_Countdown_Popups_UIBP:Expand()
    self.BlockButton:SetVisibility(ESlateVisibility.Visible)
    self.Background:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.RespawnPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.ExpandButton:SetVisibility(ESlateVisibility.Collapsed)
end

function UGC_Countdown_Popups_UIBP:RefreshCountDown(CountDown)
    if CountDown <= -1 then
        self.WidgetSwitcher_Mode:SetActiveWidgetIndex(1)
        --self.CountDownTipNameText:SetVisibility(ESlateVisibility.Collapsed)
        return
    end

    self.WidgetSwitcher_Mode:SetActiveWidgetIndex(0)
    --self.CountDownTipNameText:SetVisibility(ESlateVisibility.HitTestInvisible)
    self.CountDownText:SetText(string.format("%dS", CountDown))
end

function UGC_Countdown_Popups_UIBP:OnCoinRespawnButtonClick()
    local PC = UGCGameSystem.GetLocalPlayerController()
    local CoinID = self:GetCoinID()
    if self.VirtualItemManager == nil then
        return
    end
    local CoinNum = self.VirtualItemManager:GetItemNum(CoinID,PC)
    local ConsumeCoinNum = self:GetConsumeCoinNum()
    if CoinNum >= ConsumeCoinNum then
        local Config = UGCGameSystem.GetPlayerStateByPlayerController(PC).RespawnConfig
        local CurrentPaidReviveCount = Config.CurrentPaidReviveCount
        if CurrentPaidReviveCount > 0 then
            self:RequestRespawn(false)
        else
            UGCWidgetManagerSystem.ShowTipsUI("付费复活次数不足")
        end
    else
        UGCWidgetManagerSystem.ShowTipsUI("复活币不足")
    end
end

function UGC_Countdown_Popups_UIBP:SetCoinInfo()
    print("[UGC_Countdown_Popups_UIBP:SetCoinInfo]: Executed")
    local CoinID = self:GetCoinID()
    if self.VirtualItemManager == nil then
        print("[UGC_Countdown_Popups_UIBP:SetCoinInfo]: VirtualItemManager is nil")
        return
    end
    local CoinData = self.VirtualItemManager:GetItemData(CoinID)
    if not CoinData then
        print("[UGC_Countdown_Popups_UIBP:SetCoinInfo]: CoinData is nil")
        return
    end
    local CoinPath = CoinData.ItemIcon
    FuncUtil.SetImageWithPath(self.Image_Icon, CoinPath)
    FuncUtil.SetImageWithPath(self.Image_OasisCoin, CoinPath)
    local PC = UGCGameSystem.GetLocalPlayerController();
    local CoinNum = self.VirtualItemManager:GetItemNum(CoinID, PC)
    print("[UGC_Countdown_Popups_UIBP:SetCoinInfo]: CoinNum: " .. tostring(CoinNum))
    self.TextBlock_OasisCoin:SetText(tostring(CoinNum))
    print("[UGC_Countdown_Popups_UIBP:SetCoinInfo]: CoinNumSetDone")
    local ConsumeCoinNum = self:GetConsumeCoinNum()
    self.TextBlock_Consumption:SetText(tostring(ConsumeCoinNum))
end

function UGC_Countdown_Popups_UIBP:GetCoinID()
    local PC = UGCGameSystem.GetLocalPlayerController();
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(PC)
    local Config = PlayerState.RespawnConfig
    return Config.CurrencyID
end

function UGC_Countdown_Popups_UIBP:GetConsumeCoinNum()
    local PC = UGCGameSystem.GetLocalPlayerController();
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(PC)
    local Config = PlayerState.RespawnConfig
    return Config.Price
end

function UGC_Countdown_Popups_UIBP:Button_No_OnClicked()
    UGCWidgetManagerSystem.ShowTipsUI("免费复活次数已用完")
	return nil;
end

---@private
function UGC_Countdown_Popups_UIBP:OnClickRespawnBtn()
    GameplayUtils.Print("UGC_Countdown_Popups_UIBP.OnClickRespawnBtn")
    self:RequestRespawn(true)
end

---@private
function UGC_Countdown_Popups_UIBP:OnClickBackToLobbyBtn()
    GameplayUtils.Print("UGC_Countdown_Popups_UIBP.OnClickBackToLobbyBtn")
end

return UGC_Countdown_Popups_UIBP