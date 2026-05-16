Common = Common or {}

CommonImpl = CommonImpl or {};

--- 读表
---@param Table string
function Common.GetTableDataByKey(TablePath, Key)
    local Table = UGCGameSystem.GetTableData(TablePath);
    for Index, Data in pairs(Table) do
        if Index == Key then
            return Data;
        end
    end

    return nil;
end

---@param SoftObjectPath FSoftObjectPath
function Common.GetDataTablePath(SoftObjectPath)
    
    local Path = UGCObjectUtility.GetPathBySoftObjectPath(SoftObjectPath);
    Path = string.match(Path, "^.*Asset/(.+)$") or "";
    Path = string.match(Path, "^([^%.]+)") or "";

    return Path;
end

---@param SoftClassPath FSoftClassPath
function Common.GetClassWithSoftPath(SoftClassPath)
    
    if SoftClassPath == nil then
        print("SignInEventManager: SoftClassPath is not valid");
        return nil;
    end

    local Path = UGCObjectUtility.GetPathBySoftObjectPath(SoftClassPath);
    if Path == nil then
        print("SignInEventManager: Path is nil");
        return nil;
    end

    return UE.LoadClass(Path);
end

function Common.GetProductDatas()
   
    return CommonImpl:GetProductDatas();
end

function Common.GetObjectDatas()
    
    return CommonImpl:GetObjectDatas();
end

--- 异步加载 Object
---@param SourcePath string
---@param CallBack function
function Common.LoadObjectAsync(SourcePath, CallBack)
    
    local SoftObjectPath = UGCObjectUtility.MakeSoftObjectPath(SourcePath);
    Common.LoadObjectWithSoftPathAsync(SoftObjectPath, CallBack);
end

--- 异步加载 Object
---@param SoftObjectPath FSoftObjectPath
---@param CallBack function
function Common.LoadObjectWithSoftPathAsync(SoftObjectPath, CallBack)
    UGCObjectUtility.AsyncLoadObjectBySoftPath(SoftObjectPath, CallBack)
end

---@return osdate
function Common.GetCurrentDate()
    
    return os.date("*t", Common.GetCurrentTime());
end

function Common.GetCurrentTime(bPrintLog)

    if bPrintLog == nil then
        bPrintLog = true;
    end
    
    local CurrentTime = UGCGameSystem.GetServerTimeSec();
    if CurrentTime == false then
        CurrentTime = 0;
    end

    if bPrintLog == true then
        print(string.format("[Common.GetCurrentTime] Current Timestamp=%d", CurrentTime));
    end

    return CurrentTime;
end

---@param StartDate FDateTime
---@param EndDate FDateTime
function Common.CheckStartEndDate(StartDate, EndDate)
    
    print(string.format("[Common.CheckStartEndDate] Start check start end date"));

    local CurrentTime = Common.GetCurrentTime();
    local StartTime = Common.GetTimestampFromDateTime(StartDate);
    print(string.format("[Common.CheckStartEndDate] StartTime=%d", StartTime));
    local EndTime = Common.GetTimestampFromDateTime(EndDate);
    print(string.format("[Common.CheckStartEndDate] EndTime=%d", EndTime));

    return CurrentTime >= StartTime and CurrentTime < EndTime;
end

---@param StartTime int
---@param EndTime int
function Common.CheckStartEndTime(StartTime, EndTime)
    
    print(string.format("[Common.CheckStartEndDate] Start check start end time"));

    local CurrentTime = Common.GetCurrentTime();
    print(string.format("[Common.CheckStartEndDate] StartTime=%d", StartTime));
    print(string.format("[Common.CheckStartEndDate] EndTime=%d", EndTime));

    return CurrentTime >= StartTime and CurrentTime < EndTime;
end

---@param Date FDateTime
---@return number
function Common.GetTimestampFromDateTime(Date)
    
    local Year, Month, Day, Hour, Minute, Second = KismetMathLibrary.BreakDateTime(Date);
    Year = Year < 1970 and 1970 or Year;
    Hour = Hour + 8;
    
    -- Lua 时间戳有最大值，大约大于了 3000.1.1 就会返回 nil
    local Time = os.time({year=Year, month=Month, day=Day, hour=Hour, min=Minute, sec=Second});
    Time = Time == nil and 32503694400 or Time;

    return Time;
end

--- 加载资源
--- 获得道具界面
--- 二次确认界面
--- 通用提示界面
--- 道具Tips
