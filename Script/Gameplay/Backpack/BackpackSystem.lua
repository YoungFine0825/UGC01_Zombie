local Print = GameplayUtils.Print
local Exception = GameplayUtils.Exception

---@type UGCBackpackSystemV2
local UGCBackpackSystem = UGCBackpackSystemV2

---@class Gameplay.BackpackSystem
local BackpackSystem = LuaClass("Gameplay.BackpackSystem")

function BackpackSystem:Ctor()
end

---@public
---@param player PlayerPawn | PlayerController
---@param itemId number
---@return ItemDefineID | nil
function BackpackSystem:GetGainedItemDefineId(player,itemId)
    local itemDefineId = nil---@type ItemDefineID
    local items = UGCBackpackSystem.GetItemDefineIDsByIDV2(player, itemId)
    if items and #items > 0 then
        itemDefineId = items[#items]
    end
    return itemDefineId
end

---@public
---@param player PlayerPawn | PlayerController
---@param itemId number
---@param itemCnt number
---@return boolean,ItemDefineID
function BackpackSystem:DeliverItemToPlayer(player,itemId,itemCnt)
    local itemDefineId = nil---@type ItemDefineID
    local items = UGCBackpackSystem.GetItemDefineIDsByIDV2(player, itemId)
    if items and #items > 0 then
        itemDefineId = items[#items]
    else
        local actualItemCnt, defineIDs = UGCBackpackSystem.AddItemV2(player, itemId, itemCnt)
        if actualItemCnt <= 0 then
            Exception("BackpackSystem.DeliverItemToPlayer: 添加道具进背包失败！itemId ="..tostring(itemId))
            return false
        end

        if defineIDs and #defineIDs > 0 then
            itemDefineId = defineIDs[1]
        else
            items = UGCBackpackSystem.GetItemDefineIDsByIDV2(player, itemId)
            if items and #items > 0 then
                itemDefineId = items[#items]
            end
        end
    end
    if itemDefineId == nil then
        Exception("[BackpackSystem.DeliverItemToPlayer: 无法找到道具的DefineID! itemId ="..tostring(itemId))
        return false
    end
    return true,itemDefineId
end

return BackpackSystem