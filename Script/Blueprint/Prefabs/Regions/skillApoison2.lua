---@class skillApoison2_C:AActor
---@field ParticleSystem UParticleSystemComponent
---@field Box UBoxComponent
---@field DefaultSceneRoot USceneComponent
---@field Interval float
---@field DamageValue float
---@field PlayerPawn UClass
--Edit Below--
local skillApoison2 = {
    timer = 0,
    BuffClass = nil
}


function skillApoison2:ReceiveBeginPlay()
    --skillApoison2.SuperClass.ReceiveBeginPlay(self)
    ugcprint("skillApoison2 Log:ReceiveBeginPlay()")

    -- Add Poisoned Buff
    self.BuffClass = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Prefabs/Buffs/Buff_Poisoned2.Buff_Poisoned2_C'))
    ugcprint("skillApoison2 Log:ReceiveBeginPlay() BuffClass as:"..tostring(self.BuffClass))
end


function skillApoison2:ReceiveTick(DeltaTime)
    --skillApoison2.SuperClass.ReceiveTick(self, DeltaTime)
    ugcprint("skillApoison2 Log:ReceiveTick()")

    if UGCActorComponentUtility.HasAuthority(self) then
        -- Every Interval seconds, apply damage to all actors in the box
        self.timer = self.timer + DeltaTime
        if self.timer >= self.Interval then
            self.timer = 0
           
            ugcprint("Server skillApoison2 Log:ReceiveTick()")

            local EnemyClass = UGCObjectUtility.LoadClass("/Script/UGCGame.UGCMobCharacter")
            ugcprint("skillApoison2:ReceiveTick EnemyClass:"..tostring(EnemyClass))

            local OverlapResults = UGCSceneQueryUtility.QueryOverlapActorsBySphereWithFinder(self, self, self:K2_GetActorLocation(), 500, ECollisionChannel.ECC_Pawn)
            ugcprint("OutActors skillApoison2 Count:".. tostring(#OverlapResults))

            for i = 1, OverlapResults:Num() do
                local OverlapHitResult = OverlapResults:Get(i)
                local OverlapActor = OverlapHitResult.Actor:Get()
                ugcprint("OverlapActor skillApoison2:"..tostring(OverlapActor))

                if UGCObjectUtility.IsA(OverlapActor, EnemyClass) then
                    ugcprint("Enemy OverlapActor skillApoison2:"..tostring(OverlapActor))

                    UGCPersistEffectSystem.AddBuffByClass(OverlapActor, self.BuffClass, UGCActorComponentUtility.GetOwner(self), -1, 1)
                end
            end

        end
    end
end



-- function skillApoison2:ReceiveEndPlay()
--     skillApoison2.SuperClass.ReceiveEndPlay(self) 
-- end


--[[
function skillApoison2:GetReplicatedProperties()
    return
end
--]]

--[[
function skillApoison2:GetAvailableServerRPCs()
    return
end
--]]


return skillApoison2