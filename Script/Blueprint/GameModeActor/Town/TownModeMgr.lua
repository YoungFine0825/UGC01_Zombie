---@class TownModeMgr_C:UGCLevelActorMgr
--Edit Below--
local TownModeMgr = {}
 
--[[
function TownModeMgr:ReceiveBeginPlay()
    TownModeMgr.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function TownModeMgr:ReceiveTick(DeltaTime)
    TownModeMgr.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function TownModeMgr:ReceiveEndPlay()
    TownModeMgr.SuperClass.ReceiveEndPlay(self) 
end
--]]

return TownModeMgr