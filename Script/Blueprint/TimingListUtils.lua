local PromiseFuture = require("common.PromiseFuture") 

TimingListUtils = TimingListUtils or {
    TimingList = {},
    TempTimingList = {},
}

-- 深拷贝，保证List能重复使用
function TimingListUtils.DeepCopy(original)
    if type(original) ~= "table" then
        return original  -- 基本数据类型直接返回
    end

    local copy = {}
    for k, v in pairs(original) do
        copy[TimingListUtils.DeepCopy(k)] = TimingListUtils.DeepCopy(v)  -- 递归复制键和值
    end
    return copy
end

-- 获取一个ListIndex用于添加一个新TimingList
--- @return ListIndex 返回一个ListIndex
function TimingListUtils.NewList()
    TimingListUtils.TimingList[#TimingListUtils.TimingList + 1] = {}
    return #TimingListUtils.TimingList
end

-- 往List里添加变量和函数。激活后时序逻辑为：轮询变量是否为空，当变量不为空的时候，执行对应的函数，所以每次Add一组变量和函数，就相当于添加一个时序逻辑。
-- 注意：这里传InParam的时候，需要传一个Table，否则只是值复制，而不是引用
-- 至于InFunctionTable和InFunction，可以参考CallBack和CallBack_Self的用法，也就是tab:fun()和fun()的区别，如果InFunctionTable是空，则是直接执行InFunction，否则是执行InFunctionTable:InFunction
-- 最后传入的是可变参数，会被带到InFunction中
--- @param ListIndex integer 时序逻辑列表的索引
--- @param ParamIndex integer 参数插入时序逻辑列表的位置，如果是0，则是插入到列表的尾部
--- @param InConditionTable table 可执行的条件的Table
--- @param InConditionFunctionOrParam any 可执行的条件或变量
--- @param InFunctionTable table 当条件为true时执行函数的Table
--- @param InFunction function 当条件为true时执行的函数
function TimingListUtils.Add(ListIndex, ParamIndex, InConditionTable, InConditionFunction, InFunctionTable, InFunction, ...)

    local timingLogic = {
        ConditionCtx = InConditionTable,    -- 可执行条件的上下文Table
        Condition = InConditionFunction,    -- 可执行的条件
        ExecuteCtx = InFunctionTable,       -- 执行的上下文Table
        ExecuteFn = InFunction,             -- 执行的函数
        args = {...}                        -- 执行参数
    }

    -- 如果 ParamIndex 合法（大于 0），则在指定位置插入
    if ParamIndex > 0 then
        -- 先确保 ParamIndex 在现有表的有效范围内（不超出最大索引）
        if ParamIndex <= #TimingListUtils.TimingList[ListIndex] + 1 then
            table.insert(TimingListUtils.TimingList[ListIndex], ParamIndex, timingLogic)
        else
            -- 如果 ParamIndex 超出范围，直接加到最后
            table.insert(TimingListUtils.TimingList[ListIndex], timingLogic)
        end
    else
        -- 如果 ParamIndex <= 0，则直接加到最后
        table.insert(TimingListUtils.TimingList[ListIndex], timingLogic)
    end
end

-- 激活TimingList
--- @param Interval number @自动恢复的间隔，单位为秒
--- @param Timeout number @自动恢复的超时时间，单位为秒
function TimingListUtils.Activate(Index, Interval, Timeout)
    if Index < 0 or not TimingListUtils.TimingList[Index] then
        return
    end
    PromiseFuture.New():Set(
        function (PromiseFuture)
            local TempIndex = #TimingListUtils.TempTimingList + 1
            TimingListUtils.TempTimingList[TempIndex] = TimingListUtils.DeepCopy(TimingListUtils.TimingList[Index])
            while #TimingListUtils.TempTimingList[TempIndex] > 0 do
                local v = TimingListUtils.TempTimingList[TempIndex][1]
                ugcprint("[TimingListUtils] TempTimingList: ")

                local conditionMet = false
                -- 新写法：使用条件函数
                if v.Condition and type(v.Condition) == "function" then
                    conditionMet = v.ConditionCtx and v.Condition(v.ConditionCtx) or v.Condition()
                -- 旧写法：检查参数是否存在
                elseif v.ConditionCtx and v.Condition then -- ConditionCtx是table，Condition是key
                    conditionMet = v.ConditionCtx[v.Condition]
                else
                    -- 默认情况下，条件为真，例如传进来的Condition为nil，或是传进来的ConditionCtx是nil且Condition不是function
                    conditionMet = true
                end

                if conditionMet then
                    -- 执行函数处理
                    if v.ExecuteFn and type(v.ExecuteFn) == "function" then
                        if v.ExecuteCtx then
                            v.ExecuteFn(v.ExecuteCtx, table.unpack(v.args))
                        else
                            v.ExecuteFn(table.unpack(v.args))
                        end
                    end
                    table.remove(TimingListUtils.TempTimingList[TempIndex], 1) -- 删除后索引不递增
                end
                PromiseFuture:Yield()
            end
        end
    ):AutoResume(UGCGameSystem.GameMode, Interval, Timeout)
end

--- @param tablePaths table<string> @要加载的表路径列表
--- @param context any @加载表时传入的上下文
--- @param onCompleteCallback function @加载完成后执行的回调函数
function TimingListUtils.AsyncLoadTables(tablePaths, context, onCompleteCallback)
    local listIndex = TimingListUtils.NewList()
    local loadedTables = {}
    local loadFlags = {}  -- 每个表是否加载
    print("[TimingListUtils.AsyncLoadTables]: " .. #tablePaths)
    -- 先添加第一个表的加载逻辑（依赖GameState）
    if #tablePaths > 0 then
        local firstPath = tablePaths[1]
        local firstName = string.match(firstPath, "([^/]+)%.[^%.]+$")
        TimingListUtils.Add(
            listIndex, 0,
            UGCGameSystem, "GameState",
            context, 
            function()
                UGCGameSystem.AsyncGetTableData(
                    firstPath,
                    function(data)
                        loadedTables[firstName] = data
                        loadFlags[1] = true  -- 标记第一个表已加载
                        print("[TimingListUtils.AsyncLoadTables]:Loaded: " .. firstPath)
                    end
                )
            end
        )
        -- 添加后续表的加载逻辑
        for i = 2, #tablePaths do
            local currentPath = tablePaths[i]
            local prevIndex = i - 1
            local currentName = string.match(currentPath, "([^/]+)%.[^%.]+$")
            TimingListUtils.Add(
                listIndex, 0,
                nil, function() return loadFlags[prevIndex] end,  -- 检查前一个表是否已加载
                context, 
                function()
                    UGCGameSystem.AsyncGetTableData(
                        currentPath,
                        function(data)
                            loadedTables[currentName] = data
                            loadFlags[i] = true  -- 标记当前表已加载
                            print("[TimingListUtils.AsyncLoadTables]:Loaded: " .. currentPath)
                        end
                    )
                end
            )
        end
        -- 添加完成回调
        TimingListUtils.Add(
            listIndex, 0,
            nil, function() return loadFlags[#tablePaths] end,  -- 检查最后一个表是否已加载
            context, function()
                if onCompleteCallback then
                    onCompleteCallback(context, loadedTables)
                end
            end
        )
    end
    
    TimingListUtils.Activate(listIndex, 0.2, 20)
    
    return loadedTables
end

-- 示例：TimingListUtils
ExampleTable = {}
-- 示例：TimingListUtils.Add的用法
function ExampleTable:exampleAdd()
    
    local NewIndex = TimingListUtils.NewList()  -- 创建新的协程
    TimingListUtils.Add(NewIndex, 0, UGCGameSystem, "GameState")        -- 单纯地等待GameState加载完成

    TimingListUtils.Add(NewIndex, 0, UGCGameSystem, "GameState", self, function ()
        print("[ExampleTable:example] : GameState is loaded.")
    end)   -- 等待GameState加载完成，然后执行回调

    TimingListUtils.Add(NewIndex, 0, self, function ()
        print("[ExampleTable:example] : This is a condition")
        return true
    end, self, function ()
        print("[ExampleTable:example] : GameState is loaded.")
    end)   -- 使用条件function，当返回true时执行回调

    TimingListUtils.Activate(NewIndex, 0.2, 20) -- 激活协程

end

-- 示例：TimingListUtils.AsyncLoadTables的用法
function ExampleTable:exampleAsyncLoadTables()
    
    local tables = {
        UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCGameModeConfig.UGCGameModeConfig'),
        UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCGameModeDetail.UGCGameModeDetail'),
        UGCGameSystem.GetUGCResourcesFullPath('Asset/Data/Table/UGCSkillDetails.UGCSkillDetails')
    }
    print("[ExampleTable:exampleAsyncLoadTables] : loading" )
    TimingListUtils.AsyncLoadTables(tables, self, function (context, loadedTables)
        print("[ExampleTable:exampleAsyncLoadTables] : loadedTable: [UGCGameModeConfig] : ")
        log_tree(loadedTables["UGCGameModeConfig"])
        print("[ExampleTable:exampleAsyncLoadTables] : loadedTable: [UGCGameModeDetail] : ")
        log_tree(loadedTables["UGCGameModeDetail"])
        print("[ExampleTable:exampleAsyncLoadTables] : loadedTable: [UGCSkillDetails] : ")
        log_tree(loadedTables["UGCSkillDetails"])
    end)

end


-- 定义一个全局表来存储协程和状态
TimingListUtils.CoroutineManager = {}
TimingListUtils.TimeStampList = {}

-- 用于启动协程并存储
function TimingListUtils.StartCoroutine(func)
    local co = coroutine.create(func)
    table.insert(TimingListUtils.CoroutineManager, co)
    return co
end

-- 通过传入的index来挂起协程，直到该index被设置为true
function TimingListUtils.WaitForIndex(index)
    while not TimingListUtils.TimeStampList[index] do
        coroutine.yield()  -- 如果index没有被设为true，则挂起协程
    end
end

-- 用于设置index，激活等待该index的协程
function TimingListUtils.SetIndexTrue(index)
    TimingListUtils.TimeStampList[index] = true  -- 将index设置为true，恢复所有等待该index的协程
    TimingListUtils.ResumeCoroutines()  -- 恢复协程
end

-- 用于恢复所有挂起的协程
function TimingListUtils.ResumeCoroutines()
    for i, co in ipairs(TimingListUtils.CoroutineManager) do
        if coroutine.status(co) == "suspended" then
            coroutine.resume(co)  -- 恢复挂起的协程
        end
    end
end
