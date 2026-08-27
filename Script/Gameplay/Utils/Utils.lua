---@class Gameplay.Utils
local Utils = {}

function Utils.Print(...)
    --ugcprint_concat("[Gameplay] ",...)
    print(table.concat({"[Gameplay]: ",...}))
end

function Utils.Exception(...)
    -- ugc_exception(...)
    --ugcprint_concat("[Gameplay Exception]: ",...)
    print(table.concat({"[Gameplay Exception]: ",...}))
end

---@public
---@return string
function Utils.GetUEObjClassName(obj)
    local ret = obj.classname
    if ret ~= nil then
        return tostring(ret)
    end
    local mt = getmetatable(obj)
    if mt and mt.classname then
        return tostring(mt.classname)
    end
    return "Unknown"
end

---@param inActor Actor
---@param inCompObjectName string 这里的名字指Actor蓝图面板上组件的“变量命名”字段
---@param inClass UClass
---@return UActorComponent
function Utils.GetComponentByName(inActor,inCompObjectName,inClass)
    local comps = nil
    if inClass then
        comps = UGCActorComponentUtility.GetComponentsByClass(inActor, inClass)
    else
        comps = UGCActorComponentUtility.GetComponentsByOwner(inActor)
    end
    if comps and #comps > 0 then
        for k,v in pairs(comps) do
            if UGCObjectUtility.GetObjectName(v) == inCompObjectName then
                return v
            end
        end
    end
    return nil
end

---@type Gameplay.Utils
GameplayUtils = Utils