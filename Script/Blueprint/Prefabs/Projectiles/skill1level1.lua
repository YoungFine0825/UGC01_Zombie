---@class skill1level1_C:UniversalProjectileBase
---@field ParticleSystem UParticleSystemComponent
---@field M18 UStaticMeshComponent
---@field Sphere USphereComponent
---@field CameraShakeRange float
---@field PlayerPawn UClass
---@field CameraShakeTime float
---@field CameraShakeScale float
--Edit Below--
local skill1level1 = {}
 
function skill1level1:ReceiveOnImpact(ImpactResult)
    ugcprint("skill1level1:ReceiveOnImpact")
    if (UGCActorComponentUtility.HasAuthority(self)) then
        local PlayerPawnsNearby = {}
        local PlayerPawnClass = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/UGCPlayerPawn.UGCPlayerPawn_C'));
        local IfAnyPlayerPawnsNearby = UGCSceneQueryUtility.QueryOverlapActorsBySphere(self, UGCActorComponentUtility.GetActorTransform(self).Translation, nil, 2000, nil, PlayerPawnClass, PlayerPawnsNearby)
        ugcprint("GuidedStrikeProjectile:PlayerPawnsNearby Length: "..#PlayerPawnsNearby);

        if (IfAnyPlayerPawnsNearby) then
            local CameraShakeClass = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/PESkill/GuidedStrike/GuidedStrikeCameraShake.GuidedStrikeCameraShake_C'));
            for i = 1, #PlayerPawnsNearby do
                local Pawn = PlayerPawnsNearby[i];
                UGCGameSystem.GetPlayerControllerByPlayerPawn(Pawn):ClientPlayCameraShake(CameraShakeClass, 2.0);
            end
        end
    end
end

function skill1level1:ReceiveLaunchBullet()
    skill1level1.SuperClass.ReceiveLaunchBullet(self)

    ugcprint("skill1level1:ReceiveLaunchBullet")
end

function skill1level1:OnImpactSpawnActor(ImpactResult)
    ugcprint("skill1level1:OnImpactSpawnActor")
    -- fix code
    if self.HitSpawnActor then
        local TargetPos = nil
        local Start = ImpactResult.ImpactPoint
        local End  = UGCMathUtility.AddVector(Start, Vector.New(0, 0, -10000))
        local bHit, hitResult = UGCSceneQueryUtility.QueryBlocksByChannel(self, Start, End, nil, {}, {ECollisionChannel.ECC_WorldStatic})
        if bHit then
            for _, v in pairs(hitResult) do
                if v.Actor:Get() or v.Component:Get() then
                    TargetPos = UGCMathUtility.AddVector(v.ImpactPoint, Vector.New(0, 0, 5))
                    break
                end
            end
        end
        if not TargetPos then
            TargetPos = UGCMathUtility.AddVector(ImpactResult.ImpactPoint, Vector.New(0, 0, 5))
        end
        UGCGameSystem.SpawnActor(self,
        self.HitSpawnActor,
        TargetPos, Vector.New(0, 0, 0), Vector.New(1, 1, 1),
        UGCActorComponentUtility.GetOwner(self))
        
    end
end


--[[
function skill1level1:ReceiveBeginPlay()
    skill1level1.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function skill1level1:ReceiveTick(DeltaTime)
    skill1level1.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function skill1level1:ReceiveEndPlay()
    skill1level1.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function skill1level1:GetReplicatedProperties()
    return
end
--]]

--[[
function skill1level1:GetAvailableServerRPCs()
    return
end
--]]

return skill1level1