---@class BP_Weapon_Pistol_P92_C:BP_UGC_Pistol_P92_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
--Edit Below--
local BP_Weapon_Pistol_P92 = {}
 
--[[
function BP_Weapon_Pistol_P92:ReceiveBeginPlay()
    BP_Weapon_Pistol_P92.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_Pistol_P92:ReceiveTick(DeltaTime)
    BP_Weapon_Pistol_P92.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_Pistol_P92:ReceiveEndPlay()
    BP_Weapon_Pistol_P92.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_Pistol_P92:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_Pistol_P92:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_Pistol_P92