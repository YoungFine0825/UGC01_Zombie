---@class UGC_TeammateStatus_Item_UIBP_C:UUserWidget
---@field Gender UBattleGenderUI
---@field NetworkStatusSwitcher UWidgetSwitcher
---@field PlayerNameText UTextBlock
---@field ReadyState USizeBox
---@field ReadyStateSwitcher UWidgetSwitcher
--Edit Below--
local UGC_TeammateStatus_Item_UIBP = 
{ 
    bInitDoOnce = false,
    PlayerState = nil
} 

function UGC_TeammateStatus_Item_UIBP:Construct()
	
end

function UGC_TeammateStatus_Item_UIBP:Destruct()
    if self.PlayerState ~= nil then
        self.PlayerState.ReadyStateUpdateDelegate:Remove(self.OnPlayerReadyStateUpdate, self)
        self.PlayerState.OnlineStateUpdateDelegate:Remove(self.OnPlayerOnlineStateUpdate, self)
    end
end

function UGC_TeammateStatus_Item_UIBP:Refresh(PlayerState)
    if PlayerState == nil then
        print("UGC_TeammateStatus_Item_UIBP:Refresh PlayerState is nil")
        return
    end

    self.PlayerState = PlayerState

    local UID = UGCGameSystem.GetUIDByPlayerState(self.PlayerState)
    local PlatformGender = self.PlayerState.PlatformGender
    local PlayerName = self.PlayerState.PlayerName

    self.Gender:SetGender(PlatformGender, UID)
    self.PlayerNameText:SetText(PlayerName)
    self.ReadyStateSwitcher:SetActiveWidgetIndex(self.PlayerState.bIsLobbyTeamLeader and 0 or 1)
        
    if self.PlayerState.bIsReadyInLobby then
        self.ReadyState:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self.ReadyState:SetVisibility(ESlateVisibility.Collapsed)
    end

    self.NetworkStatusSwitcher:SetActiveWidgetIndex(self.PlayerState.bIsOnline and 0 or 1)

    self.PlayerState.ReadyStateUpdateDelegate:Remove(self.OnPlayerReadyStateUpdate, self)
    self.PlayerState.OnlineStateUpdateDelegate:Remove(self.OnPlayerOnlineStateUpdate, self)
    self.PlayerState.ReadyStateUpdateDelegate:Add(self.OnPlayerReadyStateUpdate, self)
    self.PlayerState.OnlineStateUpdateDelegate:Add(self.OnPlayerOnlineStateUpdate, self)
end

function UGC_TeammateStatus_Item_UIBP:OnPlayerReadyStateUpdate()
    self.ReadyStateSwitcher:SetActiveWidgetIndex(self.PlayerState.bIsLobbyTeamLeader and 0 or 1)

    if self.PlayerState.bIsReadyInLobby then
        self.ReadyState:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self.ReadyState:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UGC_TeammateStatus_Item_UIBP:OnPlayerOnlineStateUpdate()
    self.NetworkStatusSwitcher:SetActiveWidgetIndex(self.PlayerState.bIsOnline and 0 or 1)
end

return UGC_TeammateStatus_Item_UIBP