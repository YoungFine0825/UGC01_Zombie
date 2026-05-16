---@class ItemSpawnerManager_C:BP_UGCItemSpawnerManager_C
--Edit Below--
local ItemSpawnerManager = {}
 
local GameModeConfigTablePath = "Data/Table/UGCGameModeConfig"
function ItemSpawnerManager:ReceiveBeginPlay()
    ItemSpawnerManager.SuperClass.ReceiveBeginPlay(self)

    ugcprint("ItemSpawnerManager:ReceiveBeginPlay")
    local ModeID = UGCMultiMode.GetModeID()
    local GameModeConfigTable = UGCGameSystem.GetTableData(GameModeConfigTablePath)
    if not GameModeConfigTable then
        ugcprint("ItemSpawnerManager:ReceiveBeginPlay GameModeConfigTable not found")
        return
    end

    local ModeConfig = nil
    for _, value in pairs(GameModeConfigTable) do
		if value.ModeID == ModeID then
			ModeConfig = value
            break
		end
	end
    if not ModeConfig then
        ugcprint("ItemSpawnerManager:ReceiveBeginPlay ModeID not found")
        return -1
    end

    ugcprint("ItemSpawnerManager:ReceiveBeginPlay ModeID="..ModeID)
    local NewSpawnConfig = {}
    NewSpawnConfig.ConfigMode = EUGCItemSpawnerConfigMode.Custom
    NewSpawnConfig.CustomParam = { SchemeID = ModeConfig.ItemRefresh}
    
    self:CleanAllItemConfigOverride()
    self:SetItemConfigOverride(NewSpawnConfig)
end


--[[
function ItemSpawnerManager:ReceiveTick(DeltaTime)
    ItemSpawnerManager.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function ItemSpawnerManager:ReceiveEndPlay()
    ItemSpawnerManager.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function ItemSpawnerManager:GetReplicatedProperties()
    return
end
--]]

--[[
function ItemSpawnerManager:GetAvailableServerRPCs()
    return
end
--]]

return ItemSpawnerManager