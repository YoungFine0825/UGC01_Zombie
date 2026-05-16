---@class BP_HeroSelectionTestActor_C:AActor
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local BP_HeroSelectionTestActor = {}


local _TestInterval = 0.2
local _LogDuration = 100000

-- 测试状态管理
local TestManager = {
    _currentTest = nil,
    _testQueue = {},
    _testResults = {},
    _isRunning = false,
    _rpcActor = nil
}

-- 单元测试工具类
local UnitTest = {
    AssertTrue = function(Expression, ErrorMessage)
        if not Expression then
            local msg = "[HeroSelectionTest] AssertTrue Failed: " .. ErrorMessage
            TestManager:RecordResult(false, msg)
            assert(Expression, msg)
        end
    end,

    AssertEqual = function(A, B, ErrorMessage)
        if A ~= B then
            local msg = string.format("[HeroSelectionTest] AssertEqual Failed: %s != %s, %s", tostring(A), tostring(B), ErrorMessage)
            TestManager:RecordResult(false, msg)
            assert(A ~= B, msg)
        end
    end,

    Pass = function()
        TestManager:RecordResult(true)
        TestManager:RunNextTest()
    end,

    UnPass = function(ErrorMessage)
        TestManager:RecordResult(false, ErrorMessage or "Manual UnPass")
    end,

    GetCurrentTestName = function()
        return TestManager._currentTest and TestManager._currentTest.name or "Unknown"
    end,

    CallRPC = function(FuncName, ...)
        print("[HeroSelectionTest] RPC Call: " .. FuncName)
        local PC = UGCGameSystem.GetLocalPlayerController()
        UnrealNetwork.CallUnrealRPC(PC, TestManager._rpcActor, "Server_CallRPC", FuncName, ...)
    end,
}

-- 测试管理方法
function TestManager:PushTest(name, func)
    table.insert(self._testQueue, {
        name = name,
        func = func
    })
end

function TestManager:RunNextTest()
    if #self._testQueue > 0 then
        UGCTimerUtility.CreateLuaTimer(_TestInterval, function()
            self._currentTest = table.remove(self._testQueue, 1)
            print("[HeroSelectionTest] Run Test: " .. self._currentTest.name)
            UGCDebugSystem.PrintToScreen("Testing... " .. self._currentTest.name, { A = 1, B = 1, G = 1, R = 1 }, _LogDuration)
            local success, err = pcall(function()
                self._currentTest.func(UnitTest)
            end)
            if not success then
                local msg = string.format("[HeroSelectionTest] Test %s failed with error: %s",
                        self._currentTest.name, tostring(err))
                print(msg)
                self:RecordResult(false, msg)
            end
        end)
    else
        self._isRunning = false
        print("[HeroSelectionTest] All Tests Completed")
        UGCDebugSystem.PrintToScreen("All Tests Completed", { A = 1, B = 0, G = 1, R = 0 }, _LogDuration)
    end
end

function TestManager:RecordResult(success, message)
    if not success then
        print(message)
        UGCDebugSystem.PrintToScreen(message, { A = 1, B = 0, G = 0, R = 1 }, _LogDuration)
    end
    table.insert(self._testResults, {
        name = self._currentTest.name,
        success = success,
        message = message or "",
        time = os.time()
    })
end

function TestManager:StartTesting()
    if not self._isRunning and #self._testQueue > 0 then
        self._isRunning = true
        self:RunNextTest()
    end
end

function BP_HeroSelectionTestActor:ReceiveBeginPlay()
    BP_HeroSelectionTestActor.SuperClass.ReceiveBeginPlay(self)

    -- Test only work on client
    if not self:HasAuthority() then
        UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionManager")
        if HeroSelectionManager:IsInitialized() then
            self:DelayStartTest(3)
        else
            HeroSelectionManager.OnInitialized:Add(function()
                self:DelayStartTest(3)
            end)
        end
    end
end

function BP_HeroSelectionTestActor:DelayStartTest(Duration)
    UGCTimerUtility.CreateLuaTimer(Duration, function()
        self:StartTest()
    end)
end

function BP_HeroSelectionTestActor:StartTest()
    TestManager._testQueue = {}
    TestManager._testResults = {}
    TestManager._rpcActor = self

    local Manager = UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.Test.TestHeroSelectionManager")
    self:AddTestsToQueue(Manager:GetTests())
    local ViewModel = UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.Test.TestHeroSelectionViewModel")
    self:AddTestsToQueue(ViewModel:GetTests())

    TestManager:StartTesting()
end

function BP_HeroSelectionTestActor:AddTestsToQueue(Tests)
    for _, Test in ipairs(Tests) do
        TestManager:PushTest(Test.Name, Test.TestFunc)
    end
end

function BP_HeroSelectionTestActor:Server_CallRPC(FuncName, ...)
    print("[HeroSelectionTest] RPC Call: " .. FuncName)
    for i, v in ipairs({...}) do
        print("Arg[" .. i .. "] = " .. tostring(v))
    end
    HeroSelectionManager[FuncName](HeroSelectionManager, ...)
end

function BP_HeroSelectionTestActor:GetAvailableServerRPCs()
    return "Server_CallRPC"
end

return BP_HeroSelectionTestActor
