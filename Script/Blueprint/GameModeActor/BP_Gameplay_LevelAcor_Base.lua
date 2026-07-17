---@class BP_Gameplay_LevelAcor_Base_C:UGCLevelActor
---@field DefaultSceneRoot USceneComponent
--Edit Below--
---@type BP_Gameplay_LevelAcor_Base_C
local BP_Gameplay_LevelAcor_Base = {

}
 
--[[--]]
function BP_Gameplay_LevelAcor_Base:ReceiveBeginPlay()
    BP_Gameplay_LevelAcor_Base.SuperClass.ReceiveBeginPlay(self)

    GameplayUtils.Print("UGCLevelActor.ReceiveBeginPlay: Enter game mode ",UGCMultiMode.GetModeID())
end


--[[--]]
function BP_Gameplay_LevelAcor_Base:ReceiveTick(DeltaTime)
    BP_Gameplay_LevelAcor_Base.SuperClass.ReceiveTick(self, DeltaTime)
end


--[[--]]
function BP_Gameplay_LevelAcor_Base:ReceiveEndPlay()
    BP_Gameplay_LevelAcor_Base.SuperClass.ReceiveEndPlay(self)
    GameplayUtils.Print("UGCLevelActor.ReceiveBeginPlay: Exit game mode ",UGCMultiMode.GetModeID())
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

return BP_Gameplay_LevelAcor_Base