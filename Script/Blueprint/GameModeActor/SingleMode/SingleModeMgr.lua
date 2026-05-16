---@class SingleModeMgr_C:UGCLevelActorMgr
--Edit Below--
local SingleModeMgr = {}
 
--[[
function SingleModeMgr:ReceiveBeginPlay()
    SingleModeMgr.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SingleModeMgr:ReceiveTick(DeltaTime)
    SingleModeMgr.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SingleModeMgr:ReceiveEndPlay()
    SingleModeMgr.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SingleModeMgr:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleModeMgr:GetAvailableServerRPCs()
    return
end
--]]

return SingleModeMgr