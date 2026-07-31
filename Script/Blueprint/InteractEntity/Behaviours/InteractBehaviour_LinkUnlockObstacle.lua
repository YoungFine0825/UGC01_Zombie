---@class InteractBehaviour_LinkUnlockObstacle_C:BP_InteractEntityBehaviourComponent_C
---@field LinkedObstacles ULuaArrayHelper<BP_InteractableBase_C>
---@field SkipBehaviours ULuaArrayHelper<FGameplayTag>
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_LinkUnlockObstacle_C
local InteractBehaviour_LinkUnlockObstacle = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_LinkUnlockObstacle:ReceiveBeginPlay()
    InteractBehaviour_LinkUnlockObstacle.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_LinkUnlockObstacle:ReceiveTick(DeltaTime)
    InteractBehaviour_LinkUnlockObstacle.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_LinkUnlockObstacle:ReceiveEndPlay()
    InteractBehaviour_LinkUnlockObstacle.SuperClass.ReceiveEndPlay(self) 
end


---@public 服务端&客户端执行
---@param playerKey number 请求交互的玩家的playerKey
function InteractBehaviour_LinkUnlockObstacle:PreExecute(playerKey)
    self.BaseClass.PreExecute(self,playerKey)
    if self.m_isServer then
        --在预执行时，为联动解锁的实体创建交互请求，并跳过一些行为（比如扣除玩家得分的行为）让实体无条件执行行为
        for i = 1,self.LinkedObstacles:Num() do
            ---@type BP_Interact_LevelObstacle_C
            local interactEntity = self.LinkedObstacles:Get(i)
            ---@type BP_InteractEntityComponent_C
            local interactEntityComp = interactEntity:GetInteractComponent()
            ---@type Gameplay.InteractEntitySystem.InteractionRequest
            local request = {
                PlayerKey        = playerKey,
                EntityInstanceID = interactEntityComp:GetInstanceID(),
                skipBehaviours = {},
                IgnoreConditionChecking = true,--跳过条件检查
            }
            for j = 1,self.SkipBehaviours:Num() do
                ---@type FGameplayTag
                local gameplayTag = self.SkipBehaviours:Get(j)
                table.insert(request.skipBehaviours,gameplayTag)
            end
            --让请求者的PlayerController去处理
            ---@type UGCPlayerController_C
            local pc = UGCGameSystem.GetPlayerControllerByPlayerKey(playerKey)
            pc.PlayerInteractEntityComponent:ServerHandleInteractRequest(request)
        end
    end
end

return InteractBehaviour_LinkUnlockObstacle