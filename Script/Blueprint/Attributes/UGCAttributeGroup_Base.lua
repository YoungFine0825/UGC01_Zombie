---@class UGCAttributeGroup_Base_C:GameAttributeGroup
--Edit Below--
local UGCAttributeGroup_Base = {}
 
--[[
function UGCAttributeGroup_Base:ReceiveBeginPlay()
    UGCAttributeGroup_Base.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function UGCAttributeGroup_Base:ReceiveTick(DeltaTime)
    UGCAttributeGroup_Base.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function UGCAttributeGroup_Base:ReceiveEndPlay()
    UGCAttributeGroup_Base.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function UGCAttributeGroup_Base:GetReplicatedProperties()
    return
end
--]]

--[[
function UGCAttributeGroup_Base:GetAvailableServerRPCs()
    return
end
--]]

function UGCAttributeGroup_Base:GetTestOne_Override(OriginalValue, AttributeOwnerActor)
    ugcprint("[UGCAttributeGroup_Base] GetTestOne_Override: ".. OriginalValue..", owner: ".. tostring(AttributeOwnerActor))

    -- if not AttributeOwnerActor then
        return OriginalValue
    -- end
    
    -- return 105
end

return UGCAttributeGroup_Base