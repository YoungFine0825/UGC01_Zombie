---@class Newskill2level1_C:UniversalProjectileBase
---@field Tail UParticleSystemComponent
---@field Sphere UStaticMeshComponent
---@field SphereCollision USphereComponent
---@field PlayerPawn UClass
---@field CameraShakeRange float
---@field CameraShakeTime float
---@field CameraShakeScale float
--Edit Below--
local GuidedMissile = {}
 
function GuidedMissile:ReceivePlayExplosionEffectToAllTarget(ExplosionTarget)
    GuidedMissile.SuperClass:ReceivePlayExplosionEffectToAllTarget()

    for k, v in pairs(ExplosionTarget) do
        if UGCObjectUtility.IsObjectValid(v.Actor:Get()) then
            if UGCObjectUtility.IsA(v.Actor:Get(),self.PlayerPawn) then
                local PlayerController = UGCGameSystem.GetPlayerControllerByPlayerPawn(v.Actor:Get())
                ugcprint("GuidedMissile: Log:震屏")
                UGCGameSystem.ClientPlayCameraShake(PlayerController, EPESkillCameraShakeType.E_PESKILL_CameraShake_Random, 1, 1)
            end
        end
    end
end


return GuidedMissile