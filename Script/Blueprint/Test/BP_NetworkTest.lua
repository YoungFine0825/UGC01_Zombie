---@class BP_NetworkTest_C:AActor
---@field TextRender UTextRenderComponent
---@field StaticMesh UStaticMeshComponent
---@field NetworkTestComponent BP_NetworkTestComponent_C
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local BP_NetworkTest = {}
 
--[[--]]
function BP_NetworkTest:ReceiveBeginPlay()
    BP_NetworkTest.SuperClass.ReceiveBeginPlay(self)
    GameplayUtils.Print("BP_NetworkTest ",UGCObjectUtility.GetObjectName(self)," ReceiveBeginPlay！！！")
end


--[[--]]
function BP_NetworkTest:ReceiveTick(DeltaTime)
    BP_NetworkTest.SuperClass.ReceiveTick(self, DeltaTime)
end


--[[
function BP_NetworkTest:ReceiveEndPlay()
    BP_NetworkTest.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_NetworkTest:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_NetworkTest:GetAvailableServerRPCs()
    return
end
--]]

return BP_NetworkTest