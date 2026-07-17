---@class BP_Weapon_Pistol_VZ61_C:BP_UGC_Pistol_Vz61_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
--Edit Below--
local BP_Weapon_Pistol_VZ61 = {}
 
--[[
function BP_Weapon_Pistol_VZ61:ReceiveBeginPlay()
    BP_Weapon_Pistol_VZ61.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_Pistol_VZ61:ReceiveTick(DeltaTime)
    BP_Weapon_Pistol_VZ61.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_Pistol_VZ61:ReceiveEndPlay()
    BP_Weapon_Pistol_VZ61.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_Pistol_VZ61:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_Pistol_VZ61:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_Pistol_VZ61