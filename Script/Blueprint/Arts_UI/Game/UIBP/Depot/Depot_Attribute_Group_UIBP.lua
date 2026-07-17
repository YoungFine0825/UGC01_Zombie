---@class Depot_Attribute_Group_UIBP_C:UUserWidget
---@field VerticalBox_Attribute_Number UVerticalBox
---@field VerticalBox_Attribute_TextTips UVerticalBox
--Edit Below--
local EquipmentAffixManager = UGCGameSystem.UGCRequire("Script.Blueprint.Affix.EquipmentAffixManager")
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
local Depot_Attribute_Group_UIBP = { 
    bInitDoOnce = false,
    Attribute_Number_WidgetPath = 'Asset/Blueprint/Arts_UI/Game/UIBP/Equip/Equip_AttributeNum_UIBP.Equip_AttributeNum_UIBP_C',
    Attribute_TextTips_WidgetPath = 'Asset/Blueprint/Arts_UI/Game/UIBP/Depot/Depot_Attribute_TextTips_UIBP.Depot_Attribute_TextTips_UIBP_C',
 } 


function Depot_Attribute_Group_UIBP:Construct()
	
end

---自定义属性UI部分必须有InitData方法
function Depot_Attribute_Group_UIBP:InitData(Data)
    self.VerticalBox_Attribute_Number:ClearChildren()
    self.VerticalBox_Attribute_TextTips:ClearChildren()
    if Data == nil then
        return
    end
    self:Add_Number_And_Tips_Widget(Data)
end

function Depot_Attribute_Group_UIBP:Add_Number_And_Tips_Widget(Data)
    
    local BaseDescs,SpecialDesc = self:GetAttributeData(Data)
    if #BaseDescs ~= 0 then
        local Attribute_Number_Slot = WidgetLayoutLibrary.SlotAsVerticalBoxSlot(self.VerticalBox_Attribute_Number)
        Attribute_Number_Slot:SetPadding({ Left = 0, Right = 0, Bottom = 0, Top = 5 })
        for i,data in ipairs(BaseDescs) do
            self:Add_Number_Widget(data)
        end 
    end
    if #SpecialDesc ~= 0 then
        local Attribute_TextTips_Slot = WidgetLayoutLibrary.SlotAsVerticalBoxSlot(self.VerticalBox_Attribute_TextTips)
        Attribute_TextTips_Slot:SetPadding({ Left = 0, Right = 0, Bottom = 0, Top = 5 })
        for i,data in ipairs(SpecialDesc) do
            self:Add_TextTips_Widget(data)
        end
    end
end

function Depot_Attribute_Group_UIBP:Add_Number_Widget(data)
    local pc = UGCGameSystem.GetLocalPlayerController();
    local Number_WidgetUI_Class = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath(self.Attribute_Number_WidgetPath))
    local Number_WidgetUI = UserWidget.NewWidgetObjectBP(pc,Number_WidgetUI_Class)
    
    if Number_WidgetUI  then
        self.VerticalBox_Attribute_Number:AddChildToVerticalBox(Number_WidgetUI)
        local Color = self:GetQualityTextColor(data.AffixesLevel)
        if Number_WidgetUI.Text_AttributeNumeric then
            UIUtil.SetSlateHexColor(Number_WidgetUI.Text_AttributeNumeric,Color)
            Number_WidgetUI.Text_AttributeNumeric:SetText(data.Modifier)
        end
        if Number_WidgetUI.TextBlock_Title then
            UIUtil.SetSlateHexColor(Number_WidgetUI.TextBlock_Title,Color)
            Number_WidgetUI.TextBlock_Title:SetText(data.Description) 
        end
        if Number_WidgetUI.Border_Color then
            Number_WidgetUI.Border_Color:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
    
end

function Depot_Attribute_Group_UIBP:Add_TextTips_Widget(data)
    local pc = UGCGameSystem.GetLocalPlayerController();
    local TextTips_WidgetUI_Class = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath(self.Attribute_TextTips_WidgetPath))
    local TextTips_WidgetUI = UserWidget.NewWidgetObjectBP(pc,TextTips_WidgetUI_Class)
    if TextTips_WidgetUI then
        self.VerticalBox_Attribute_TextTips:AddChildToVerticalBox(TextTips_WidgetUI)
        local Color = self:GetQualityTextColor(data.AffixesLevel)
        if TextTips_WidgetUI.UTRichTextBlock_Tips then
            UIUtil.SetSlateHexColor(TextTips_WidgetUI.UTRichTextBlock_Tips,Color)
            TextTips_WidgetUI.UTRichTextBlock_Tips:SetText(data.Description)
        end
  
    end
