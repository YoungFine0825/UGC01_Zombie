---@class SingleMode_6_Actor_C:UGCLevelActor
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local SingleMode_6_Actor = {}
 
function SingleMode_6_Actor:ReceiveBeginPlay()

    SingleMode_6_Actor.SuperClass.ReceiveBeginPlay(self)

    if UGCGameSystem.IsServer() then

        ugcprint(string.format("SingleMode_6_Actor:ReceiveBeginPlay Not Client"))

    else      

        self.ChangeMapTimer = UGCTimerUtility.CreateLuaTimer(0.5, 
            function()
                local MapPath = self.MiniMapConfig.MapPath
                local MapCentre = self.MiniMapConfig.MapCentre
                local MapSize = self.MiniMapConfig.MapSize
                local MapScale = self.MiniMapConfig.MapScale

                local IsChanegeMapSuccess = UGCWidgetManagerSystem.ChangeMap(UGCGameSystem.GetUGCResourcesFullPath(MapPath), MapCentre, MapSize, MapScale)
                ugcprint(string.format("SingleMode_6_Actor:ReceiveBeginPlay ChangeMap is %s", tostring(IsChanegeMapSuccess)))
            end
        , false)

    end

end

-- function SingleMode_6_Actor:ReceiveTick(DeltaTime)
--     SingleMode_6_Actor.SuperClass.ReceiveTick(self, DeltaTime)
-- end

-- function SingleMode_6_Actor:ReceiveEndPlay()
--     SingleMode_6_Actor.SuperClass.ReceiveEndPlay(self) 
-- end

--[[
function SingleMode_6_Actor:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleMode_6_Actor:GetAvailableServerRPCs()
    return
end
--]]

return SingleMode_6_Actor