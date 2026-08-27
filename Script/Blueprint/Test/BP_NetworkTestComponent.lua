---@class BP_NetworkTestComponent_C:ActorComponent
--Edit Below--
local BP_NetworkTestComponent = {
    InstanceID = 0,
}

function BP_NetworkTestComponent:ReceiveBeginPlay()
    BP_NetworkTestComponent.SuperClass.ReceiveBeginPlay(self)
    local owner = self:GetOwnerActor()
    GameplayUtils.Print("BP_NetworkTestComponent ",UGCObjectUtility.GetObjectName(owner),"-",UGCObjectUtility.GetObjectName(self)," ReceiveBeginPlay！！！")
    local isServer = owner:HasAuthority()
    if isServer then
        self.InstanceID = math.random()
        UnrealNetwork.RepLazyProperty(self,"InstanceID")
    end
end

function BP_NetworkTestComponent:GetReplicatedProperties()
    return {"InstanceID","Lazy"}
end

---@protected
function BP_NetworkTestComponent:OnRep_InstanceID()
    --客户端像交互系统注册自身
    local owner = self:GetOwnerActor()
    if owner and owner.TextRender then
        owner.TextRender:SetText("InstanceID: "..tostring(self.InstanceID))
    end
    GameplayUtils.Print("BP_NetworkTestComponent.OnRep_InstanceID: 可交互实体 ",UGCObjectUtility.GetObjectName(owner)," 获得实例ID ",self.InstanceID)
end

function BP_NetworkTestComponent:GetOwnerActor()
    if self.m_owner == nil then
        self.m_owner = UGCActorComponentUtility.GetOwner(self)
    end
    return self.m_owner
end

return BP_NetworkTestComponent