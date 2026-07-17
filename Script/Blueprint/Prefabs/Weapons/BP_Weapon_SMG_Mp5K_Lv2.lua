---@class BP_Weapon_SMG_Mp5K_Lv2_C:BP_Weapon_SMG_Mp5K_C
--Edit Below--
local BP_Weapon_SMG_Mp5K_Lv2 = {}
 
--[[
function BP_Weapon_SMG_Mp5K_Lv2:ReceiveBeginPlay()
    BP_Weapon_SMG_Mp5K_Lv2.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_Weapon_SMG_Mp5K_Lv2:ReceiveTick(DeltaTime)
    BP_Weapon_SMG_Mp5K_Lv2.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_Weapon_SMG_Mp5K_Lv2:ReceiveEndPlay()
    BP_Weapon_SMG_Mp5K_Lv2.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_Weapon_SMG_Mp5K_Lv2:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Weapon_SMG_Mp5K_Lv2:GetAvailableServerRPCs()
    return
end
--]]

return BP_Weapon_SMG_Mp5K_Lv2