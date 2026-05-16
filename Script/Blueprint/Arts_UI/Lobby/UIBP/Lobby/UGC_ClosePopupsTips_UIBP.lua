---@class UGC_ClosePopupsTips_UIBP_C:UUserWidget
---@field Button_Cancel UButton
---@field Button_Confirm UButton
---@field General_MessageBox_UIBP UGeneral_MessageBox_UIBP_C
---@field Image_1 UImage
---@field NewButton_Close UButton
---@field TextBlock_Tips UTextBlock
--Edit Below--

---@type UGC_ClosePopupsTips_UIBP_C
local UGC_ClosePopupsTips_UIBP = {}

function UGC_ClosePopupsTips_UIBP:Construct()
    self.NewButton_Close.OnClicked:Add(self.OnCloseClicked, self)
    self.Button_Cancel.OnClicked:Add(self.OnCancelClicked, self)
    self.Button_Confirm.OnClicked:Add(self.OnConfirmClicked, self)
end

function UGC_ClosePopupsTips_UIBP:Destruct()
    self.NewButton_Close.OnClicked:Remove(self.OnCloseClicked, self)
    self.Button_Cancel.OnClicked:Remove(self.OnCancelClicked, self)
    self.Button_Confirm.OnClicked:Remove(self.OnConfirmClicked, self)
end

function UGC_ClosePopupsTips_UIBP:OnOpen(Data)

end

function UGC_ClosePopupsTips_UIBP:OnClose()

end

function UGC_ClosePopupsTips_UIBP:OnUpdate(Data)

end

function UGC_ClosePopupsTips_UIBP:OnCloseClicked()
    LobbyFlow:Go(LobbyFlowState.LFS_Lobby)
end

function UGC_ClosePopupsTips_UIBP:OnCancelClicked()
    LobbyFlow:Go(LobbyFlowState.LFS_Lobby)
end

function UGC_ClosePopupsTips_UIBP:OnConfirmClicked()
    LobbyModel:ExitLobby()
end

return UGC_ClosePopupsTips_UIBP