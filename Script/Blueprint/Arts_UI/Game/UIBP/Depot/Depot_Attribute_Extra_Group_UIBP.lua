---@class Depot_Attribute_Extra_Group_UIBP_C:UUserWidget
---@field Depot_Attribute_Group_UIBP Depot_Attribute_Group_UIBP_C
---@field Equip_AttributeDescribe_UIBP Equip_AttributeDescribe_UIBP_C
---@field VerticalBox_Attribute UVerticalBox
---@field VerticalBox_ItemWidget UVerticalBox
---@field NewVar_0 FSoftClassPath
--Edit Below--
local Depot_Attribute_Group_UIBP = { 
    bInitDoOnce = false,
    Attribute_WidgetPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Game/UIBP/Depot/Depot_Attribute_Group_UIBP.Depot_Attribute_Group_UIBP_C'),
    Attribute_Extra_WidgetPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Game/UIBP/Equip/Equip_AttributeDescribe_UIBP.Equip_AttributeDescribe_UIBP_C'),
 } 


function Depot_Attribute_Group_UIBP:Construct()
	
end

---自定义属性UI部分必须有InitData方法
function Depot_Attribute_Group_UIBP:InitData(Data)
    if Data == nil then
        return
    end
    self.VerticalBox_Attribute:ClearChildren()
    self.VerticalBox_ItemWidget:ClearChildren()
    log_tree("Depot_Attribute_Group_UIBP:InitData ", Data)
    for i, v in ipairs(Data) do
        if i == 1 then
            self:Add_Number_And_Tips_Widget(v)
        else
            self:Add_Extra_Widget(v) 
        end
    end  
end

function Depot_Attribute_Group_UIBP:Add_Number_And_Tips_Widget(Data)
    
    local Attribute_Slot = WidgetLayoutLibrary.SlotAsVerticalBoxSlot(self.VerticalBox_Attribute)
    Attribute_Slot:SetPadding({ Left = 0, Right = 0, Bottom = 0, Top = 10 })
    local pc = UGCGameSystem.GetLocalPlayerController();
    local Attribute_WidgetPath_Class = UGCObjectUtility.LoadClass(self.Attribute_WidgetPath)
    local Attribute_WidgetUI = UserWidget.NewWidgetObjectBP(pc,Attribute_WidgetPath_Class);
    Attribute_WidgetUI:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if Attribute_WidgetUI and Attribute_WidgetUI.InitData ~= nil and type(Attribute_WidgetUI.InitData) == "function" then
        self.VerticalBox_Attribute:AddChildToVerticalBox(Attribute_WidgetUI)
        Attribute_WidgetUI:InitData(Data)
    end
end

function Depot_Attribute_Group_UIBP:Add_Extra_Widget(Data)
   
    local Extra_Widget_Slot = WidgetLayoutLibrary.SlotAsVerticalBoxSlot(self.VerticalBox_ItemWidget)
    Extra_Widget_Slot:SetPadding({ Left = 0, Right = 0, Bottom = 0, Top = 10 })
    local pc = UGCGameSystem.GetLocalPlayerController();
    local Extra_WidgetUI_Class = UGCObjectUtility.LoadClass(self.Add_Extra_Widget)
    local  Extra_WidgetUI = UserWidget.NewWidgetObjectBP(pc,Extra_WidgetUI_Class);
    if Extra_WidgetUI and Extra_WidgetUI.InitData ~= nil and type(Extra_WidgetUI.InitData) == "function" then
        self.VerticalBox_ItemWidget:AddChildToVerticalBox(Extra_Widget_Slot)
        Extra_WidgetUI:InitData(Data)
        
    end
end
-- function Depot_Attribute_Group_UIBP:Tick(MyGeometry, InDeltaTime)

-- end

-- function Depot_Attribute_Group_UIBP:Destruct()

-- end

return Depot_Attribute_Group_UIBP