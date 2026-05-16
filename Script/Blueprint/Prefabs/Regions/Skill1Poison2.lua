---@class Skill1Poison2_C:AActor
---@field ParticleSystem UParticleSystemComponent
---@field Box UBoxComponent
---@field DefaultSceneRoot USceneComponent
---@field Interval float
---@field PoisonedBuff UClass
--Edit Below--
local Skill1Poison1 = {
    timer = 0,
}


function Skill1Poison1:ReceiveBeginPlay()
    --Skill1Poison1.SuperClass.ReceiveBeginPlay(self)
    ugcprint("Skill1Poison1 Log:ReceiveBeginPlay()")
end


function Skill1Poison1:ReceiveTick(DeltaTime)
    --Skill1Poison1.SuperClass.ReceiveTick(self, DeltaTime)
    ugcprint("Skill1Poison1 Log:ReceiveTick()")

    if UGCActorComponentUtility.HasAuthority(self) then
        -- Every Interval seconds, apply damage to all actors in the box
        self.timer = self.timer + DeltaTime
        if self.timer >= self.Interval then
            self.timer = 0
           
            ugcprint("Server Skill1Poison1 Log:ReceiveTick()")

            local EnemyClass = UGCObjectUtility.LoadClass("/Script/UGCGame.UGCMobCharacter")
            ugcprint("Skill1Poison1:ReceiveTick EnemyClass:"..tostring(EnemyClass))

            local OverlapResults = UGCSceneQueryUtility.QueryOverlapActorsBySphereWithFinder(self, self, UGCActorComponentUtility.GetActorTransform(self).Translation, 500, ECollisionChannel.ECC_Pawn)
            ugcprint("OutActors Skill1Poison1 Count:".. tostring(#OverlapResults))

            for i = 1, OverlapResults:Num() do
                local OverlapHitResult = OverlapResults:Get(i)
                local OverlapActor = OverlapHitResult.Actor:Get()
                ugcprint("OverlapActor Skill1Poison1:"..tostring(OverlapActor))

                if UGCObjectUtility.IsA(OverlapActor, EnemyClass) then
                    ugcprint("Enemy OverlapActor Skill1Poison1:"..tostring(OverlapActor))

                    UGCPersistEffectSystem.AddBuffByClass(OverlapActor, self.PoisonedBuff, UGCActorComponentUtility.GetOwner(self), -1, 1)
                end
            end

        end
    end
end



-- function Skill1Poison1:ReceiveEndPlay()
--     Skill1Poison1.SuperClass.ReceiveEndPlay(self) 
-- end


--[[
function Skill1Poison1:GetReplicatedProperties()
    return
end
--]]

--[[
function Skill1Poison1:GetAvailableServerRPCs()
    return
end
--]]


return Skill1Poison1