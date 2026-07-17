---@class BP_Zombie_02_C:BP_Zombie_Base_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Zombie_02_C
local BP_Zombie_02 = BPExtent({},'Script.Blueprint.Prefabs.Monsters.BP_Zombie_Base')

-- function BP_Zombie_02:ReceiveBeginPlay()
--     BP_Zombie_02.SuperClass.ReceiveBeginPlay(self)
-- end

-- function BP_Zombie_02:ReceiveTick(DeltaTime)
--     BP_Zombie_02.SuperClass.ReceiveTick(self, DeltaTime)
-- end

-- function BP_Zombie_02:ReceiveEndPlay()
--     BP_Zombie_02.SuperClass.ReceiveEndPlay(self) 
-- end

-- function BP_Zombie_02:GetReplicatedProperties()
--     return
-- end

return BP_Zombie_02