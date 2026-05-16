---@class ItemSpawner_C:BP_UGCItemSpawner_C
---@field SpawnerType FName
--Edit Below--
local ItemSpawner = {}
 
local ItemSchemeTablePath="Data/Table/DT_ItemSpawnScheme"

--[[
function ItemSpawner:ReceiveBeginPlay()
    ItemSpawner.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function ItemSpawner:ReceiveTick(DeltaTime)
    ItemSpawner.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function ItemSpawner:ReceiveEndPlay()
    ItemSpawner.SuperClass.ReceiveEndPlay(self) 
end
--]]

function ItemSpawner:GetDropGroupID(SchemeID, SpawnerType)
    ugcprint("ItemSpawner:GetDropGroupID SchemeID="..tostring(SchemeID).." SpawnerType="..tostring(SpawnerType))
    local ItemSchemeTable = UGCGameSystem.GetTableData(ItemSchemeTablePath)
    if not ItemSchemeTable then
        ugcprint("ItemSchemeTable not found")
        return -1
    end

    local ItemScheme = nil
    for _, value in pairs(ItemSchemeTable) do
		if tonumber(value.SchemeID) == tonumber(SchemeID) then
			ItemScheme = value
            break
		end
	end
    if not ItemScheme then
        ugcprint("ItemSpawner:GetDropGroupID SchemeID not found")
        return -1
    end

    local DropGroupID = -1
    for _, value in pairs(ItemScheme.SpawnerTypes) do
		if value.SpawnerType == SpawnerType then
			DropGroupID = value.DropGroupID
            break
		end
	end

    return DropGroupID
end

function ItemSpawner:CustomSpawnItem(InCustomParam)
    ugcprint("ItemSpawner:CustomSpawnItem")
    local DropGroupID = self:GetDropGroupID(InCustomParam.SchemeID, self.SpawnerType)
    if DropGroupID == -1 then
        ugcprint("ItemSpawner:CustomSpawnItem GetDropGroupID failed InCustomID="..tostring(InCustomParam.SchemeID).." SpawnerType="..tostring(self.SpawnerType))
        return nil
    end

    local DropItemList = UGCDropSystem.DropItemsByGroup(DropGroupID)
    if nil == next(DropItemList) then
        ugcprint("ItemSpawner:CustomSpawnItem Error, Drop Nothing")
        return {}
    end

    local SpawnedItems = {}
    for ItemID, ItemCount in pairs(DropItemList) do
        local SpawnedItem = self:SpawnItem(ItemID, ItemCount)
        table.insert(SpawnedItems, SpawnedItem)
    end

    return SpawnedItems
end


return ItemSpawner