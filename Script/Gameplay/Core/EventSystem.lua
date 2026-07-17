---@class Gameplay.EventListener
---@field ID number
---@field Owner table|userdata|nil
---@field Callback function
---@field Once boolean
---@field Removed boolean Unlisten()不知道自己是不是发生在正在广播的中途,所以通过标志位标记幼删除，再到合适时候统一删除。

---@class Gameplay.EventSystem
local EventSystem = LuaClass("Gameplay.EventSystem")

function EventSystem:Ctor()
    ---@type table<string, Gameplay.EventListener[]>
    self.Listeners = {}
    self.NextListenerID = 1
end

function EventSystem:BeginPlayOnServer()
    --Begin内不要调用Clear()
end

function EventSystem:BeginPlayOnClient()
    --Begin内不要调用Clear()
end

function EventSystem:EndPlayOnServer()
    self:Clear()
end

function EventSystem:EndPlayOnClient()
    self:Clear()
end

---@private
---@param eventName string
---@return Gameplay.EventListener[]
function EventSystem:GetOrCreateEventListeners(eventName)
    local listeners = self.Listeners[eventName]
    if listeners == nil then
        listeners = {}
        self.Listeners[eventName] = listeners
    end
    return listeners
end

---@private
---@param callback function
---@param owner table|userdata|nil
---@param ... any
---@return boolean
---@return any
function EventSystem:SafeInvoke(callback, owner, ...)
    if owner ~= nil then
        return pcall(callback, owner, ...)
    end
    return pcall(callback, ...)
end

---@public
---@param eventName string
---@param owner table|userdata|nil
---@param callback function
---@return number|nil
function EventSystem:Listen(eventName, owner, callback)
    if type(eventName) ~= "string" or eventName == "" then
        GameplayUtils.Print("[EventSystem] Listen failed: invalid event name")
        return nil
    end
    if type(callback) ~= "function" then
        GameplayUtils.Print("[EventSystem] Listen failed: callback is not function, event = ", tostring(eventName))
        return nil
    end

    local listenerID = self.NextListenerID
    self.NextListenerID = self.NextListenerID + 1

    local listeners = self:GetOrCreateEventListeners(eventName)
    listeners[#listeners + 1] = {
        ID = listenerID,
        Owner = owner,
        Callback = callback,
        Once = false,
        Removed = false,
    }
    return listenerID
end

---@public
---@param eventName string
---@param owner table|userdata|nil
---@param callback function
---@return number|nil
function EventSystem:ListenOnce(eventName, owner, callback)
    local listenerID = self:Listen(eventName, owner, callback)
    if listenerID == nil then
        return nil
    end

    local listeners = self.Listeners[eventName]
    if listeners then
        for _, listener in ipairs(listeners) do
            if listener.ID == listenerID then
                listener.Once = true
                break
            end
        end
    end
    return listenerID
end

---@public
---@param eventName string
---@param ownerOrListenerID table|userdata|number|nil
---@param callback function|nil
---@return number
function EventSystem:Unlisten(eventName, ownerOrListenerID, callback)
    local listeners = self.Listeners[eventName]
    if listeners == nil then
        return 0
    end

    local removedCount = 0
    for _, listener in ipairs(listeners) do
        if not listener.Removed then
            local shouldRemove = false
            if type(ownerOrListenerID) == "number" then
                shouldRemove = listener.ID == ownerOrListenerID
            elseif callback ~= nil then
                shouldRemove = listener.Owner == ownerOrListenerID and listener.Callback == callback
            else
                shouldRemove = listener.Owner == ownerOrListenerID
            end

            if shouldRemove then
                listener.Removed = true
                removedCount = removedCount + 1
            end
        end
    end

    return removedCount
end

---@public
---@param owner table|userdata|nil
---@return number
function EventSystem:UnlistenAll(owner)
    if owner == nil then
        return 0
    end

    local removedCount = 0
    for eventName, _ in pairs(self.Listeners) do
        removedCount = removedCount + self:Unlisten(eventName, owner)
    end
    return removedCount
end

---@public
---@param eventName string
---@return boolean
function EventSystem:HasListeners(eventName)
    local listeners = self.Listeners[eventName]
    if listeners == nil then
        return false
    end

    for _, listener in ipairs(listeners) do
        if not listener.Removed then
            return true
        end
    end
    return false
end

---@public 仅GameplayLua层广播
---@param eventName string
---@param ... any
---@return number
function EventSystem:Broadcast(eventName, ...)
    local listeners = self.Listeners[eventName]
    if listeners == nil or #listeners == 0 then
        return 0
    end

    local invokeCount = 0
    local activeListeners = {}
    for _, listener in ipairs(listeners) do
        if not listener.Removed then
            activeListeners[#activeListeners + 1] = listener
        end
    end

    for _, listener in ipairs(activeListeners) do
        if not listener.Removed then
            local ok, err = self:SafeInvoke(listener.Callback, listener.Owner, ...)
            if not ok then
                GameplayUtils.Print(
                    "[EventSystem] Broadcast listener failed, event = ",
                    tostring(eventName),
                    ", error = ",
                    tostring(err)
                )
            else
                invokeCount = invokeCount + 1
            end

            if listener.Once then
                listener.Removed = true
            end
        end
    end

    local compactedListeners = {}
    for _, listener in ipairs(listeners) do
        if not listener.Removed then
            compactedListeners[#compactedListeners + 1] = listener
        end
    end
    self.Listeners[eventName] = compactedListeners

    return invokeCount
end

---@public 全项目共同广播（包括Gameplay纯lua层以及UGC领域）
function EventSystem:BroadcastGlobal(eventName,...)
    --
    self:Broadcast(eventName,...)
    --
    UGCGenericMessageSystem.BroadcastUserDefinedGlobalMessage(eventName,...)
end

---@public
---@param eventName string|nil
function EventSystem:Clear(eventName)
    if eventName ~= nil then
        self.Listeners[eventName] = nil
        return
    end

    self.Listeners = {}
    self.NextListenerID = 1
end

return EventSystem
