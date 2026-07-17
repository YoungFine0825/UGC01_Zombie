---@class BP_Weapon_Pistol_P1911_C:BP_UGC_Pistol_P1911_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
--Edit Below--
local BP_Weapon_Pistol_P1911 = {}
 
--[[
function BP_Weapon_Pistol_P1911:ReceiveBeginPlay()
    BP_Weapon_Pistol_P1911.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_Pistol_P1911:ReceiveTick(DeltaTime)
    BP_Weapon_Pistol_P1911.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_Pistol_P1911:ReceiveEndPlay()
    BP_Weapon_Pistol_P1911.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_Pistol_P1911:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_Pistol_P1911:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_Pistol_P1911