---@class BP_PlayerInGameStatDataComponent_C:ActorComponent
local BP_PlayerInGameStatDataComponent = {}

--[[--]]
function BP_PlayerInGameStatDataComponent:ReceiveBeginPlay()
    BP_PlayerInGameStatDataComponent.SuperClass.ReceiveBeginPlay(self)
    ---@type UGCPlayerState_C
    self.m_playerState = UGCActorComponentUtility.GetOwner(self)
end


--[[
function BP_PlayerInGameStatDataComponent:ReceiveTick(DeltaTime)
    BP_PlayerInGameStatDataComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_PlayerInGameStatDataComponent:ReceiveEndPlay()
    BP_PlayerInGameStatDataComponent.SuperClass.ReceiveEndPlay(self) 
end
--]]

--function BP_PlayerInGameStatDataComponent:GetReplicatedProperties()
--    return
--end

---@public
function BP_PlayerInGameStatDataComponent:RepLazyProperties()

end

---@public
---@return number
function BP_PlayerInGameStatDataComponent:AddStatData(Key,Value)
    local pawn = UGCGameSystem.GetPlayerPawnByPlayerState(self.m_playerState)
    local curValue = UGCAttributeSystem.GetGameAttributeValue(pawn,Key)
    local newValue = math.max(0,curValue + Value)
    UGCAttributeSystem.SetGameAttributeValue(pawn,Key,newValue)
    GameplayUtils.Print("BP_PlayerInGameStatDataComponent.AddStatData: ",Key," + ",Value)
    GameplayUtils.Print("BP_PlayerInGameStatDataComponent.AddStatData: ",Key," = ",UGCAttributeSystem.GetGameAttributeValue(pawn,Key))
    return newValue
end

---@public
---@return number
function BP_PlayerInGameStatDataComponent:GetStatData(Key)
    local pawn = UGCGameSystem.GetPlayerPawnByPlayerState(self.m_playerState)
    local data = UGCAttributeSystem.GetGameAttributeValue(pawn,Key)
    return data
end

---@public
function BP_PlayerInGameStatDataComponent:SetStatData(Key,Value)
    local pawn = UGCGameSystem.GetPlayerPawnByPlayerState(self.m_playerState)
    UGCAttributeSystem.SetGameAttributeValue(pawn,Key,Value)
end

---@public
function BP_PlayerInGameStatDataComponent:ClearAllStatData()

end

return BP_PlayerInGameStatDataComponent