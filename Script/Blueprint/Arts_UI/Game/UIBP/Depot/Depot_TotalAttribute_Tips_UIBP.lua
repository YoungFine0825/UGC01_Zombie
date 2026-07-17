---@class Depot_TotalAttribute_Tips_UIBP_C:UUserWidget
---@field Button_Mask UButton
---@field Image_Icon UImage
---@field TextBlock_Num UTextBlock
---@field VerticalBox_Attribute_Number UVerticalBox
--Edit Below--
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
local EquipmentAffixManager = UGCGameSystem.UGCRequire("Script.Blueprint.Affix.EquipmentAffixManager")
local Depot_TotalAttribute_Tips_UIBP = 
{ 
    bInitDoOnce = false;
    Attribute_Number_WidgetPath = 'Asset/Blueprint/Arts_UI/Game/UIBP/Equip/Equip_AttributeNum_UIBP.Equip_AttributeNum_UIBP_C',
} 


function Depot_TotalAttribute_Tips_UIBP:Construct()
	self:LuaInit();
end

function Depot_TotalAttribute_Tips_UIBP:Destruct()
    local PC = UGCGameSystem.GetLocalPlayerController();
	local BackpackComp = UGCBackpackSystemV2.GetBackpackComponentV2(PC);
	BackpackComp.ItemEquippedChangeDelegate:Remove(self.RefreshData, self)
end

function Depot_TotalAttribute_Tips_UIBP:RefreshData()
    local TotalBaseData = self:GetTotalAttributeData()
    self.VerticalBox_Attribute_Number:ClearChildren()
    if #TotalBaseData == 0 then
        return
    end
    for i,data in ipairs(TotalBaseData) do
        self:Add_Number_Widget(data)
    end
end

function Depot_TotalAttribute_Tips_UIBP:Add_Number_Widget(data)
    local pc = UGCGameSystem.GetLocalPlayerController();
    local Number_WidgetUI_Class = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath(self.Attribute_Number_WidgetPath))
    local Number_WidgetUI = UserWidget.NewWidgetObjectBP(pc,Number_WidgetUI_Class)
    
    if Number_WidgetUI  then
        self.VerticalBox_Attribute_Number:AddChildToVerticalBox(Number_WidgetUI)
        if Number_WidgetUI.Text_AttributeNumeric then
            UIUtil.SetSlateHexColor(Number_WidgetUI.Text_AttributeNumeric,"cbcbceff")
            Number_WidgetUI.Text_AttributeNumeric:SetText(data.Modifier)
        end
        if Number_WidgetUI.TextBlock_Title then
            UIUtil.SetSlateHexColor(Number_WidgetUI.TextBlock_Title,"cbcbceff")
            Number_WidgetUI.TextBlock_Title:SetText(data.Description) 
        end
        if Number_WidgetUI.Border_Color then
            Number_WidgetUI.Border_Color:SetVisibility(ESlateVisibility.Collapsed)
        end
    end 
end


