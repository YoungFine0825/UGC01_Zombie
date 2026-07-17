---@class GymModeMgr_C:UGCLevelActorMgr
--Edit Below--
local GymModeMgr = {}
 
--[[
function GymModeMgr:ReceiveBeginPlay()
    GymModeMgr.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function GymModeMgr:ReceiveTick(DeltaTime)
    GymModeMgr.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function GymModeMgr:ReceiveEndPlay()
    GymModeMgr.SuperClass.ReceiveEndPlay(self) 
end
--]]

return GymModeMgr