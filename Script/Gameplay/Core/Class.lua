local callSuperCtor
callSuperCtor = function(cls, instance, ...)
    if type(rawget(cls, "__supers")) == "table" and #cls.__supers > 0 then
        for i = 1, #cls.__supers do
            local superClass = cls.__supers[i]
            callSuperCtor(superClass, instance, ...)
        end
    end
    if rawget(cls, "Ctor") then
        cls.Ctor(instance, ...)
    end
end

function LuaClass(className,...)
    local cls = { 
        __cname = className,
        __supers = {},
    }
    local supers = {...}
    local superCnt = 0
    for i = 1,#supers do
        local superType = type(supers[i])
        if superType == "table" then
           table.insert(cls.__supers,supers[i]) 
           superCnt = superCnt + 1
           if not cls.Super then
                cls.Super = supers[i]
           end
        end
    end
    cls.__index = cls
    if superCnt > 0 then
        if superCnt == 1 then
            setmetatable(cls,{__index = cls.Super})
        else
            setmetatable(cls,{__index = function(t,key) 
                local supers = cls.__supers
                for i = 1,#supers do
                    if supers[i][key] then
                        return supers[i][key]
                    end
                end
            end})
        end
    end

    cls.New = function(...)
        local instance = {Class = cls}
        setmetatable(instance,{__index = cls})
        --递归调用父类构造函数
        if type(rawget(cls, "__supers")) == 'table' then
            for i = 1, #cls.__supers do
                callSuperCtor(cls.__supers[i], instance, ...)
            end
        end
        --执行自身构造函数
        if rawget(cls, "Ctor") then
            cls.Ctor(instance, ...)
        end
        return instance
    end
    
    return cls
end