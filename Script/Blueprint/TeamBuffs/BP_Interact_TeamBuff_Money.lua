---@class BP_Interact_TeamBuff_Money_C:BP_Interact_TeamBuff_C
---@field InteractBehaviour_Grant InteractBehaviour_Grant_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type BP_Interact_TeamBuff_Money_C
local BP_Interact_TeamBuff_Money = BPExtent({},"Script.Blueprint.TeamBuffs.BP_Interact_TeamBuff")
 
--[[--]]
function BP_Interact_TeamBuff_Money:ReceiveBeginPlay()
    BP_Interact_TeamBuff_Money.SuperClass.ReceiveBeginPlay(self)
end


--[[
function BP_Interact_TeamBuff_Money:ReceiveTick(DeltaTime)
    BP_Interact_TeamBuff_Money.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function BP_Interact_TeamBuff_Money:ReceiveEndPlay()
    BP_Interact_TeamBuff_Money.SuperClass.ReceiveEndPlay(self) 
end


--[[
function BP_Interact_TeamBuff_Money:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Interact_TeamBuff_Money:GetAvailableServerRPCs()
    return
end
--]]

return BP_Interact_TeamBuff_Money