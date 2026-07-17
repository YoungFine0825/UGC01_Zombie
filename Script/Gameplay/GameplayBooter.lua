local UGCRequire = UGCGameSystem.UGCRequire

UGCRequire("Script.Gameplay.Config.GameplayEvents")
UGCRequire("Script.Gameplay.Core.Class")
UGCRequire("Script.Gameplay.Utils.Utils")
UGCRequire("Script.Gameplay.Core.GameplayEnum")

UGCRequire("Script.Gameplay.GameplaySystem")


---@class GameplayBooter
local GameplayBooter = {
    m_tickList = {},---@type Gameplay.IGameplaySystem[]
    m_serverTickList = {},---@type Gameplay.IGameplaySystem[]
    m_clientTickList = {},---@type Gameplay.IGameplaySystem[]
}

local IsLuaClass = function(obj)
    return type(obj) == "table" and obj.__cname ~= nil
end

local IsValidFunc = function(func)
    return func ~= nil and type(func) == "function"
end

local CallSystemsLifecycleFunc = function(funcName)
    for _,v in pairs(GameplaySystem) do
        if IsLuaClass(v) then
            local func = v[funcName]
            if IsValidFunc(func) then
                pcall(func,v)
            end
        end
    end
end

---@public
function GameplayBooter.Construct()
    GameplayUtils.Print("GameplayBooter.Construct")
    local registerFunc = UGCGenericMessageSystem.RegisterUserDefinedMessage
    for _,clientEvt in pairs(GameplayEvents.Global or {}) do
        registerFunc(clientEvt)
    end
    if UGCGameSystem.IsServer() then
        for _,clientEvt in pairs(GameplayEvents.Server or {}) do
            registerFunc(clientEvt)
        end
    else
        for _,clientEvt in pairs(GameplayEvents.Client or {}) do
            registerFunc(clientEvt)
        end
    end
end

---@public
function GameplayBooter.BeginPlayOnServer()
    GameplayUtils.Print("[服务端] 启动Gameplay相关子系统'")
    --
    for _,v in pairs(GameplaySystem) do
        if IsLuaClass(v) then
            if IsValidFunc(v["OnTick"]) then
                table.insert(GameplayBooter.m_tickList,v)
            elseif IsValidFunc(v["OnServerTick"]) then
                table.insert(GameplayBooter.m_serverTickList,v)
            end
        end
    end
    --
    CallSystemsLifecycleFunc("BeginPlayOnServer")
end

---@public
function GameplayBooter.EndPlayOnServer()
    GameplayUtils.Print("[服务端] 结束Gameplay相关子系统'")
    --
    GameplayBooter.m_tickList = {}
    GameplayBooter.m_serverTickList = {}
    CallSystemsLifecycleFunc("EndPlayOnServer")
end

---@public
function GameplayBooter.BeginPlayOnClient()
    GameplayUtils.Print("[客户端] 启动Gameplay相关子系统'")
    --
    for _,v in pairs(GameplaySystem) do
        if IsLuaClass(v) then
            if IsValidFunc(v["OnTick"]) then
                table.insert(GameplayBooter.m_tickList,v)
            elseif IsValidFunc(v["OnClientTick"]) then
                table.insert(GameplayBooter.m_clientTickList,v)
            end
        end
    end
    --
    CallSystemsLifecycleFunc("BeginPlayOnClient")
end

---@public
function GameplayBooter.EndPlayOnClient()
    GameplayUtils.Print("[客户端] 结束Gameplay相关子系统'")
    --
    GameplayBooter.m_tickList = {}
    GameplayBooter.m_clientTickList = {}
    CallSystemsLifecycleFunc("EndPlayOnClient")
end

---@public
function GameplayBooter.OnTick(isServer,DeltaTime)
    for k,v in pairs(GameplayBooter.m_tickList) do
        v:OnTick(DeltaTime)
    end
    if isServer then
        for k,v in pairs(GameplayBooter.m_serverTickList) do
            v:OnServerTick(DeltaTime)
        end
    else
        for k,v in pairs(GameplayBooter.m_clientTickList) do
            v:OnClientTick(DeltaTime)
        end
    end
end

return GameplayBooter