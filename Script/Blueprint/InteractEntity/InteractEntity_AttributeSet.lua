---@class InteractEntity_AttributeSet_C:BlueprintableDataAsset
---@field Attributes ULuaArrayHelper<FStruct_InteractEntityAttribute__pf966240085>
--Edit Below--
local InteractEntity_AttributeSet = {}
 
--[[
function InteractEntity_AttributeSet:ReceiveBeginPlay()
    InteractEntity_AttributeSet.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function InteractEntity_AttributeSet:ReceiveTick(DeltaTime)
    InteractEntity_AttributeSet.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function InteractEntity_AttributeSet:ReceiveEndPlay()
    InteractEntity_AttributeSet.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function InteractEntity_AttributeSet:GetReplicatedProperties()
    return
end
--]]

--[[
function InteractEntity_AttributeSet:GetAvailableServerRPCs()
    return
end
--]]

return InteractEntity_AttributeSet