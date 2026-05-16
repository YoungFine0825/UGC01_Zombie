---@class UGC_Equip_Tips_UIBP_C:UUserWidget
---@field Button_Close UButton
---@field CanvasPanel_PropsDetails_1 UCanvasPanel
---@field CanvasPanel_PropsDetails_2 UCanvasPanel
---@field CanvasPanel_WepSlot UCanvasPanel
---@field NewButton_WepCompare UNewButton
---@field Text_WeaponnnName UTextBlock
---@field Text_WeaponnnName2 UTextBlock
---@field WidgetSwitcher_WepCompare UWidgetSwitcher
--Edit Below--
local UGC_Equip_Tips_UIBP = 
{ 
    bInitDoOnce = false;
    InnerTipsWidgetPath = "WidgetBlueprint'/Game/UGC/UITemplate/Asset/Backpack/Arts_UI/UIBP/Equip/Depot_PropsDetails_Tips_UIBP.Depot_PropsDetails_Tips_UIBP_C'", --内部tips蓝图路径
    TipsWidget1 = nil;
    TipsWidget2 = nil;
    data1 = nil;
    data2 = nil;
} 


function UGC_Equip_Tips_UIBP:Construct()
	self:LuaInit();
	
end
---data = {ItemDefineID,ItemID,ItemCount}ItemID不可为空   
function UGC_Equip_Tips_UIBP:SetData(data1,data2)
    self.data1 = data1
    self.data2 = data2
    local pc = UGCGameSystem.GetLocalPlayerController();
    local TipsWidgetClass = UGCObjectUtility.LoadClass(self.InnerTipsWidgetPath)
    if self.TipsWidget1 == nil or not UGCObjectUtility.IsObjectValid(self.TipsWidget1) then
        self.TipsWidget1 = UserWidget.NewWidgetObjectBP(pc,TipsWidgetClass);
        self.CanvasPanel_PropsDetails_1:AddChildToCanvas(self.TipsWidget1) 
    end
    self.CanvasPanel_PropsDetails_1:SetVisibility(ESlateVisibility.Collapsed)
    if self.TipsWidget2 == nil or not UGCObjectUtility.IsObjectValid(self.TipsWidget2) then
        self.TipsWidget2 = UserWidget.NewWidgetObjectBP(pc,TipsWidgetClass);
        self.CanvasPanel_PropsDetails_2:AddChildToCanvas(self.TipsWidget2)
    end
    self.CanvasPanel_PropsDetails_2:SetVisibility(ESlateVisibility.Collapsed)
    log_tree("UGC_Equip_Tips_UIBP:SetData ",totable(data1))
    log_tree("UGC_Equip_Tips_UIBP:SetData ",totable(data2))

    if self:Checkdata(data1) and self:Checkdata(data2) then
        ugcprint("data1 and data2 is not empty")
        if self:CheckSelectWeapon() == -1 then
            self.NewButton_WepCompare:SetVisibility(ESlateVisibility.Collapsed)
        else
            self.NewButton_WepCompare:SetVisibility(ESlateVisibility.Visible)
            if self:CheckSelectWeapon() ==  1 then
                self.WidgetSwitcher_WepCompare:SetActiveWidgetIndex(0)
            else
                self.WidgetSwitcher_WepCompare:SetActiveWidgetIndex(1)
            end
        end
        self.CanvasPanel_PropsDetails_1:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.TipsWidget1:SetData(data1)
        self.CanvasPanel_PropsDetails_2:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.TipsWidget2:SetData(data2)
    else
        self.NewButton_WepCompare:SetVisibility(ESlateVisibility.Collapsed)
        if self:Checkdata(data1) then
            self.CanvasPanel_PropsDetails_2:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            self.TipsWidget2:SetData(data1)
        elseif self:Checkdata(data2) then
            self.CanvasPanel_PropsDetails_2:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            self.TipsWidget2:SetData(data2)
        end
    end
end

