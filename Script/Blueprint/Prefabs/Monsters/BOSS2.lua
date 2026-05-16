---@class BOSS2_C:BP_UGC_GenericMobPawn_Base_C
---@field HitBox UCapsuleComponent
--Edit Below--
local BOSS2 = 
{
    LuaLogicPart = nil,
    MonsterID = 10001,
    MonsterType = 'Monster',
}
 

function BOSS2:ReceiveBeginPlay()
    ugcprint("BOSS2:ReceiveBeginPlay")
    BOSS2.SuperClass.ReceiveBeginPlay(self)

    self.LuaLogicPart = UGCGameSystem.UGCRequire("Script.Blueprint.Prefabs.Monsters.LuaMonsterLogicPart"):New()
    self.LuaLogicPart.Owner = self
    self.LuaLogicPart:ReceiveBeginPlay()
end


--[[
function BOSS2:ReceiveTick(DeltaTime)
    BOSS2.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BOSS2:ReceiveEndPlay()
    BOSS2.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BOSS2:GetReplicatedProperties()
    return
end
--]]

--[[
function BOSS2:GetAvailableServerRPCs()
    return
end
--]]


function BOSS2:BPDie(Damage, Killer, DamageCauser, DamageEvent, DamageTypeID)
    ugcprint("BOSS2:BPDie")
    self.LuaLogicPart:BPDie(Damage, Killer, DamageCauser, DamageEvent, DamageTypeID)
end

return BOSS2