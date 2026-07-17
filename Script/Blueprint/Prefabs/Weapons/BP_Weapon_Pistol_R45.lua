---@class BP_Weapon_Pistol_R45_C:BP_UGC_Pistol_R45_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
--Edit Below--
local BP_Weapon_Pistol_R45 = {}
 
--[[
function BP_Weapon_Pistol_R45:ReceiveBeginPlay()
    BP_Weapon_Pistol_R45.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_Pistol_R45:ReceiveTick(DeltaTime)
    BP_Weapon_Pistol_R45.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_Pistol_R45:ReceiveEndPlay()
    BP_Weapon_Pistol_R45.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_Pistol_R45:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_Pistol_R45:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_Pistol_R45