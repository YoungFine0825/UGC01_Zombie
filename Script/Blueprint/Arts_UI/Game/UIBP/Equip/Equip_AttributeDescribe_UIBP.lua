---@class Equip_AttributeDescribe_UIBP_C:UUserWidget
---@field Button_Select UButton
---@field CanvasPanel_Upgrade UCanvasPanel
---@field Depot_Attribute_Group_UIBP UDepot_Attribute_Group_UIBP_C
---@field Image_Icon UImage
---@field TextBlock_Describe UTextBlock
---@field TextBlock_Name UTextBlock
---@field TextBlock_Title UTextBlock
--Edit Below--
local Equip_AttributeDescribe_UIBP = 
{ 
    bInitDoOnce = false,
 } 


function Equip_AttributeDescribe_UIBP:Construct()
	
end

function Equip_AttributeDescribe_UIBP:InitData(data)
    self:SetInfo(data)
    self.Depot_Attribute_Group_UIBP:InitData({data}) 
end

function Equip_AttributeDescribe_UIBP:SetInfo(data)
    if data == nil then
        return
    end
    local Count = data.ItemCount
	if Count == nil then
		Count = 1
	end
	local ItemID = data.ItemID
	local Name = UGCItemSystemV2.GetItemNameV2(ItemID)
    self.TextBlock_Name:SetText(Name)
    local desc = UGCItemSystemV2.GetItemDetailV2(ItemID)
    self.TextBlock_Describe:SetText(desc)
	local ItemHandle = UGCItemSystemV2.GetConfigItemHandle(ItemID)
	if ItemHandle then
		local IconPath = UGCObjectUtility.GetPathBySoftObjectPath(ItemHandle:UGC_GetIconTexture());
		if IconPath then
			FuncUtil.SetImageWithPath(self.Image_Icon, IconPath)
		end
	end
end


-- function Equip_AttributeDescribe_UIBP:Tick(MyGeometry, InDeltaTime)

-- end

-- function Equip_AttributeDescribe_UIBP:Destruct()

-- end

    


return Equip_AttributeDescribe_UIBP