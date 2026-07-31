---@class InteractBehaviour_TeamBuffPickup_C:BP_InteractEntityBehaviourComponent_C
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_TeamBuffPickup_C
local InteractBehaviour_TeamBuffPickup = BPExtent({}, "Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")

--[[--]]
function InteractBehaviour_TeamBuffPickup:ReceiveBeginPlay()
    InteractBehaviour_TeamBuffPickup.SuperClass.ReceiveBeginPlay(self)
end

--[[
function InteractBehaviour_TeamBuffPickup:ReceiveTick(DeltaTime)
    InteractBehaviour_TeamBuffPickup.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_TeamBuffPickup:ReceiveEndPlay()
    InteractBehaviour_TeamBuffPickup.SuperClass.ReceiveEndPlay(self)
end

---@public
---@param playerKey number
function InteractBehaviour_TeamBuffPickup:Execute(playerKey)
    -- 仅服务端处理
    if self.m_isClient then
        self:OnFinish()
        return
    end

    self.BaseClass.Execute(self, playerKey)

    -- 获取掉落物 Owner
    local owner = UGCActorComponentUtility.GetOwner(self)
    if not owner or not UE.IsValid(owner) then
        GameplayUtils.Exception("InteractBehaviour_TeamBuffPickup.Execute: owner 无效")
        self:OnFinish()
        return
    end

    -- 获取来源 Manager
    local manager = owner.DropManager
    if not manager then
        GameplayUtils.Exception("InteractBehaviour_TeamBuffPickup.Execute: DropManager 未挂载")
        self:OnFinish()
        return
    end

    -- 广播拾取事件，携带 manager + pickupActor + playerKey
    GameplaySystem.EventSystem:BroadcastGlobal(
        GameplayEvents.Server.OnTeamBuffPicked,
        manager,
        owner,
        playerKey
    )

    self:OnFinish()
end

return InteractBehaviour_TeamBuffPickup
