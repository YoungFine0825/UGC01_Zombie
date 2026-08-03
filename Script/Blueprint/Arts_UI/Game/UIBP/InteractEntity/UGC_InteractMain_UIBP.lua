---@class UGC_InteractMain_UIBP_C:UUserWidget
---@field Btn_Interact UButton
---@field BtnRoot UCanvasPanel
---@field Icon_Interact UImage
---@field Text_ButtonLabel UTextBlock
---@field Text_Tips_Main UTextBlock
---@field TipsRoot UCanvasPanel
--Edit Below--
local UGC_InteractMain_UIBP = { bInitDoOnce = false } 

--[==[ Construct-- Construct ]==]
function UGC_InteractMain_UIBP:Construct()
    self:LuaInit()
end


-- function UGC_InteractMain_UIBP:Tick(MyGeometry, InDeltaTime)

-- end


function UGC_InteractMain_UIBP:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true
    self.m_curInteractEntityID = 0
    self.Btn_Interact.OnClicked:Add(self.OnClickBtnInteract, self)
    GameplaySystem.EventSystem:Listen(GameplayEvents.Client.OnLocalPlayerUpdateInteractEntityWidget,self,self.OnUpdateInteractUI)
    ---@type UGCPlayerController_C
    local playerController = UGCGameSystem.GetLocalPlayerController()
    ---@type BP_PlayerInteractEntityComponent_C
    local playerInteractEntityComponent = playerController.PlayerInteractEntityComponent
    self:ShowEntityInteractUI(playerInteractEntityComponent:ClientGetCurFocusedEntityID())
    UGCWidgetManagerSystem.HideWidget(self)
end

function UGC_InteractMain_UIBP:Destruct()
    GameplaySystem.EventSystem:UnlistenAll(self)
end

---@param interactEntityID number
---@param playerInteractComp BP_PlayerInteractEntityComponent_C
function UGC_InteractMain_UIBP:OnUpdateInteractUI(interactEntityID,playerInteractComp)
    self:ShowEntityInteractUI(interactEntityID)
end

---@private
function UGC_InteractMain_UIBP:ShowEntityInteractUI(interactEntityInstanceID)
    self.m_curInteractEntityID = interactEntityInstanceID
    if interactEntityInstanceID <= 0 then
        self.BtnRoot:SetVisibility(ESlateVisibility.Collapsed)
        self.TipsRoot:SetVisibility(ESlateVisibility.Collapsed)
        return
    end
    self.BtnRoot:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.TipsRoot:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local interactEntityComp = GameplaySystem.InteractEntitySystem:GetInteractComponentByInstanceID(interactEntityInstanceID)
    if not interactEntityComp then
        GameplayUtils.Exception("UGC_InteractMain_UIBP.OnClickBtnInteract: 未找到可交互实体",interactEntityInstanceID,"!")
        return
    end
    self.Text_Tips_Main:SetText(interactEntityComp:ClientGetHUDTipsText())
    self.Text_ButtonLabel:SetText(interactEntityComp:ClientGetHUDInteractionBtnLabel())
end

---@private
function UGC_InteractMain_UIBP:OnClickBtnInteract()
    if self.m_curInteractEntityID <= 0 then
        GameplayUtils.Exception("UGC_InteractMain_UIBP.OnClickBtnInteract: 玩家点击交互按钮，但未进入交互区域！")
        return
    end
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Client.OnLocalPlayerInvokeInteraction,self.m_curInteractEntityID)
    --UGCWidgetManagerSystem.ShowTipsUI(table.concat({"UGC_InteractMain_UIBP.OnClickBtnInteract: 玩家点击交互按钮，发起与",self.m_curInteractEntityID,"交互！"}))
end

return UGC_InteractMain_UIBP