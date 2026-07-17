---@class BP_PlayerControllerWeaponSystemComponent_C:ActorComponent
---

---@type BP_PlayerControllerWeaponSystemComponent_C
local BP_PlayerControllerWeaponSystemComponent = {}
 
--[[
function BP_PlayerControllerWeaponSystemComponent:ReceiveBeginPlay()
    BP_PlayerControllerWeaponSystemComponent.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_PlayerControllerWeaponSystemComponent:ReceiveTick(DeltaTime)
    BP_PlayerControllerWeaponSystemComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_PlayerControllerWeaponSystemComponent:ReceiveEndPlay()
    BP_PlayerControllerWeaponSystemComponent.SuperClass.ReceiveEndPlay(self) 
end
--]]

---@public
---@param Weapon ASTExtraWeapon
function BP_PlayerControllerWeaponSystemComponent:OnPlayerShoot(Weapon)

end

return BP_PlayerControllerWeaponSystemComponent