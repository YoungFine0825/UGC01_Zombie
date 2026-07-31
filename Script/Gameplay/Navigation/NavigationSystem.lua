---@class Gameplay.NavigationSystem:Gameplay.IGameplaySystem
local NavigationSystem = LuaClass("Gameplay.NavigationSystem")

function NavigationSystem:Ctor()
    ---@type number 增量构建倒计时帧数（0=无待处理，>0=倒计时中）
    self.m_RebuildCountdown = 0
    ---@type FName 导航 Agent 名称
    self.m_AgentName = "Mannequin"
end

---@public 添加导航动态影响区域，并在下一帧自动触发增量构建
--- 可在同一帧内多次调用，内部自动合并为一次 AsyncIncrementalBuild
---@param InBounds FBox 影响区域包围盒
---@return boolean 是否成功添加动态影响区域
function NavigationSystem:AddDynamicNavAffect(InBounds)
    if not UGCGameSystem.IsServer() then
        return false
    end
    local agentName = AgentName or self.m_AgentName
    local worldContext = UGCGameSystem.GetGameState()
    local bSuccess = UGCNavigationSystem.AddDynamicNavAffect(worldContext, self.m_AgentName, InBounds)
    if not bSuccess then
        GameplayUtils.Exception("NavigationSystem.AddDynamicNavAffect: 添加动态影响区域失败")
        return false
    end

    self.m_RebuildCountdown = 2
    return true
end

---@public 立即触发增量构建（跳过待处理标记，直接构建）
---@param WorldContext UObject 世界上下文
---@param AgentName FName|nil 导航 Agent 名称
---@return boolean
function NavigationSystem:FlushRebuild(WorldContext, AgentName)
    self.m_RebuildCountdown = 0
    local agentName = AgentName or self.m_AgentName
    local worldContext = WorldContext or UGCGameSystem.GetGameState()
    return UGCNavigationSystem.AsyncIncrementalBuild(worldContext, agentName)
end

---@private 服务端 Tick：在 m_bPendingRebuild 为 true 的下一帧执行 AsyncIncrementalBuild
---@param DeltaTime number
function NavigationSystem:OnServerTick(DeltaTime)
    if self.m_RebuildCountdown <= 0 then
        return
    end
    self.m_RebuildCountdown = self.m_RebuildCountdown - 1
    if self.m_RebuildCountdown > 0 then
        return
    end

    local worldContext = UGCGameSystem.GetGameState()
    if not worldContext then
        GameplayUtils.Exception("NavigationSystem.OnServerTick: 无法获取 GameState")
        return
    end

    if not UGCNavigationSystem.AsyncIncrementalBuild(worldContext, self.m_AgentName) then
        GameplayUtils.Exception("NavigationSystem.OnServerTick: AsyncIncrementalBuild 失败")
    end
end

return NavigationSystem
