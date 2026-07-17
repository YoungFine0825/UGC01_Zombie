--[[
        局内游戏状态组件，挂在GameState上
--]]
---@class BP_GameplayStateComponent
---@field GameStateInfo Gameplay.GameStateInfo
---@field RoundFlowInfo Gameplay.RoundFlowInfo
local BP_GameplayStateComponent = {
    ---@type Gameplay.GameStateInfo
    GameStateInfo = UGCGameSystem.UGCRequire("Script.Gameplay.Core.GameStateInfo"),
    ---@type Gameplay.RoundFlowInfo
    RoundFlowInfo = UGCGameSystem.UGCRequire("Script.Gameplay.Core.RoundFlowInfo"),
}
 
--[[--]]
function BP_GameplayStateComponent:ReceiveBeginPlay()
    BP_GameplayStateComponent.SuperClass.ReceiveBeginPlay(self)
end


--[[
function BP_GameplayStateComponent:ReceiveTick(DeltaTime)
    BP_GameplayStateComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_GameplayStateComponent:ReceiveEndPlay()
    BP_GameplayStateComponent.SuperClass.ReceiveEndPlay(self) 
end
--]]

function BP_GameplayStateComponent:GetReplicatedProperties()
   return {"GameStateInfo", "Lazy"},
   {"RoundFlowInfo", "Lazy"}
end

---@public
function BP_GameplayStateComponent:RepLazyProperties()
    UnrealNetwork.RepLazyProperty(self,"GameStateInfo")
    UnrealNetwork.RepLazyProperty(self,"RoundFlowInfo")
end

---@public
function BP_GameplayStateComponent:RepLazyProperty(propertyName)
    if self[propertyName] == nil then
        return false
    end
    UnrealNetwork.RepLazyProperty(self,propertyName)
end

---@protected 生效范围 Client
function BP_GameplayStateComponent:OnRep_GameStateInfo()
    -- GameplayUtils.Print("BP_GameplayStateComponent.OnRep_GameStateInfo: 当前游戏状态：",self.GameStateInfo.GameState)
    --广播事件
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Client.OnGameStateChanged)
end

---@protected 生效范围 Client
function BP_GameplayStateComponent:OnRep_RoundFlowInfo()
    -- GameplayUtils.Print("BP_GameplayStateComponent.OnRep_RoundFlowInfo: 当前回合阶段：",self.RoundFlowInfo.RoundPhase)
    --广播事件
    GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Client.OnRoundFlowChanged)
end

return BP_GameplayStateComponent