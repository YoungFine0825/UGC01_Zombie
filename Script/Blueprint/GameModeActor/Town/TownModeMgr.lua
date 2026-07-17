---@class TownModeMgr_C:UGCLevelActorMgr
--Edit Below--
local TownModeMgr = {}
 
--[[--]]
function TownModeMgr:ReceiveBeginPlay()
    TownModeMgr.SuperClass.ReceiveBeginPlay(self)
    GameplayUtils.Print("TownModeMgr.ReceiveBeginPlay")
end


--[[
function TownModeMgr:ReceiveTick(DeltaTime)
    TownModeMgr.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function TownModeMgr:ReceiveEndPlay()
    TownModeMgr.SuperClass.ReceiveEndPlay(self)
    GameplayUtils.Print("TownModeMgr.ReceiveEndPlay")
end


return TownModeMgr