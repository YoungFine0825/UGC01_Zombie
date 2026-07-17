---@class BP_Weapon_SMG_Mp5K_C:BP_UGC_MachineGun_MP5K_C
---@field WeaponSystemComponent BP_WeaponSystemComponent_C
---@field WeaponConfigID int32
--Edit Below--
---@type BP_Weapon_Mp5K_C
local BP_Weapon_SMG_Mp5K = {}
 
--[[--]]
function BP_Weapon_SMG_Mp5K:ReceiveBeginPlay()
    BP_Weapon_SMG_Mp5K.SuperClass.ReceiveBeginPlay(self)
end


--[[
function BP_Weapon_SMG_Mp5K:ReceiveTick(DeltaTime)
    BP_Weapon_SMG_Mp5K.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_SMG_Mp5K:ReceiveEndPlay()
    BP_Weapon_SMG_Mp5K.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_SMG_Mp5K:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_SMG_Mp5K:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_SMG_Mp5K