end

function Depot_Attribute_Group_UIBP:GetBaseAffixData(ItemID)
    local ItemHandle = UGCItemSystemV2.GetConfigItemHandle(ItemID)
    local Showinfo = {}
    if ItemHandle then
        local AttrModifyItemSimpleList = ItemHandle.AttrModifyItemSimpleList
        ---装备上的属性
        if AttrModifyItemSimpleList then
            for index, value in ipairs(totable(AttrModifyItemSimpleList)) do
                local OneAttr = self:GetAttributeString(value)
                table.insert(Showinfo,OneAttr)
            end
        else
            ugcprint("AttrModifyItemSimpleList is error")
        end

        local CharacterAttrModifyConfigs = totable(ItemHandle.CharacterAttrModifyConfigs)
        if CharacterAttrModifyConfigs then
            for index, value in ipairs(CharacterAttrModifyConfigs) do
                local oneAttr = {}
                local AttrModifyActiveCondition = value.AttrModifyActiveCondition
                if AttrModifyActiveCondition ~= EItemGAActiveCondition.ActiveOnManual then
                    local Attribute = value.AttrModifyItemSimple
                    local OneAttr = self:GetAttributeString(Attribute)
                    table.insert(Showinfo,OneAttr) 
                end
            end
        end
    end
    return Showinfo
end

function Depot_Attribute_Group_UIBP:GetAttributeString(value)
    local OneAttr = {}
    local GameAttribute = value.GameAttribute
    local ModifierOp = value.ModifierOp
    local ModifierValue = value.ModifierValue
    OneAttr.Description = UGCGameData.GetAttributeName(GameAttribute)
    local op = ""
    if ModifierOp == EAttrOperator.Plus then
        op = "+"
    elseif ModifierOp == EAttrOperator.Multiply then
        op = "x"
    elseif ModifierOp == EAttrOperator.Set then
        op = "="
    elseif ModifierOp == EAttrOperator.Max then
        op = "(Max)"
    end
    OneAttr.Modifier = op..tostring(math.floor(ModifierValue))
    OneAttr.AffixesLevel = 0
    return OneAttr
end

function Depot_Attribute_Group_UIBP:GetAttributeData(Data)
    local ItemDefineID = Data.ItemDefineID --如果为nil说明只有基础属性
    local ItemID = Data.ItemID  --此ID不能为空，如果为空说明传参错误
    if ItemID == nil then
       ugcprint("Data Error")
       return {}, {}
    end
    
    local RandomAffixData = EquipmentAffixManager.GetAffixShowInfosByDefineID(ItemDefineID)
    local BaseDescs = {}
    local SpecialDesc = {}

    if RandomAffixData then --取随机词条
        for i,Data in ipairs(RandomAffixData) do
            if Data.Modifier == nil then
                table.insert(SpecialDesc,Data)
            else
                table.insert(BaseDescs,Data)
            end
        end
    end
    table.sort(BaseDescs,self.Compare)
    return BaseDescs,SpecialDesc
end

function Depot_Attribute_Group_UIBP.Compare(data1,data2)
    local level1 = data1.AffixesLevel
    local level2 = data2.AffixesLevel
    return level1 <  level2
end

function Depot_Attribute_Group_UIBP:GetQualityTextColor(level)
    if level == 0 then
        return "cbcbceff"
    elseif level == 1 then
        return "51b988ff"
    elseif level == 2 then
        return "61a9f2ff"
    elseif level == 3 then
        return "9a69feff"
    elseif level == 4 then
        return "f49548ff"
    elseif level == 5 then
        return "fe4f43ff"
    elseif level == 6 then
        return "ffcb41ff"
    end
end
-- function Depot_Attribute_Group_UIBP:Tick(MyGeometry, InDeltaTime)

-- end

-- function Depot_Attribute_Group_UIBP:Destruct()

-- end

return Depot_Attribute_Group_UIBP