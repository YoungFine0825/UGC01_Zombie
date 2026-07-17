local Print = GameplayUtils.Print
local Exception = GameplayUtils.Exception

---@class Gameplay.MonsterAISystem
local MonsterAISystem = LuaClass("Gameplay.MonsterAISystem")

function MonsterAISystem:Ctor()
    ---@type BP_EntryForZombie_Base_C[]
    self.registeredZombieEntries = {}
end

---@public
function MonsterAISystem:IsZombieAlive(zombiePawn)
    return UGCGenericCharacterSystem.GetHealth(zombiePawn) > 0
end

---@public 查找直线距离最近的玩家 生效范围：服务器
---由于要获取玩家的Pawn，不保证任意时候调用该方法都能找到玩家，因为方法调用时可能玩家的Pawn还未生成。
---@param monsterPawn APawn
---@return APawn
function MonsterAISystem:ServerFindNearstPlayerAsTarget(monsterPawn)
    local allPlayers = UGCGameSystem.GetAllPlayerPawn()
    if not allPlayers or #allPlayers <= 0 then
        Exception("MonsterAISystem.FindNearstPlayerAsTarget: 获取在场玩家列表失败！")
        return nil
    end
    local minimumDis = math.maxinteger
    local ret = nil
    local monsterLocation = monsterPawn:K2_GetActorLocation()
    local playerSys = GameplaySystem.PlayerSystem
    local EAliveState = EPlayerAliveState
    for k,player in pairs(allPlayers) do
        local aliveState = playerSys:GetPlayerAliveState(player)
        if aliveState == EAliveState.Alive then
            local ppos = player:K2_GetActorLocation()
            local dis = UGCMathUtility.VSize(UGCMathUtility.SubtractVector(ppos,monsterLocation))
            if dis < minimumDis then
                minimumDis = dis
                ret = player
            end
        end
    end
    if ret then
        local playerKey = UGCGameSystem.GetPlayerKeyByPlayerPawn(ret)
        Print("MonsterAISystem.FindNearstPlayerAsTarget: 找到最近的玩家目标！playerkey ="..tostring(playerKey))
    else
        Exception("MonsterAISystem.FindNearstPlayerAsTarget: 未找到最近的玩家目标！")
    end
    return ret
end

---@public 查找直线距离最近的入口 生效范围：服务器
---由于要获取玩家的Pawn，不保证任意时候调用该方法都能找到玩家，因为方法调用时可能玩家的Pawn还未生成。
---@param monsterPawn APawn
---@param entries ULuaArrayHelper<BP_EntryForZombie_Base_C>|BP_EntryForZombie_Base_C[]
---@return BP_EntryForZombie_Base_C
function MonsterAISystem:ServerFindNearstEntry(monsterPawn,entries)
    local allEntries = entries or self:GetRegistredZombieEntries()
    local minimumDis = math.maxinteger
    local ret = nil
    local monsterLocation = monsterPawn:K2_GetActorLocation()
    -- 支持 ULuaArrayHelper 和 Lua table 两种类型
    if type(allEntries) == "userdata" and allEntries.Num then
        -- ULuaArrayHelper: 用索引遍历
        for i = 1, allEntries:Num() do
            local actor = allEntries:Get(i)
            if UE.IsValid(actor) then
                local ppos = actor:K2_GetActorLocation()
                local dis = UGCMathUtility.VSize(UGCMathUtility.SubtractVector(ppos, monsterLocation))
                if dis < minimumDis then
                    minimumDis = dis
                    ret = actor
                end
            end
        end
    else
        -- Lua table: 用 pairs 遍历
        if next(allEntries) == nil then
            Exception("MonsterAISystem.ServerFindNearstEntry: 获取关卡中丧尸入口Actor失败！")
            return nil
        end
        for k, actor in pairs(allEntries) do
            if UE.IsValid(actor) then
                local ppos = actor:K2_GetActorLocation()
                local dis = UGCMathUtility.VSize(UGCMathUtility.SubtractVector(ppos, monsterLocation))
                if dis < minimumDis then
                    minimumDis = dis
                    ret = actor
                end
            end
        end
    end
    if ret then
        Print("MonsterAISystem.ServerFindNearstEntry: 找到最近的入口！")
    else
        Exception("MonsterAISystem.ServerFindNearstEntry: 未找到最近的入口！")
    end
    return ret