function Depot_TotalAttribute_Tips_UIBP:GetTotalAttributeData()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if not PlayerPawn then
        return {}
    end
    local TotalBaseData = {}
    -- local SkillData = {}
    local TotalAttributeShowConfig = UGCGameSystem.GetTableData(UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCTotalAttributeShowConfig.UGCTotalAttributeShowConfig'))
    for _, Config in pairs(TotalAttributeShowConfig) do
        if Config.IsShow then
            local data = {}
            data.Value = 0
            local EquipSlots = UGCBackpackSystemV2.GetEquipSlots(PlayerPawn)
            for index, value in ipairs(EquipSlots) do
                local EquipDefineID = UGCBackpackSystemV2.GetEquippedItemBySlotName(PlayerPawn, value);
                if value ~= "EquipmentSlot.Core.MainSlot1" and value ~= "EquipmentSlot.Core.MainSlot2" then
                    if EquipDefineID ~= nil or EquipDefineID.TypeSpecificID ~= 0 then
                        local Res = self:GetAttributeData(EquipDefineID, Config.AttributeName)
                        data.Value = data.Value + Res.Value
                    else
                        ugcprint(" Depot_TotalAttribute_Tips_UIBP:EquipDefineID error")
                    end
                end
            end
            --枪的按局内局外区分，局外优先第一把，局内当前装备的，没有装备然后再第一把
            local ModeID = UGCMultiMode.GetModeID()
            if ModeID == 1001 then --局外
                local Res = self:GetWeaponAttribute(Config.AttributeName)
                data.Value = data.Value + Res.Value
            else --局内
                local PlayerPawn1 = UGCGameSystem.GetLocalPlayerPawn()
                local slot = UGCWeaponManagerSystem.GetCurrentWeaponSlot(PlayerPawn1)
                if slot == nil then
                    local Res = self:GetWeaponAttribute(Config.AttributeName)
                    data.Value = data.Value + Res.Value
                elseif slot == 1 then
                    local EquipDefineID1 = UGCBackpackSystemV2.GetEquippedItemBySlotName(PlayerPawn, "EquipmentSlot.Core.MainSlot1");
                    local Res = self:GetAttributeData(EquipDefineID1, Config.AttributeName)
                    data.Value = data.Value + Res.Value
                else
                    local EquipDefineID2 = UGCBackpackSystemV2.GetEquippedItemBySlotName(PlayerPawn, "EquipmentSlot.Core.MainSlot2");
                    local Res = self:GetAttributeData(EquipDefineID2, Config.AttributeName)
                    data.Value = data.Value + Res.Value
                end
            end

            if data.Value > 0 then
                local AffixString = nil
                if Config.DisplayPercentage then
                    local Modifier = data.Value * 100;
                    AffixString = tostring(Modifier) .. "%";
                else
                    AffixString = tostring(data.Value)
                end
                data.Description = Config.AttributeName
                data.Modifier = AffixString
                table.insert(TotalBaseData,data)
            end
        end
    end
    return TotalBaseData
end

function Depot_TotalAttribute_Tips_UIBP:GetWeaponAttribute(AttributeName)
    local data = {}
    data.Value = 0
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    local EquipDefineID1 = UGCBackpackSystemV2.GetEquippedItemBySlotName(PlayerPawn, "EquipmentSlot.Core.MainSlot1");
    local EquipDefineID2 = UGCBackpackSystemV2.GetEquippedItemBySlotName(PlayerPawn, "EquipmentSlot.Core.MainSlot2");
    if EquipDefineID1 ~= nil and EquipDefineID1.TypeSpecificID ~= 0 then
        local Res = self:GetAttributeData(EquipDefineID1,AttributeName)
        data.Value = Res.Value
    elseif EquipDefineID2 ~= nil and EquipDefineID2.TypeSpecificID ~= 0 then
        local Res = self:GetAttributeData(EquipDefineID2,AttributeName)
        data.Value = Res.Value
    end
    return data
end

function Depot_TotalAttribute_Tips_UIBP:GetAttributeData(DefineID,AttributeName)
    local data = {}
    data.Value = 0
    local CustomData = UGCItemSystemV2.LoadItemCustomData(DefineID);
    if CustomData == nil or CustomData.AffixData == nil then
        ugcprint(" Depot_TotalAttribute_Tips_UIBP:GetAttributeData Error")
    else
        for key, value in ipairs(CustomData.AffixData) do
            local AffixID = value.AffixId
            local AffixData = UGCGameData.GetAffixDetailsConfig(AffixID)
            ugcprint("Depot_TotalAttribute_Tips_UIBP:GetAttributeData AffixID: %d", AffixID)
            local RandomModifier = value.RandomModifier
            
            if RandomModifier == nil then
                ugcprint("AffixID: [%d] RandomModifier is nil",AffixData)
                RandomModifier = 0
            else
                local MinPlaces = AffixData.DecimalPlaces;
                if MinPlaces <= 0 then
                    RandomModifier = string.format("%d", math.floor(RandomModifier));
                else
                    RandomModifier = string.format("%." .. MinPlaces .. "f", RandomModifier);
                end
            end
            -- local SkillID = value.SkillId
            if AffixData.Description == AttributeName then
                data.Value = data.Value + RandomModifier
            end
        end
    end
    return data
end


function Depot_TotalAttribute_Tips_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;

	-- 监听背包装备变化
	local PC = UGCGameSystem.GetLocalPlayerController();
	local BackpackComp = UGCBackpackSystemV2.GetBackpackComponentV2(PC);
	BackpackComp.ItemEquippedChangeDelegate:Add(self.RefreshData, self)
end



function Depot_TotalAttribute_Tips_UIBP:Button_Mask_OnClicked()
	return nil;
end


return Depot_TotalAttribute_Tips_UIBP