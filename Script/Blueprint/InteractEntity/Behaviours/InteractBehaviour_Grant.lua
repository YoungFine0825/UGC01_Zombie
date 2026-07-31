---@class InteractBehaviour_Grant_C:BP_InteractEntityBehaviourComponent_C
---@field GrantType TEnumAsByte<EInteractBehaviourGrantType>
---@field WeaponConfigID int32
---@field BuffClass FSoftClassPath
---@field Score float
---@field bGrantToAllPlayers bool
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_Grant_C
local InteractBehaviour_Grant = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_Grant:ReceiveBeginPlay()
    InteractBehaviour_Grant.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_Grant:ReceiveTick(DeltaTime)
    InteractBehaviour_Grant.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_Grant:ReceiveEndPlay()
    InteractBehaviour_Grant.SuperClass.ReceiveEndPlay(self) 
end

---@public
---@param playerKey number
function InteractBehaviour_Grant:Execute(playerKey)
    self.BaseClass.Execute(self, playerKey)
    if self.m_isClient then
        return
    end

    -- 确定授予目标玩家列表
    local targetPlayerKeys = {}
    if self.bGrantToAllPlayers then
        local allKeys = UGCGameSystem.GetAllPlayerKey()
        for _, pk in pairs(allKeys) do
            table.insert(targetPlayerKeys, pk)
        end
    else
        table.insert(targetPlayerKeys, playerKey)
    end

    if self.GrantType == EInteractBehaviourGrantType.Weapon then
        self:_ExecuteGrantWeapon(targetPlayerKeys)
    elseif self.GrantType == EInteractBehaviourGrantType.Buff then
        self:_ExecuteGrantBuff(targetPlayerKeys)
    elseif self.GrantType == EInteractBehaviourGrantType.Score then
        self:_ExecuteGrantScore(targetPlayerKeys)
    end

    self:OnFinish()
end

---@private 授予武器
---@param targetPlayerKeys number[]
function InteractBehaviour_Grant:_ExecuteGrantWeapon(targetPlayerKeys)
    if self.WeaponConfigID <= 0 then
        GameplayUtils.Exception("InteractBehaviour_Grant._ExecuteGrantWeapon: WeaponConfigID 无效")
        return
    end
    for _, pk in ipairs(targetPlayerKeys) do
        GameplaySystem.WeaponSystem:ServerDeliverAndEquipWeaponToPlayer(pk, self.WeaponConfigID)
    end
end

---@private 授予 Buff
---@param targetPlayerKeys number[]
function InteractBehaviour_Grant:_ExecuteGrantBuff(targetPlayerKeys)
    if not self.BuffClass then
        GameplayUtils.Exception("InteractBehaviour_Grant._ExecuteGrantBuff: BuffClass 未配置")
        return
    end

    local buffClassPath = UGCObjectUtility.GetPathBySoftObjectPath(self.BuffClass)
    if not buffClassPath or buffClassPath == "" then
        GameplayUtils.Exception("InteractBehaviour_Grant._ExecuteGrantBuff: BuffClass 路径为空")
        return
    end

    local buffClass = UGCObjectUtility.LoadClass(buffClassPath)
    if not buffClass then
        GameplayUtils.Exception(string.format(
            "InteractBehaviour_Grant._ExecuteGrantBuff: 无法加载 BuffClass [%s]", buffClassPath))
        return
    end

    for _, pk in ipairs(targetPlayerKeys) do
        local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(pk)
        if not playerPawn or not UE.IsValid(playerPawn) then
            GameplayUtils.Exception(string.format(
                "InteractBehaviour_Grant._ExecuteGrantBuff: 玩家 %d 的 Pawn 无效", pk))
        else
            local playerController = UGCGameSystem.GetPlayerControllerByPlayerKey(pk)
            UGCPersistEffectSystem.AddBuffByClass(playerPawn, buffClass, playerController)
        end
    end
end

---@private 授予积分
---@param targetPlayerKeys number[]
function InteractBehaviour_Grant:_ExecuteGrantScore(targetPlayerKeys)
    if self.Score <= 0 then
        GameplayUtils.Exception("InteractBehaviour_Grant._ExecuteGrantScore: Score 无效")
        return
    end
    for _, pk in ipairs(targetPlayerKeys) do
        GameplaySystem.PlayerSystem:AddPlayerScore(pk, self.Score)
    end
end

return InteractBehaviour_Grant