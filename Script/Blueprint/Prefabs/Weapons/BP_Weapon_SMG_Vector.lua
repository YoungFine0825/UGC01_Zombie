---@class BP_Weapon_SMG_Vector_C:BP_UGC_MachineGun_Vector_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
--Edit Below--
local BP_Weapon_SMG_Vector = {}
 
--[[
function BP_Weapon_SMG_Vector:ReceiveBeginPlay()
    BP_Weapon_SMG_Vector.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_SMG_Vector:ReceiveTick(DeltaTime)
    BP_Weapon_SMG_Vector.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_SMG_Vector:ReceiveEndPlay()
    BP_Weapon_SMG_Vector.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_SMG_Vector:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_SMG_Vector:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_SMG_Vector