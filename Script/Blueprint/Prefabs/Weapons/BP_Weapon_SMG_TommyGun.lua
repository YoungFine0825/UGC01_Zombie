---@class BP_Weapon_SMG_TommyGun_C:BP_UGC_MachineGun_TommyGun_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
--Edit Below--
local BP_Weapon_SMG_TommyGun = {}
 
--[[
function BP_Weapon_SMG_TommyGun:ReceiveBeginPlay()
    BP_Weapon_SMG_TommyGun.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_SMG_TommyGun:ReceiveTick(DeltaTime)
    BP_Weapon_SMG_TommyGun.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_SMG_TommyGun:ReceiveEndPlay()
    BP_Weapon_SMG_TommyGun.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_SMG_TommyGun:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_SMG_TommyGun:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_SMG_TommyGun