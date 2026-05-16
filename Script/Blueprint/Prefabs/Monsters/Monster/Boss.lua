---@class BOSS_C:BP_UGC_GenericMobPawn_Base_C
---@field HitBox UCapsuleComponent
--Edit Below--
local BOSS = 
{
    LuaLogicPart = nil,
    MonsterID = 10001,
    MonsterType = 'Monster',
}
 

function BOSS:ReceiveBeginPlay()
    ugcprint("BOSS:ReceiveBeginPlay")
    BOSS.SuperClass.ReceiveBeginPlay(self)

    self.LuaLogicPart = UGCGameSystem.UGCRequire("Script.Blueprint.Prefabs.Monsters.LuaMonsterLogicPart"):New()
    self.LuaLogicPart.Owner = self
    self.LuaLogicPart:ReceiveBeginPlay()
end


--[[
function BOSS:ReceiveTick(DeltaTime)
    BOSS.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BOSS:ReceiveEndPlay()
    BOSS.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BOSS:GetReplicatedProperties()
    return
end
--]]

--[[
function BOSS:GetAvailableServerRPCs()
    return
end
--]]


function BOSS:BPDie(Damage, Killer, DamageCauser, DamageEvent, DamageTypeID)
    ugcprint("BOSS:BPDie")
    self.LuaLogicPart:BPDie(Damage, Killer, DamageCauser, DamageEvent, DamageTypeID)
end

return BOSS