---@class BP_Inventory_Soda_QuickRevive_C:Template_Consumable_Drink_C
--Edit Below--
local BP_Inventory_Soda_QuickRevive = {} 

--[[经典背包事件]]--
--[[
--- func 处理物品的拾取(服务端生效)
---@return bool @是否拾取该物品, 返回true才能拾取进背包
-- function BP_Inventory_Soda_QuickRevive:HandlePickup(ItemContainer, PickupInfo, Reason)
--    return BP_Inventory_Soda_QuickRevive.SuperClass.HandlePickup(self, ItemContainer, PickupInfo, Reason)
-- end

--- func 处理物品的丢弃(服务端生效)
---@return bool @是否丢弃该物品, 返回true才会丢弃
-- function BP_Inventory_Soda_QuickRevive:HandleDrop(InCount, Reason)
--    return BP_Inventory_Soda_QuickRevive.SuperClass.HandleDrop(self, InCount, Reason)
-- end

--- func 处理物品的取出(服务端生效)
---@return number @可取出物品数量
-- function BP_Inventory_Soda_QuickRevive:HandleTake(TakeCount, TotalCount)
--    return BP_Inventory_Soda_QuickRevive.SuperClass.HandleTake(self, TakeCount, TotalCount)
-- end

--- func 处理物品的使用(服务端生效)
---@return bool @使用是否成功
-- function BP_Inventory_Soda_QuickRevive:HandleUse(Target, Reason)
--    return BP_Inventory_Soda_QuickRevive.SuperClass.HandleUse(self, Target, Reason) 
-- end

--- func 处理物品的取消使用(服务端生效)
---@return bool @取消使用是否成功
-- function BP_Inventory_Soda_QuickRevive:HandleDisuse(Reason)
--    return BP_Inventory_Soda_QuickRevive.SuperClass.HandleDisuse(self, Reason) 
-- end

--- func 尝试取消使用物品，仅尝试(服务端生效)
---@return bool @物品能否取消使用
-- function BP_Inventory_Soda_QuickRevive:HandleTryDisuse(Reason)
--    return BP_Inventory_Soda_QuickRevive.SuperClass.HandleTryDisuse(self, Reason)
-- end

--- func 处理物品的有效性(服务端生效)
-- function BP_Inventory_Soda_QuickRevive:HandleEnable(bEnable)
--    BP_Inventory_Soda_QuickRevive.SuperClass.HandleEnable(self, bEnable)
-- end

--- func 处理物品的清除(服务端生效)
---@return bool @清除物品是否成功
-- function BP_Inventory_Soda_QuickRevive:HanldeCleared()
--    return BP_Inventory_Soda_QuickRevive.SuperClass.HanldeCleared(self)
-- end
]]--

--[[V2背包事件]]--
--[[
--- func 能否创建物品Handle(服务端生效)
---@return bool @是否允许创建物品Handle, 若不允许，物品也将创建失败
-- function BP_Inventory_Soda_QuickRevive:CanCreateItemHandleV2()
--     return BP_Inventory_Soda_QuickRevive.SuperClass.CanCreateItemHandleV2(self);
-- end

--- func 当创建物品Handle后回调，可重载并自定义(服务端生效)
--  function BP_Inventory_Soda_QuickRevive:OnCreateItemHandleV2()
--     BP_Inventory_Soda_QuickRevive.SuperClass.OnCreateItemHandleV2(self);
--  end

--- func 能否销毁物品Handle，可重载并自定义(服务端生效)
---@return bool 是否允许销毁Handle, 若不允许，物品移除或丢弃也可能失败
-- function BP_Inventory_Soda_QuickRevive:CanDestoryItemHandleV2()
--     return BP_Inventory_Soda_QuickRevive.SuperClass.CanDestoryItemHandleV2(self);
-- end

--- func 销毁物品Handle前回调，可重载并自定义(服务端生效)
-- function BP_Inventory_Soda_QuickRevive:OnDestoryItemHandleV2()
--     BP_Inventory_Soda_QuickRevive.SuperClass.OnDestoryItemHandleV2(self);
-- end

--- func 能否更新此物品实例，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
---@return 是否允许物品数量更新，若不允许，物品添加或移除操作可能失败
-- function BP_Inventory_Soda_QuickRevive:CanUpdateItemCountV2(NewItemCount, OldItemCount)
--     return BP_Inventory_Soda_QuickRevive.SuperClass.CanUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 物品数量更新后回调，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
-- function BP_Inventory_Soda_QuickRevive:OnUpdateItemCountV2(NewItemCount, OldItemCount)
--     BP_Inventory_Soda_QuickRevive.SuperClass.OnUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 能否使用物品，可重载并自定义(服务端生效)
---@return 物品是否能够被使用
-- function BP_Inventory_Soda_QuickRevive:CanUseV2()
--     return BP_Inventory_Soda_QuickRevive.SuperClass.CanUseV2(self);
-- end

--- func 当物品被使用回调，可重载并自定义(服务端生效)
-- function BP_Inventory_Soda_QuickRevive:OnUseV2()
--     BP_Inventory_Soda_QuickRevive.SuperClass.OnUseV2(self);
-- end

--- func 当物品被取消使用，与UseItem对应，用于清理状态，应当支持多次调用，不产生额外副作用，移除物品时自动调用，可重载并自定义(服务端生效)
-- function BP_Inventory_Soda_QuickRevive:OnDisuseV2()
--     BP_Inventory_Soda_QuickRevive.SuperClass.OnDisuseV2(self);
-- end

--- func 当物品开始使用时回调，可重载并自定义(服务端生效)
-- function BP_Inventory_Soda_QuickRevive:UGC_OnStartUse()
--     BP_Inventory_Soda_QuickRevive.SuperClass.UGC_OnStartUse(self)
-- end

--- func 当物品停止使用时回调，可重载并自定义(服务端生效)，在OnUseV2后调用
-- function BP_Inventory_Soda_QuickRevive:UGC_OnStopUse(Reason)
    BP_Inventory_Soda_QuickRevive.SuperClass.UGC_OnStopUse(self, Reason)
-- end
]]--

return BP_Inventory_Soda_QuickRevive