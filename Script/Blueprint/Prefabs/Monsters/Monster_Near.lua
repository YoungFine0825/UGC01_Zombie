---@class Monster_Near_C:BP_UGC_GenericMobPawn_Base_C
---@field HitBox UCapsuleComponent
--Edit Below--
local Monster_Near = 
{
    LuaLogicPart = nil,
    MonsterID = 10001,
    MonsterType = 'Monster',
}
 

function Monster_Near:ReceiveBeginPlay()
    ugcprint("Monster_Near:ReceiveBeginPlay")
    Monster_Near.SuperClass.ReceiveBeginPlay(self)
    self.bVaultIsOpen = true
    self.LuaLogicPart = UGCGameSystem.UGCRequire("Script.Blueprint.Prefabs.Monsters.LuaMonsterLogicPart"):New()
    self.LuaLogicPart.Owner = self
    self.LuaLogicPart:ReceiveBeginPlay()
end


--[[
function Monster_Near:ReceiveTick(DeltaTime)
    Monster_Near.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function Monster_Near:ReceiveEndPlay()
    Monster_Near.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function Monster_Near:GetReplicatedProperties()
    return
end
--]]

--[[
function Monster_Near:GetAvailableServerRPCs()
    return
end
--]]


function Monster_Near:BPDie(Damage, Killer, DamageCauser, DamageEvent, DamageTypeID)
    ugcprint("Monster_Near:BPDie")
    self.LuaLogicPart:BPDie(Damage, Killer, DamageCauser, DamageEvent, DamageTypeID)
end

return Monster_Near