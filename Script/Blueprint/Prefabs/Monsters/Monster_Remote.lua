---@class Monster_Remote_C:BP_UGC_GenericMobPawn_Base_C
---@field HitBox UCapsuleComponent
--Edit Below--
local Monster_Remote = 
{
    LuaLogicPart = nil,
    MonsterID = 10001,
    MonsterType = 'Monster',
}
 

function Monster_Remote:ReceiveBeginPlay()
    ugcprint("Monster_Remote:ReceiveBeginPlay")
    Monster_Remote.SuperClass.ReceiveBeginPlay(self)

    self.LuaLogicPart = UGCGameSystem.UGCRequire("Script.Blueprint.Prefabs.Monsters.LuaMonsterLogicPart"):New()
    self.LuaLogicPart.Owner = self
    self.LuaLogicPart:ReceiveBeginPlay()
end


--[[
function Monster_Remote:ReceiveTick(DeltaTime)
    Monster_Remote.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function Monster_Remote:ReceiveEndPlay()
    Monster_Remote.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function Monster_Remote:GetReplicatedProperties()
    return
end
--]]

--[[
function Monster_Remote:GetAvailableServerRPCs()
    return
end
--]]


function Monster_Remote:BPDie(Damage, Killer, DamageCauser, DamageEvent, DamageTypeID)
    ugcprint("Monster_Remote:BPDie")
    self.LuaLogicPart:BPDie(Damage, Killer, DamageCauser, DamageEvent, DamageTypeID)
end

return Monster_Remote