end

---@public
---@param entryActor BP_EntryForZombie_Base_C
---@return boolean
function MonsterAISystem:RegisterZombieEntry(entryActor)
    if not UE.IsValid(entryActor) then
        return false
    end
    table.insert(self.registeredZombieEntries,entryActor)
    return true
end

---@public
---@param entryActor BP_EntryForZombie_Base_C
---@return boolean
function MonsterAISystem:UnregisterZombieEntry(entryActor)
    if not UE.IsValid(entryActor) then
        return false
    end
    for i = #self.registeredZombieEntries,1,-1 do
        if self.registeredZombieEntries[i] == entryActor then
            table.remove(self.registeredZombieEntries,i)
        end
    end
    GameplayUtils.Print("MonsterAISystem.UnregisterZombieEntry: 注销丧尸入口Actor！")
    return true
end

---@public
---@return BP_EntryForZombie_Base_C[]
function MonsterAISystem:GetRegistredZombieEntries()
    return self.registeredZombieEntries
end

---@public
---@return UBlackboardComponent
function MonsterAISystem:GetBlackboard(aiController)
    local blackboard = UGCGenericCharacterSystem.GetBlackboard(aiController)
    if not blackboard then
        GameplayUtils.Print("MonsterAISystem.GetBlackboard: 获取黑板组件失败！")
    end
    return blackboard
end

---@public
---@return BP_EntryForZombie_Base_C
function MonsterAISystem:GetZombieEntryActor(aiController)
    local blackboard = UGCGenericCharacterSystem.GetBlackboard(aiController)
    if not blackboard then
        GameplayUtils.Print("MonsterAISystem.GetZombieEntryActor: 获取黑板组件失败！")
        return nil
    end
    local entryActor = blackboard:GetValueAsObject("EntryActor")
    return entryActor
end

---@public
---@param zombiePawn BP_Zombie_Base_C
---@return number,FVector
function MonsterAISystem:ServerRequestZombieEntryPositionSlot(zombiePawn)
    if not self:IsZombieAlive(zombiePawn) then
        GameplayUtils.Print("MonsterAISystem.ServerRequestZombieEntryPositionSlot: 丧尸已死亡无法请求站位！")
        return 0
    end
    local entryActor = zombiePawn:ServerGetTargetEntry()
    if not entryActor then
        GameplayUtils.Print("MonsterAISystem.ServerRequestZombieEntryPositionSlot: 无法获取入口Actor！")
        return 0
    end
    local posSlotIndex,worldPos = entryActor:RequestPositionSlot(zombiePawn)
    zombiePawn:SetEntryPositionSlotIndex(posSlotIndex)
    return posSlotIndex,worldPos
end

---@public
---@param zombiePawn  BP_Zombie_Base_C
---@return boolean
function MonsterAISystem:ServerGiveupZombieEntryPositionSlot(zombiePawn)
    local entryActor = zombiePawn:ServerGetTargetEntry()
    if not entryActor then
        GameplayUtils.Print("MonsterAISystem.ServerGiveupZombieEntryPositionSlot: 无法获取入口Actor！")
        return false
    end
    local slotIndex = zombiePawn:GetEntryPositionSlotIndex()
    local success = entryActor:ReturnPositionSlot(zombiePawn,slotIndex)
    if success then
        zombiePawn:SetEntryPositionSlotIndex(0)
    end
    return success
end

return MonsterAISystem