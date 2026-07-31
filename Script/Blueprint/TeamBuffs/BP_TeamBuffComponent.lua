---@class BP_TeamBuffComponent_C:ActorComponent
--Edit Below--
---@type BP_TeamBuffComponent_C
local BP_TeamBuffComponent = {}

-- 生命周期结束委托列表
-- 格式: { {callback=fn, context=obj}, ... }
---@private
---@type table
BP_TeamBuffComponent.m_onLifeSpanEndedCallbacks = nil

--[[--]]
function BP_TeamBuffComponent:ReceiveBeginPlay()
    BP_TeamBuffComponent.SuperClass.ReceiveBeginPlay(self)
    ---@type BP_TeamBuffDropManager_C
    self.m_dropManager = nil
    self.m_onLifeSpanEndedCallbacks = {}
    ---@type BP_Interact_TeamBuff_C
    self.m_ownerActor = UGCActorComponentUtility.GetOwner(self)
    self.m_lifeSpanTime = 0
end


--[[
function BP_TeamBuffComponent:ReceiveTick(DeltaTime)
    BP_TeamBuffComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_TeamBuffComponent:ReceiveEndPlay()
    BP_TeamBuffComponent.SuperClass.ReceiveEndPlay(self) 
end
--]]

---@public 注册生命周期结束回调
---@param callback function 回调函数 callback(context, buffComponent)
---@param context AActor 回调上下文(通常是self)
function BP_TeamBuffComponent:RegisterOnLifeSpanEnded(callback, context)
    if not self.m_onLifeSpanEndedCallbacks then
        self.m_onLifeSpanEndedCallbacks = {}
    end
    table.insert(self.m_onLifeSpanEndedCallbacks, {
        callback = callback,
        context = context,
    })
end

---@public 取消注册生命周期结束回调
---@param context AActor 要移除的回调上下文
function BP_TeamBuffComponent:UnregisterOnLifeSpanEnded(context)
    if not self.m_onLifeSpanEndedCallbacks then
        return
    end
    for i = #self.m_onLifeSpanEndedCallbacks, 1, -1 do
        if self.m_onLifeSpanEndedCallbacks[i].context == context then
            table.remove(self.m_onLifeSpanEndedCallbacks, i)
        end
    end
end

---@private 触发生命周期结束委托
function BP_TeamBuffComponent:FireOnLifeSpanEnded()
    if not self.m_onLifeSpanEndedCallbacks then
        return
    end
    local ownerActor = self:GetOwnerActor()
    for _, entry in ipairs(self.m_onLifeSpanEndedCallbacks) do
        if entry.callback and entry.context and UE.IsValid(entry.context) then
            entry.callback(entry.context, ownerActor)
        end
    end
end

---@public
function BP_TeamBuffComponent:Activate(dropManager,lifeSpanTime)
    self.m_dropManager = dropManager
    self.m_lifeSpanTime = lifeSpanTime
    if self.m_lifeSpanTimer then
        UGCTimerUtility.RemoveLuaTimer(self.m_lifeSpanTimer)
        self.m_lifeSpanTimer = nil
    end
    self.m_lifeSpanTimer = UGCTimerUtility.CreateLuaTimer(lifeSpanTime,function()
        if UE.IsValid(self) then
            self:OnLifeSpanEnd()
        end
    end,false)
end

---@public
function BP_TeamBuffComponent:GetDropManager()
    return self.m_dropManager
end

---@private
function BP_TeamBuffComponent:OnLifeSpanEnd()
    GameplayUtils.Print("BP_TeamBuffComponent.OnLifeSpanEnd")
    local ownerActor = self:GetOwnerActor()
    ownerActor:SetLifeSpan(0.1)--稍后销毁

    -- 先触发生命周期结束委托(通知DropManager移除记录)
    self:FireOnLifeSpanEnded()
end

---@public
---@return BP_Interact_TeamBuff_C
function BP_TeamBuffComponent:GetOwnerActor()
    if not self.m_ownerActor then
        self.m_ownerActor = UGCActorComponentUtility.GetOwner(self)
    end
    return self.m_ownerActor
end

return BP_TeamBuffComponent
