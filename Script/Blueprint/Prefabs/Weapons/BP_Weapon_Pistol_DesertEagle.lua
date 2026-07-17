---@class BP_Weapon_Pistol_DesertEagle_C:BP_UGC_Pistol_DesertEagle_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
--Edit Below--
local BP_Weapon_Pistol_DesertEagle = {}
 
--[[
function BP_Weapon_Pistol_DesertEagle:ReceiveBeginPlay()
    BP_Weapon_Pistol_DesertEagle.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_Pistol_DesertEagle:ReceiveTick(DeltaTime)
    BP_Weapon_Pistol_DesertEagle.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_Pistol_DesertEagle:ReceiveEndPlay()
    BP_Weapon_Pistol_DesertEagle.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_Pistol_DesertEagle:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_Pistol_DesertEagle:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_Pistol_DesertEagle