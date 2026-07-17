---@class BP_Zombie_01_C:BP_Zombie_Base_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Zombie_01_C
local BP_Zombie_01 = BPExtent({},'Script.Blueprint.Prefabs.Monsters.BP_Zombie_Base')

-- function BP_Zombie_01:ReceiveBeginPlay()
--     BP_Zombie_01.SuperClass.ReceiveBeginPlay(self)
-- end

-- function BP_Zombie_01:ReceiveTick(DeltaTime)
--     BP_Zombie_01.SuperClass.ReceiveTick(self, DeltaTime)
-- end

-- function BP_Zombie_01:ReceiveEndPlay()
--     BP_Zombie_01.SuperClass.ReceiveEndPlay(self) 
-- end

-- function BP_Zombie_01:GetReplicatedProperties()
--     return
-- end

return BP_Zombie_01