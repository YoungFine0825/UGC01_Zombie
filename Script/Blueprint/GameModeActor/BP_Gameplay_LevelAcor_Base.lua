---@class BP_Gameplay_LevelAcor_Base_C:UGCLevelActor
---@field DefaultSceneRoot USceneComponent
---@field PlayerInitScore float
--Edit Below--
---@type BP_Gameplay_LevelAcor_Base_C
local BP_Gameplay_LevelAcor_Base = {

}
 
--[[--]]
function BP_Gameplay_LevelAcor_Base:ReceiveBeginPlay()
    BP_Gameplay_LevelAcor_Base.SuperClass.ReceiveBeginPlay(self)

    GameplayUtils.Print("UGCLevelActor.ReceiveBeginPlay: Enter game mode ",UGCMultiMode.GetModeID())

    if UGCGameSystem.IsServer() then
        local MsgSys = UGCGenericMessageSystem
        local SpawnMessage = MsgSys.Messages.UGC.PlayerPawn.PawnSpawn
        MsgSys.ListenGlobalMessage(self, SpawnMessage, self, self.OnPlayerSpawn)
    end
end


--[[--]]
function BP_Gameplay_LevelAcor_Base:ReceiveTick(DeltaTime)
    if BP_Gameplay_LevelAcor_Base.SuperClass then
        BP_Gameplay_LevelAcor_Base.SuperClass.ReceiveTick(self, DeltaTime)
    end
end


--[[--]]
function BP_Gameplay_LevelAcor_Base:ReceiveEndPlay()
    BP_Gameplay_LevelAcor_Base.SuperClass.ReceiveEndPlay(self)
    GameplayUtils.Print("UGCLevelActor.ReceiveBeginPlay: Exit game mode ",UGCMultiMode.GetModeID())
    if UGCGameSystem.IsServer() then
        local MsgSys = UGCGenericMessageSystem
        MsgSys.UnListenMessage(self,UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnSpawn)
    end
end

--[[
function BP_Gameplay_LevelAcor_Base:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_Gameplay_LevelAcor_Base:GetAvailableServerRPCs()
    return
end
--]]

---@protected 子类可重载该函数，返回指定玩法组件
---@return BP_ServerGameplayComponent_C
function BP_Gameplay_LevelAcor_Base:GetServerGameplayComponentInternal()
    return self.ServerGameplayComponent
end

---@public
---@return BP_ServerGameplayComponent_C
function BP_Gameplay_LevelAcor_Base:GetServerGameplayComponent()
    if UGCGameSystem.IsServer() then--只在是服务端时返回组件
        return self:GetServerGameplayComponentInternal()
    end
end

---@protected
function BP_Gameplay_LevelAcor_Base:OnPlayerSpawn(PlayerKey)
    local initSocre = math.max(0,self.PlayerInitScore)
    if initSocre > 0 then
        GameplaySystem.PlayerSystem:AddPlayerScore(PlayerKey,initSocre)
    end
end

return BP_Gameplay_LevelAcor_Base