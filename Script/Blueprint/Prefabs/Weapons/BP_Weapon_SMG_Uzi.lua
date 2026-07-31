---@class BP_Weapon_SMG_Uzi_C:BP_UGC_MachineGun_Uzi_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
---@field WeaponConfigID int32
--Edit Below--
local BP_Weapon_SMG_Uzi = {}
 
--[[
function BP_Weapon_SMG_Uzi:ReceiveBeginPlay()
    BP_Weapon_SMG_Uzi.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_SMG_Uzi:ReceiveTick(DeltaTime)
    BP_Weapon_SMG_Uzi.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_SMG_Uzi:ReceiveEndPlay()
    BP_Weapon_SMG_Uzi.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_SMG_Uzi:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_SMG_Uzi:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_SMG_Uzi