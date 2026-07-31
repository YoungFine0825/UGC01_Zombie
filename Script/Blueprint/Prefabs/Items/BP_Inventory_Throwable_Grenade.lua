---@class BP_Inventory_Throwable_Grenade_C:Template_Throwable_ShouLei_C
--Edit Below--
local BP_Inventory_Throwable_Grenade = {} 

--[[经典背包事件]]--
--[[
--- func 处理物品的拾取(服务端生效)
---@return bool @是否拾取该物品, 返回true才能拾取进背包
-- function BP_Inventory_Throwable_Grenade:HandlePickup(ItemContainer, PickupInfo, Reason)
--    return BP_Inventory_Throwable_Grenade.SuperClass.HandlePickup(self, ItemContainer, PickupInfo, Reason)
-- end

--- func 处理物品的丢弃(服务端生效)
---@return bool @是否丢弃该物品, 返回true才会丢弃
-- function BP_Inventory_Throwable_Grenade:HandleDrop(InCount, Reason)
--    return BP_Inventory_Throwable_Grenade.SuperClass.HandleDrop(self, InCount, Reason)
-- end

--- func 处理物品的取出(服务端生效)
---@return number @可取出物品数量
-- function BP_Inventory_Throwable_Grenade:HandleTake(TakeCount, TotalCount)
--    return BP_Inventory_Throwable_Grenade.SuperClass.HandleTake(self, TakeCount, TotalCount)
-- end

--- func 处理物品的使用(服务端生效)
---@return bool @使用是否成功
-- function BP_Inventory_Throwable_Grenade:HandleUse(Target, Reason)
--    return BP_Inventory_Throwable_Grenade.SuperClass.HandleUse(self, Target, Reason) 
-- end

--- func 处理物品的取消使用(服务端生效)
---@return bool @取消使用是否成功
-- function BP_Inventory_Throwable_Grenade:HandleDisuse(Reason)
--    return BP_Inventory_Throwable_Grenade.SuperClass.HandleDisuse(self, Reason) 
-- end

--- func 尝试取消使用物品，仅尝试(服务端生效)
---@return bool @物品能否取消使用
-- function BP_Inventory_Throwable_Grenade:HandleTryDisuse(Reason)
--    return BP_Inventory_Throwable_Grenade.SuperClass.HandleTryDisuse(self, Reason)
-- end

--- func 处理物品的有效性(服务端生效)
-- function BP_Inventory_Throwable_Grenade:HandleEnable(bEnable)
--    BP_Inventory_Throwable_Grenade.SuperClass.HandleEnable(self, bEnable)
-- end

--- func 处理物品的清除(服务端生效)
---@return bool @清除物品是否成功
-- function BP_Inventory_Throwable_Grenade:HanldeCleared()
--    return BP_Inventory_Throwable_Grenade.SuperClass.HanldeCleared(self)
-- end
]]--

--[[V2背包事件]]--
--[[
--- func 其他物品能否附加到此槽位(服务端生效)
---@param SlotName string 槽位名称
---@param ItemDefineID userdata 物品ID
-- function BP_Inventory_Throwable_Grenade:CanAttachToSlot(SlotName, ItemDefineID)
--     return BP_Inventory_Throwable_Grenade.SuperClass.CanAttachToSlot(self, SlotName, ItemDefineID);
-- end

--- func 当其他物品附加到此槽位(服务端生效)
---@param SlotName string 槽位名称
---@param ItemDefineID userdata 物品ID
-- function BP_Inventory_Throwable_Grenade:OnAttachToSlot(SlotName, ItemDefineID)
--     BP_Inventory_Throwable_Grenade.SuperClass.OnAttachToSlot(self, SlotName, ItemDefineID);
-- end

--- func 当物品从此槽位移除(服务端生效)
---@param SlotName string 槽位名称
---@param ItemDefineID userdata 物品ID
-- function BP_Inventory_Throwable_Grenade:OnDetachBySlot(SlotName, ItemDefineID)
--     BP_Inventory_Throwable_Grenade.SuperClass.OnDetachBySlot(self, SlotName, ItemDefineID);
-- end

--- func 能否Attach到Parent物品上, 如果Parent为空物品, 说明将被Attach到背包装备槽位(服务端生效)
---@param ParentDefineID userdata 父物品ID
---@param SlotName string 槽位名称
---@return bool 能否Attach
-- function BP_Inventory_Throwable_Grenade:CanAttach(ParentDefineID, SlotName)
--     return BP_Inventory_Throwable_Grenade.SuperClass.CanAttach(self, ParentDefineID, SlotName);
-- end

--- func 当Attach到Parent物品上, 如果Parent为空物品, 说明是被Attach到背包装备槽位(服务端生效)
---@param ParentDefineID userdata 父物品ID
---@param SlotName string 槽位名称
-- function BP_Inventory_Throwable_Grenade:OnAttach(ParentDefineID, SlotName)
--     BP_Inventory_Throwable_Grenade.SuperClass.OnAttach(self, ParentDefineID, SlotName);
-- end

--- func 当从Parent物品上解除Attach, 如果Parent为空物品, 说明是从背包装备槽位解除装备(服务端生效)
---@param ParentDefineID userdata 父物品ID
---@param SlotName string 槽位名称
-- function BP_Inventory_Throwable_Grenade:OnDetach(ParentDefineID, SlotName)
--     BP_Inventory_Throwable_Grenade.SuperClass.OnDetach(self, ParentDefineID, SlotName);
-- end

--- func 当物品被装备前，检查能否装备(服务端生效)
---@return bool 能否装备
-- function BP_Inventory_Throwable_Grenade:CanEquip()
--     return BP_Inventory_Throwable_Grenade.SuperClass.CanEquip(self);
-- end

--- func 当物品被装备回调(服务端生效)
-- function BP_Inventory_Throwable_Grenade:OnEquip()
--     BP_Inventory_Throwable_Grenade.SuperClass.OnEquip(self);
-- end

--- func 当物品被卸下回调(服务端生效)
-- function BP_Inventory_Throwable_Grenade:OnUnEquip()
--     BP_Inventory_Throwable_Grenade.SuperClass.OnUnEquip(self);
-- end

--- func 当物品在背包中被交换槽位前，检查能否交换(服务端生效)
---@param OldSlotName string 旧槽位名称
---@param NewSlotName string 新槽位名称
---@return 能否交换到新槽位
-- function BP_Inventory_Throwable_Grenade:CanSwapEquipSlot(OldSlotName, NewSlotName)
--     return BP_Inventory_Throwable_Grenade.SuperClass.CanSwapEquipSlot(self, OldSlotName, NewSlotName);
-- end

--- func 当物品被交换到新装备槽位后回调(服务端生效)
---@param OldSlotName string 旧槽位名称
---@param NewSlotName string 新槽位名称
-- function BP_Inventory_Throwable_Grenade:OnSwapEquipSlot(OldSlotName, NewSlotName)
        BP_Inventory_Throwable_Grenade.SuperClass.OnSwapEquipSlot(self, OldSlotName, NewSlotName);
-- end
]]--

return BP_Inventory_Throwable_Grenade