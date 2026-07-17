---@class BP_Weapon_Pistol_ColtAnaconda_C:BP_UGC_Pistol_ColtAnaconda_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
--Edit Below--
local BP_Weapon_Pistol_ColtAnaconda = {}
 
--[[
function BP_Weapon_Pistol_ColtAnaconda:ReceiveBeginPlay()
    BP_Weapon_Pistol_ColtAnaconda.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_Pistol_ColtAnaconda:ReceiveTick(DeltaTime)
    BP_Weapon_Pistol_ColtAnaconda.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_Pistol_ColtAnaconda:ReceiveEndPlay()
    BP_Weapon_Pistol_ColtAnaconda.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_Pistol_ColtAnaconda:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_Pistol_ColtAnaconda:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_Pistol_ColtAnaconda