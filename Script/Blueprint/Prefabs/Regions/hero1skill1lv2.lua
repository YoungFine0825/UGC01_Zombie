---@class hero1skill1lv2_C:AActor
---@field ParticleSystem UParticleSystemComponent
---@field Box UBoxComponent
---@field DefaultSceneRoot USceneComponent
---@field Interval float
---@field DamageValue float
---@field Pawn UClass
---@field BoxScale FVector
---@field Orientation FRotator
--Edit Below--
local hero1skill1lv2 = {
    -- PEBuffClassPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/PESkill/PoisonGasGrenade/PEBuff_Poison.PEBuff_Poison_C'),
    -- PEBuffClassPath = "Asset/Blueprint/PESkill/PoisonGasGrenade/hero1skill1lv2.hero1skill1lv2_C",
    -- PEBuffClass_Poision = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath('Asset/Skill/ToxicGrenade/PEBuff_Poison.PEBuff_Poison_C')),
    -- PEBuffClass_DamageIncrease = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath('Asset/Skill/ToxicGrenade/PEBuff_DamageIncrease.PEBuff_DamageIncrease_C')),
    TimeDelegate = nil,
    TimeHandle = nil,
    CameraShakePawnList = {}
}


function hero1skill1lv2:ReceiveBeginPlay()
    hero1skill1lv2.SuperClass.ReceiveBeginPlay(self)
   
    print("hero1skill1lv2 Log:ReceiveBeginPlay()")
    local HitLocation = UGCActorComponentUtility.GetActorTransform(self).Translation;
    --[[ 生成在怪物旁边时，如果怪物未移动那么 通过GetOverLlappingActors获取不到任何对象。采用其他方式
    if UGCActorComponentUtility.HasAuthority(self) then
        self.TimeHandle, self.TimerDelegate =  UGCGameSystem.SetTimer(self,
        function ()
            print("hero1skill1lv2 Log: In [TimerTriggerFunc]")
            local OverlappingActors = {}
            self.Box:GetOverlappingActors(OverlappingActors)
            
            for k, OverlappingActor in pairs(OverlappingActors) do
                if UGCObjectUtility.IsObjectValid(self:GetInstigator()) then
                    print("hero1skill1lv2 Log: --Character:"..tostring(self:GetInstigator()))
                    if OverlappingActor ~= self:GetInstigator() then
                        print("hero1skill1lv2: Log --DamageValue:"..tostring(self.DamageValue))
                        local Damage = UGCGameSystem.ApplyDamage(OverlappingActor, self.DamageValue, self:GetInstigator():GetPlayerControllerSafety(), self, nil)
                        print("hero1skill1lv2: Log --Damage:"..tostring(Damage))
                    end
                else
                    local Damage = UGCGameSystem.ApplyDamage(OverlappingActor, self.DamageValue, nil, self, nil)
                end
            end
        end,
        self.Interval,
        true)
    end
    ]]

    if UGCActorComponentUtility.HasAuthority(self) then
        self.TimeHandle, self.TimerDelegate =  UGCGameSystem.SetTimer(self,
        function ()
            print("hero1skill1lv2 Log: In [TimerTriggerFunc]")
            local  DrawDebugTrace = EDrawDebugTrace.ForDuration
            local OutHits = {}
            local bHit = UGCSceneQueryUtility.QueryByBoxMultiForObjects(
                self,
                HitLocation,
                HitLocation,
                self.BoxScale,
                self.Orientation,
                {EObjectTypeQuery.ObjectTypeQuery3},
                false,
                {},
                EDrawDebugTrace.None,
                OutHits,
                true
            )
          
          
            if bHit then
                for k, v in pairs(OutHits) do
                    if v.Actor:IsValid() then
                        local OverlappingActor = v.Actor:Get()
                        if UGCObjectUtility.IsA(v.Actor:Get(),self.Pawn) then
                            if UGCObjectUtility.IsObjectValid(UGCAttributeSystem.GetInstigatorFromContext(self)) then
                                print("hero1skill1lv2 Log: --Character:"..tostring(UGCAttributeSystem.GetInstigatorFromContext(self)))
                                if OverlappingActor ~= UGCAttributeSystem.GetInstigatorFromContext(self) then
                                    print("hero1skill1lv2: Log --DamageValue:"..tostring(self.DamageValue))
                                    local Damage = UGCGameSystem.ApplyDamage(OverlappingActor, self.DamageValue, UGCGameSystem.GetPlayerControllerByPlayerPawn(UGCAttributeSystem.GetInstigatorFromContext(self)), self, nil)
                                    print("hero1skill1lv2: Log --Damage:"..tostring(Damage))
                                end
                            else
                                local Damage = UGCGameSystem.ApplyDamage(OverlappingActor, self.DamageValue, nil, self, nil)
                            end
                        end
                    end
                end
            end
        end,
        self.Interval,
        true)
    end
    
end


-- function hero1skill1lv2:ReceiveTick(DeltaTime)
--     hero1skill1lv2.SuperClass.ReceiveTick(self, DeltaTime)
-- end



function hero1skill1lv2:ReceiveEndPlay()
    hero1skill1lv2.SuperClass.ReceiveEndPlay(self) 
    UGCTimerUtility.RemoveUETimer(self.TimeHandle);
end


--[[
function hero1skill1lv2:GetReplicatedProperties()
    return
end
--]]

--[[
function hero1skill1lv2:GetAvailableServerRPCs()
    return
end
--]]


return hero1skill1lv2