function UGC_Equip_Tips_UIBP:Checkdata(data)
    if data == nil or isemptytable(data) then
        return false
    else
        return true
    end  
end

function UGC_Equip_Tips_UIBP:CheckSelectWeapon()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    local EquipDefineID1 = UGCBackpackSystemV2.GetEquippedItemBySlotName(PlayerPawn,"EquipmentSlot.Core.MainSlot1");
    local EquipDefineID2 = UGCBackpackSystemV2.GetEquippedItemBySlotName(PlayerPawn, "EquipmentSlot.Core.MainSlot2");
    if not self:Checkdata(self.data1) then
        return -1
    end
    local ItemID1 = self.data1[1].ItemID
    if EquipDefineID1 ~= nil and EquipDefineID1.TypeSpecificID == ItemID1 then
        return 1
    elseif EquipDefineID2 ~= nil and EquipDefineID2.TypeSpecificID == ItemID1 then
        return 2
    else
        return -1
    end
end

function UGC_Equip_Tips_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	self.Button_Close.OnClicked:Add(self.Button_Close_OnClicked, self);
	self.NewButton_WepCompare.OnClicked:Add(self.NewButton_WepCompare_OnClicked, self);
	
end

function UGC_Equip_Tips_UIBP:Button_Close_OnClicked()
    self:SetVisibility(ESlateVisibility.Collapsed)
	return nil;
end

function UGC_Equip_Tips_UIBP:NewButton_WepCompare_OnClicked()
    log_tree("UGC_Equip_Tips_UIBP:NewButton_WepCompare_OnClicked ",totable(self.data1))
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if self:CheckSelectWeapon() == 1 then
        local EquipDefineID2 = UGCBackpackSystemV2.GetEquippedItemBySlotName(PlayerPawn, "EquipmentSlot.Core.MainSlot2");
        if EquipDefineID2 ~= nil and EquipDefineID2.TypeSpecificID ~= 0 then
            UGCBackpackSystemV2.ClearEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI)
            --ShopV2Manager:ClearEquipSlotSelected();
            self.TipsWidget1:SetData({{ItemDefineID=EquipDefineID2, ItemID=EquipDefineID2.TypespecificID}})
            self.data1 = {{ItemDefineID=EquipDefineID2, ItemID=EquipDefineID2.TypespecificID}}

            local SlotName = "EquipmentSlot.Core.MainSlot1"
            UGCBackpackSystemV2.ShowEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI, SlotName)

            --ShopV2Manager:ShowEquipSlotSelected("EquipmentSlot.Core.MainSlot2");
            self.WidgetSwitcher_WepCompare:SetActiveWidgetIndex(1)
        else
            UGCWidgetManagerSystem.ShowTipsUI("副武器未装备")
            return
        end
    elseif self:CheckSelectWeapon() == 2 then
        local EquipDefineID1 = UGCBackpackSystemV2.GetEquippedItemBySlotName(PlayerPawn, "EquipmentSlot.Core.MainSlot1");
        if EquipDefineID1 ~= nil and EquipDefineID1.TypeSpecificID ~= 0 then
            UGCBackpackSystemV2.ClearEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI)
            --ShopV2Manager:ClearEquipSlotSelected();
            self.TipsWidget1:SetData({{ItemDefineID=EquipDefineID1, ItemID=EquipDefineID1.TypespecificID}})
            self.data1 = {{ItemDefineID=EquipDefineID1, ItemID=EquipDefineID1.TypespecificID}}

            local SlotName = "EquipmentSlot.Core.MainSlot1"
            UGCBackpackSystemV2.ShowEquipSlotSelected(ShopV2Manager.MainUI.EquipmentUI, SlotName)

            --ShopV2Manager:ShowEquipSlotSelected("EquipmentSlot.Core.MainSlot1");
            self.WidgetSwitcher_WepCompare:SetActiveWidgetIndex(0)
        else
            UGCWidgetManagerSystem.ShowTipsUI("主武器未装备")
            return
        end

    end
	return nil;
end


return UGC_Equip_Tips_UIBP