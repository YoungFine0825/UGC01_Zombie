---@class skillAlevel1_C:UniversalProjectileBase
---@field ParticleSystem UParticleSystemComponent
---@field M18 UStaticMeshComponent
---@field Sphere USphereComponent
---@field CameraShakeRange float
---@field PlayerPawn UClass
---@field CameraShakeTime float
---@field CameraShakeScale float
--Edit Below--
local skillAlevel1 = {}
 
function skillAlevel1:ReceiveOnImpact(ImpactResult)
    ugcprint("skillAlevel1:ReceiveOnImpact")
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

function skillAlevel1:ReceiveLaunchBullet()
    skillAlevel1.SuperClass.ReceiveLaunchBullet(self)

    ugcprint("skillAlevel1:ReceiveLaunchBullet")
end

function skillAlevel1:OnImpactSpawnActor(ImpactResult)
    ugcprint("skillAlevel1:OnImpactSpawnActor")
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
function skillAlevel1:ReceiveBeginPlay()
    skillAlevel1.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function skillAlevel1:ReceiveTick(DeltaTime)
    skillAlevel1.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function skillAlevel1:ReceiveEndPlay()
    skillAlevel1.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function skillAlevel1:GetReplicatedProperties()
    return
end
--]]

--[[
function skillAlevel1:GetAvailableServerRPCs()
    return
end
--]]

return skillAlevel1