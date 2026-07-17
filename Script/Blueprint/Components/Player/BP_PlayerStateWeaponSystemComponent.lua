---@class BP_PlayerStateWeaponSystemComponent_C:ActorComponent
---

---@type BP_PlayerStateWeaponSystemComponent_C
local BP_PlayerStateWeaponSystemComponent = {}
 
--[[--]]
function BP_PlayerStateWeaponSystemComponent:ReceiveBeginPlay()
    BP_PlayerStateWeaponSystemComponent.SuperClass.ReceiveBeginPlay(self)
end


--[[
function BP_PlayerStateWeaponSystemComponent:ReceiveTick(DeltaTime)
    BP_PlayerStateWeaponSystemComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_PlayerStateWeaponSystemComponent:ReceiveEndPlay()
    BP_PlayerStateWeaponSystemComponent.SuperClass.ReceiveEndPlay(self) 
end
--]]

---@public
---@param Weapon ASTExtraWeapon
function BP_PlayerStateWeaponSystemComponent:OnPlayerShoot(Weapon)
    --if not UGCGameSystem.IsServer() then
    --    local weaponItemId = UGCWeaponManagerSystem.GetWeaponItemID(Weapon)
    --    UGCWidgetManagerSystem.ShowTipsUI(string.format("武器 %d 射击",weaponItemId))
    --end
end

return BP_PlayerStateWeaponSystemComponent