---@class BP_Weapon_Throwable_Grenade_C:BP_UGCGrenade_Projectile_Template_C
---@field NewVar_0 bool
--Edit Below--
local BP_Weapon_Throwable_Grenade = {}

--[[
function BP_Weapon_Throwable_Grenade:ReceiveLaunchBullet()
    BP_Weapon_Throwable_Grenade.SuperClass.ReceiveLaunchBullet(self)
end
--]]

--[[
function BP_Weapon_Throwable_Grenade:ReceiveOnImpact(HitResult)
    BP_Weapon_Throwable_Grenade.SuperClass.ReceiveOnImpact(self,HitResult)
end
--]]

--[[
function BP_Weapon_Throwable_Grenade:ReceiveOnBounce(HitResult, ImpactVelocity)
    BP_Weapon_Throwable_Grenade.SuperClass.ReceiveOnBounce(self,HitResult, ImpactVelocity)
end
--]]

--[[
function BP_Weapon_Throwable_Grenade:ReceivePlayExplosionEffect(ExplosionTarget)
    BP_Weapon_Throwable_Grenade.SuperClass.ReceivePlayExplosionEffect(self,ExplosionTarget)
end
--]]

--[[
function BP_Weapon_Throwable_Grenade:TickMovementPath(DeltaTime)
    BP_Weapon_Throwable_Grenade.SuperClass.TickMovementPath(self,DeltaTime)
end
--]]

return BP_Weapon_Throwable_Grenade