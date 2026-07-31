---@class InteractBehaviour_PurchaseSoda_C:BP_InteractEntityBehaviourComponent_C
---@field SodaConfigID int32
---@field Price float
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_PurchaseSoda_C
local InteractBehaviour_PurchaseSoda = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_PurchaseSoda:ReceiveBeginPlay()
    InteractBehaviour_PurchaseSoda.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_PurchaseSoda:ReceiveTick(DeltaTime)
    InteractBehaviour_PurchaseSoda.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_PurchaseSoda:ReceiveEndPlay()
    InteractBehaviour_PurchaseSoda.SuperClass.ReceiveEndPlay(self) 
end

---@public 客户端提前判断是否可以交互
---@param playerKey number 请求交互的玩家的playerKey
---@return boolean
---@return number EInteractEntityErrCode
function InteractBehaviour_PurchaseSoda:CanInteract(playerKey)
    local canInteract,errcode = self.BaseClass.CanInteract(self,playerKey)
    if not canInteract then
        return canInteract,errcode
    end
    local configData = GameplaySystem.SodaConfigMgr:GetSodaConfigData(self.SodaConfigID)
    if not configData then
        return false,EInteractEntityErrCode.FailNoConfig
    end
    ---
    local pc = GameplaySystem.GetPlayerControllerByPlayerKey(playerKey)
    local isGained = pc.SodaSystemComponent:IsUsed(self.SodaConfigID)
    if isGained then
        return false,EInteractEntityErrCode.FailAlreadyUsed
    end
    --
    local tips = string.format("购买%s[花费%d点数]",configData.Name,self.Price)
    self.m_interactEntityComp:ClientOverrideHUDTipsText(tips)
    return true,EInteractEntityErrCode.None
end

---@public 服务端检查交互行为是否符合条件
---@param playerKey number 请求交互的玩家的playerKey
---@return boolean
---@return number EInteractEntityErrCode
function InteractBehaviour_PurchaseSoda:CanExecute(playerKey)
    local parentRet,parentErr = self.BaseClass.CanExecute(self,playerKey)
    if not parentRet then
        return parentRet,parentErr
    end
    ---
    local pc = GameplaySystem.GetPlayerControllerByPlayerKey(playerKey)
    local isGained = pc.SodaSystemComponent:IsUsed(self.SodaConfigID)
    if isGained then
        return false,EInteractEntityErrCode.FailAlreadyUsed
    end
    --
    local curSocre = GameplaySystem.PlayerSystem:GetPlayerCurrentScore(playerKey)
    if curSocre < self.Price then
        return false,EInteractEntityErrCode.FailUnavailable--得分不够
    end
    return true,EInteractEntityErrCode.None
end

---@public 服务端&客户端执行
---@param playerKey number 请求交互的玩家的playerKey
function InteractBehaviour_PurchaseSoda:Execute(playerKey)
    if self.m_isClient then
        return
    end
    local consumeSocreSuccessful = GameplaySystem.PlayerSystem:ConsumePlayerScore(playerKey,self.Price)
    if consumeSocreSuccessful then
        local pc = GameplaySystem.GetPlayerControllerByPlayerKey(playerKey)
        pc.SodaSystemComponent:ServerGainSoda(self.SodaConfigID)
    end
end

return InteractBehaviour_PurchaseSoda