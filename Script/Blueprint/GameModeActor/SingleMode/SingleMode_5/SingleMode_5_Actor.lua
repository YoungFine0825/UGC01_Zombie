---@class SingleMode_5_Actor_C:UGCLevelActor
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local SingleMode_5_Actor = {}
 
function SingleMode_5_Actor:ReceiveBeginPlay()

    SingleMode_5_Actor.SuperClass.ReceiveBeginPlay(self)

    if UGCGameSystem.IsServer() then

        ugcprint(string.format("SingleMode_5_Actor:ReceiveBeginPlay Not Client"))

    else      

        self.ChangeMapTimer = UGCTimerUtility.CreateLuaTimer(0.5, 
            function()
                local MapPath = self.MiniMapConfig.MapPath
                local MapCentre = self.MiniMapConfig.MapCentre
                local MapSize = self.MiniMapConfig.MapSize
                local MapScale = self.MiniMapConfig.MapScale

                local IsChanegeMapSuccess = UGCWidgetManagerSystem.ChangeMap(UGCGameSystem.GetUGCResourcesFullPath(MapPath), MapCentre, MapSize, MapScale)
                ugcprint(string.format("SingleMode_5_Actor:ReceiveBeginPlay ChangeMap is %s", tostring(IsChanegeMapSuccess)))
            end
        , false)

    end

end

-- function SingleMode_5_Actor:ReceiveTick(DeltaTime)
--     SingleMode_5_Actor.SuperClass.ReceiveTick(self, DeltaTime)
-- end

function SingleMode_5_Actor:ReceiveEndPlay()

    SingleMode_5_Actor.SuperClass.ReceiveEndPlay(self) 

    if UGCGameSystem.IsServer() then

        local AllPlayer = UGCLevelFlowSystem.GetAllPlayerControllerInCurrentLevel()
        if AllPlayer and #AllPlayer > 0 then
            for k, Player in pairs(AllPlayer) do
                Player:CallShutDownShop()
            end
        else
            ugcprint("SingleMode_5_Actor:ReceiveEndPlay AllPlayer is nil")
        end

    else

        ugcprint("SingleMode_5_Actor:ReceiveEndPlay Not Server")

    end
    
end

--[[
function SingleMode_5_Actor:GetReplicatedProperties()
    return
end
--]]

--[[
function SingleMode_5_Actor:GetAvailableServerRPCs()
    return
end
--]]

return SingleMode_5_Actor