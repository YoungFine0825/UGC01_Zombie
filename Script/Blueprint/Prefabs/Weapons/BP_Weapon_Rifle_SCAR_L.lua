---@class BP_Weapon_Rifle_SCAR_L_C:BP_UGC_Rifle_SCAR_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
--Edit Below--
local BP_Weapon_Rifle_SCAR_L = {}
 
--[[
function BP_Weapon_Rifle_SCAR_L:ReceiveBeginPlay()
    BP_Weapon_Rifle_SCAR_L.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_Rifle_SCAR_L:ReceiveTick(DeltaTime)
    BP_Weapon_Rifle_SCAR_L.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_Rifle_SCAR_L:ReceiveEndPlay()
    BP_Weapon_Rifle_SCAR_L.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_Rifle_SCAR_L:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_Rifle_SCAR_L:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_Rifle_SCAR_L