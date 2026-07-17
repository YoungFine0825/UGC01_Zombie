---@class BP_Weapon_Pistol_TMP9_C:BP_UGC_Pistol_TMP_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
--Edit Below--
local BP_Weapon_Pistol_TMP9 = {}
 
--[[
function BP_Weapon_Pistol_TMP9:ReceiveBeginPlay()
    BP_Weapon_Pistol_TMP9.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_Pistol_TMP9:ReceiveTick(DeltaTime)
    BP_Weapon_Pistol_TMP9.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_Pistol_TMP9:ReceiveEndPlay()
    BP_Weapon_Pistol_TMP9.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_Pistol_TMP9:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_Pistol_TMP9:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_Pistol_TMP9