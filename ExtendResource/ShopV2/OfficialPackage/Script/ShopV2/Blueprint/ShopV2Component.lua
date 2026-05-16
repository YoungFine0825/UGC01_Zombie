---@class ShopV2Component_C:ActorComponent
---@field ShowTestButton bool
---@field MainUIClassPath FSoftClassPath
---@field TestButtonPath FSoftClassPath
---@field CanLock bool
---@field LockSettingPath FSoftObjectPath
---@field RandomRefreshDropGroupID int32
---@field CostID int32
---@field MaxLockNum int32
---@field ActivateRandomRefreshRule TEnumAsByte<ShopV2_ActivateRefreshRule>
---@field RandomRefreshDuration FShopV2_Timespan__pf3369452713
---@field StartTime FShopV2_Time__pf3369452713
---@field EndTime FShopV2_Time__pf3369452713
---@field RandomRefreshRulePath FSoftObjectPath
---@field LockRefreshRule TEnumAsByte<ShopV2_LockRefreshRule>
---@field RefreshResetRule TEnumAsByte<ShopV2_RefreshResetRule>
---@field ResetPlayTimes int32
---@field ResetTime FShopV2_Time__pf3369452713
---@field UnlockTime FShopV2_Time__pf3369452713
---@field EnableRandomRefresh bool
---@field RetryCount int32
---@field ItemQualityTablePath FSoftObjectPath
--Edit Below--

UGCGameSystem.UGCRequire("ExtendResource.ShopV2.OfficialPackage." .. "Script.ShopV2.ShopV2Manager");
UGCGameSystem.UGCRequire("ExtendResource.ShopV2.OfficialPackage." .. "Script.Common.Common");

local Delegate = UGCGameSystem.UGCRequire("common.Delegate");
local STExtraGMDelegatesMgr = KismetLibrary.New("/Script/ShadowTrackerExtra.STExtraGMDelegatesMgr");

local ShopV2Component = 
{
    ---Replicate
    RandomProductData = {};
    LockData = {};
    RandomRefreshEndTime = 0;
    FreeRefreshCount = 0;
    bActive = false;
    ---

    ValidLockIDs = nil;
    ValidRandomProductIDs = nil;
    LockedNum = 0;
    
    OnShopV2DataUpdated = Delegate.New();

    RefreshRequestQueue = {};

    PlayerDataCache = nil;

    CurrentLevelDropGroupID = 0;
}

function ShopV2Component:ReceiveBeginPlay()
    
    ShopV2Manager:RegisterComponentClass(UGCObjectUtility.GetObjectClass(self));

    if self.EnableRandomRefresh == true then
        if self:GetOwner():HasAuthority() == true then
            --- 如果PlayerKey是0说明PC的玩家信息还没初始化完，需要在PostLogin后LoadData
            if self:GetOwner():GetInt64PlayerKey() == 0 then
                if STExtraGMDelegatesMgr ~= nil then
                    STExtraGMDelegatesMgr.GetInstance().OnPlayerPostLoginDelegate:AddInstance(self.LoadData, self);
                end
            else
                self:LoadData();
            end
    
            if STExtraGMDelegatesMgr ~= nil then
                STExtraGMDelegatesMgr.GetInstance().OnPlayerLogoutDelegate:AddInstance(self.OnPlayerLogout, self);
            end

            if self.RefreshResetRule == ShopV2_RefreshResetRule.PlayTimesPeriod then
                UGCGenericMessageSystem.ListenGlobalMessage(self, 
                UGCGenericMessageSystem.Messages.UGC.LevelFlow.LevelBegin, self, self.CheckPlayTimesPeriod);
            end
        end

        Common.LoadObjectWithSoftPathAsync(self.LockSettingPath, 
            function (Asset)
                if self ~= nil then
                    self:ReadShopLockSetting();
                end
            end
        );

        Common.LoadObjectWithSoftPathAsync(self.RandomRefreshRulePath, 
            function (Asset)
                if self ~= nil then
                    self:ReadRandomRefreshRule();
                end
            end
        ); 

        if UGCObjectUtility.GetPathBySoftObjectPath(self.ItemQualityTablePath) ~= "" then
            Common.LoadObjectWithSoftPathAsync(self.ItemQualityTablePath, 
                function (Asset)
                    if self ~= nil then
                        self:ReadItemQualityTable();
                    end
                end
            );
        end
    end

    if self:GetOwner():HasAuthority() == false then
        self:InitShopUI();
    end
end

function ShopV2Component:ReceiveEndPlay()
    if self.CheckTimer ~= nil then
        UGCTimerUtility.RemoveLuaTimer(self.CheckTimer)
        self.CheckTimer = nil
    end
end

function ShopV2Component:InitShopUI()

    Common.LoadObjectWithSoftPathAsync(self.MainUIClassPath, 
        function (MainUIClass)
            if self == nil or MainUIClass == nil then
                print("[ShopV2Component:InitShopUI] MainUIClass load failed");
                return;
            end

            local MainUI = UserWidget.NewWidgetObjectBP(self:GetOwner(), MainUIClass);
            MainUI:AddToViewport(10050);
            MainUI:SetVisibility(ESlateVisibility.Collapsed);
        end
    );

    if self.ShowTestButton == true then
        Common.LoadObjectWithSoftPathAsync(self.TestButtonPath, 
            function (ButtonClass)
                if self == nil or ButtonClass == nil then
                    print("[ShopV2Component:InitShopUI] TestButtonClass load failed");
                    return;
                end
                
                local Button = UserWidget.NewWidgetObjectBP(self:GetOwner(), ButtonClass);
                Button:AddToViewport(10000);
            end
        );
    end
end

function ShopV2Component:LoadData()
    
    print("[ShopV2Component:LoadData] Start load data");
    self.PlayerDataCache = self:ReadPlayerData();
    local ShopV2Data = self.PlayerDataCache["ShopV2"];

    self.LockData = ShopV2Data.RefreshLock;
    UnrealNetwork.RepLazyProperty(self, "LockData");

    self.RandomProductData.Products = ShopV2Data.RandomProducts;
    UnrealNetwork.RepLazyProperty(self, "RandomProductData");

    self.FreeRefreshCount = ShopV2Data.FreeRefreshData.Count;
    UnrealNetwork.RepLazyProperty(self, "FreeRefreshCount");

    self.RandomRefreshEndTime = ShopV2Data.RandomRefreshEndTime;
    UnrealNetwork.RepLazyProperty(self, "RandomRefreshEndTime");
    
    UnrealNetwork.RepLazyProperty(self, "bActive");
    
    Common.LoadObjectWithSoftPathAsync(self.LockSettingPath, 
        function (Asset)
            if self ~= nil then
                self:ReadShopLockSetting();

                -- 因为要获取LockID信息，所以必须在ReadShopLockSetting后执行
                self:CheckTime(); 
            end
        end
    );
end

function ShopV2Component:OnPlayerLogout(PlayerController)
    
    print("[ShopV2Component:OnPlayerLogout] Player Logout")

    if PlayerController ~= self:GetOwner() then
        return;
    end

    if self.LockRefreshRule == ShopV2_LockRefreshRule.ExitGame then
        print("[ShopV2Component:OnPlayerLogout] Clear lock")
        self:ConfirmLocks({});
    end
end

function ShopV2Component:CheckPlayTimesPeriod()

    self.PlayerDataCache = self:ReadPlayerData();
    local PlayRounds = self.PlayerDataCache.ShopV2.FreeRefreshData.PlayRounds or 0;
    self.PlayerDataCache.ShopV2.FreeRefreshData.PlayRounds = PlayRounds + 1;
    if self.PlayerDataCache.ShopV2.FreeRefreshData.PlayRounds % self.ResetPlayTimes == 0 then
        self.PlayerDataCache.ShopV2.FreeRefreshData.Count = 0;
        self.FreeRefreshCount = 0;
        UnrealNetwork.RepLazyProperty(self, "FreeRefreshCount");
    end

    self:WritePlayerData(self.PlayerDataCache);
end

function ShopV2Component:GetIsLocked(LockID)

    if self.LockData == nil or self.LockData.Locks[LockID] == nil then
        return false;
    end

    return self.LockData.Locks[LockID];
end

function ShopV2Component:GetFreeRefreshCount()
    
    if self:GetOwner():HasAuthority() == true then
        self.PlayerDataCache = self:ReadPlayerData();
        return self.PlayerDataCache.ShopV2.FreeRefreshData.Count;
    else
        return self.FreeRefreshCount;
    end
end

function ShopV2Component:ActivateRandomRefresh(DropGroupID)
    
    UnrealNetwork.CallUnrealRPC(self:GetOwner(), self, "Server_ActivateRandomRefresh", DropGroupID);
end

function ShopV2Component:Server_ActivateRandomRefresh(DropGroupID)
    
    if self:GetOwner():HasAuthority() == false or self.EnableRandomRefresh == false then
        return;
    end

    if self.ActivateRandomRefreshRule ~= ShopV2_ActivateRefreshRule.UseDuration then
        return;
    end

    self.CurrentLevelDropGroupID = DropGroupID or self.RandomRefreshDropGroupID;
    self:Server_ConfirmLocks({});
    self:RandomRefresh(true);
    self.bActive = true;
    UnrealNetwork.RepLazyProperty(self, "bActive");
end

function ShopV2Component:DeactivateRandomRefresh()

   print("[ShopV2Component:DeactivateRandomRefresh] Deactivate!");
   UnrealNetwork.CallUnrealRPC(self:GetOwner(), self, "Server_DeactivateRandomRefresh");
end

function ShopV2Component:Server_DeactivateRandomRefresh()

    print("[ShopV2Component:Server_DeactivateRandomRefresh] Deactivate!");
    
    if self:GetOwner():HasAuthority() == false or self.EnableRandomRefresh == false then
        return;
    end

    ---立即结束
    self.RandomRefreshEndTime = UGCGameSystem.GetServerTimeSec();
    local Data = self:ReadPlayerData();
    Data["ShopV2"].RandomRefreshEndTime = self.RandomRefreshEndTime;
    self:WritePlayerData(Data);
    UnrealNetwork.RepLazyProperty(self, "RandomRefreshEndTime");

    self.bActive = false;
    UnrealNetwork.RepLazyProperty(self, "bActive");
end

function ShopV2Component:ConfirmLocks(LockList)
    
    UnrealNetwork.CallUnrealRPC(self:GetOwner(), self, "Server_ConfirmLocks", LockList);
end

function ShopV2Component:Server_ConfirmLocks(LockList)
    
    print("[ShopV2Component:Server_AddProductLock] Start set lock");

    self.PlayerDataCache = self:ReadPlayerData();
    
    if LockList ~= nil and #LockList > 0 then
        for _, LockID in ipairs(LockList) do
            self.PlayerDataCache.ShopV2.RefreshLock.Locks[LockID] = true;
        end
    else
        self.PlayerDataCache.ShopV2.RefreshLock.Locks = {};
    end

    if self.LockRefreshRule == ShopV2_LockRefreshRule.WithTime then
        local CurrentDate = Common.GetCurrentDate();
        self.PlayerDataCache.ShopV2.RefreshLock.NextUnlockTime = self:CalculateNextUnlockTime();
    end

    self:WritePlayerData(self.PlayerDataCache);
    self.LockData = self.PlayerDataCache.ShopV2.RefreshLock;
    UnrealNetwork.RepLazyProperty(self, "LockData");

    print("[ShopV2Component:Server_AddProductLock] Set lock finished");
end

function ShopV2Component:CalculateNextUnlockTime()
    
    local CurrentDate = Common.GetCurrentDate();
    local CurrentTime = CurrentDate.hour * 3600 + CurrentDate.min * 60 + CurrentDate.sec;
    local RefreshTime = self.UnlockTime.Hour * 3600 + self.UnlockTime.Min * 60 + self.UnlockTime.Sec;

    local ZeroTime = os.time({year=CurrentDate.year, month=CurrentDate.month, day=CurrentDate.day, hour=0, min=0, sec=0});
    if CurrentTime < RefreshTime then
        return ZeroTime + RefreshTime;
    end

    return ZeroTime + 86400 + RefreshTime;
end

function ShopV2Component:RefreshRandomProducts()
    if self.bBlockRefreshRandomProducts then
        UGCWidgetManagerSystem.ShowTipsUI("正在刷新刷新")
        return
    end

    self.bBlockRefreshRandomProducts = true;
    print("[ShopV2Component:RefreshRandomProducts] Start refresh random products")
    UnrealNetwork.CallUnrealRPC(self:GetOwner(), self, "Server_RefreshRandomProducts");
end

function ShopV2Component:CheckTime()

    local CurrentTime = Common.GetCurrentTime();

    ---刷新随机商品
    if self.ActivateRandomRefreshRule == ShopV2_ActivateRefreshRule.UseTime then
        if self.PlayerDataCache.ShopV2.bInit == true and CurrentTime >= self.RandomRefreshEndTime then
            self.PlayerDataCache.ShopV2.bInit = false;
        end
    
        local CurrentDate = os.date("*t", CurrentTime);
        local StartTime = 
            os.time({year=CurrentDate.year, month=CurrentDate.month, day=CurrentDate.day, hour=self.StartTime.Hour, min=self.StartTime.Min, sec=self.StartTime.Sec});
        local EndTime =
            os.time({year=CurrentDate.year, month=CurrentDate.month, day=CurrentDate.day, hour=self.EndTime.Hour, min=self.EndTime.Min, sec=self.EndTime.Sec});
    
        if self.ActivateRandomRefreshRule == ShopV2_ActivateRefreshRule.UseTime 
        and self.PlayerDataCache.ShopV2.bInit == false 
        and CurrentTime >= StartTime
        and CurrentTime < EndTime then
            self:RandomRefresh(false);
        end
    end

    ---重置免费刷新次数
    if self.RefreshResetRule == ShopV2_RefreshResetRule.WithTime 
    and CurrentTime >= self.PlayerDataCache.ShopV2.FreeRefreshData.NextResetTime then
        self.PlayerDataCache.ShopV2.FreeRefreshData.Count = 0;
        self.FreeRefreshCount = 0;
        UnrealNetwork.RepLazyProperty(self, "FreeRefreshCount");

        local CurrentDate = os.date("*t", CurrentTime);
        local ResetTime = os.time({year=CurrentDate.year, month=CurrentDate.month, day=CurrentDate.day, hour=self.ResetTime.Hour, min=self.ResetTime.Min, sec=self.ResetTime.Sec});
        self.PlayerDataCache.ShopV2.FreeRefreshData.NextResetTime = CurrentTime < ResetTime and ResetTime or ResetTime + 86401;
        self:WritePlayerData(self.PlayerDataCache);
    end

    ---重置锁
    if self.LockRefreshRule == ShopV2_LockRefreshRule.WithTime
    and CurrentTime >= self.PlayerDataCache.ShopV2.RefreshLock.NextUnlockTime then
        self:Server_ConfirmLocks({});
    end

    self.CheckTimer = UGCTimerUtility.CreateLuaTimer(1,
        function ()
            if UE.IsValid(self) then
                self:CheckTime();
            end
        end,
        false
    );
end

function ShopV2Component:Server_RefreshRandomProducts()
    
    print("[ShopV2Component:Server_RefreshRandomProducts] Start refresh random products");

    if self:GetRandomRefreshPrice() == 0 then
        self:RandomRefresh(false);
        return;
    end

    local Price = self:GetRandomRefreshPrice();
    local Callback = Delegate.New();
    Callback:Add(self.OnRemoveVirtualItem, self);
    ShopV2Manager:GetVirtualItemManager():RemoveItem(self:GetOwner(), self.CostID, Price, Callback);
end

function ShopV2Component:RandomRefresh(bForce)

    self.PlayerDataCache = self:ReadPlayerData();
    local Products = self.PlayerDataCache.ShopV2.RandomProducts;
    local Locks = self.PlayerDataCache.ShopV2.RefreshLock.Locks or {};
    
    ---因为是按顺序刷新，所以必须提前记录上锁的ProductID防止重复
    local Map = {};
    for Index, LockID in ipairs(ShopV2Manager.OrderedLockList) do
        if self:GetIsLocked(LockID) == true then
            Map[Products[Index].ProductID] = true;
        end
    end

    --- 处理刷出商品的格子
    local Result = UGCDropSystem.DropItemsByGroup(self.CurrentLevelDropGroupID);
    local Index = 1;
    for ProductID, _ in pairs(Result) do
        ---刷出的ProductID数量超出格子数则退出
        if Index > #ShopV2Manager.OrderedLockList then
            break;
        end

        local LockID = ShopV2Manager.OrderedLockList[Index];
        
        if self:GetIsLocked(LockID) == false and Map[ProductID] == nil then
            local ID = ShopV2Manager:IsProductValid(ProductID) == false and 0 or ProductID;
            local Data = {};
            Data.LockID = LockID;
            Data.ProductID = ID;
            Products[Index] = Data;
            Map[ProductID] = true;
        end
        
        Index = Index + 1;
    end

    --- 处理没有刷出商品的格子
    for i = Index, #ShopV2Manager.OrderedLockList do
        local LockID = ShopV2Manager.OrderedLockList[Index];

        if self:GetIsLocked(LockID) == false then
            local Data = {};
            Data.LockID = LockID;
            Data.ProductID = 0;
            Products[Index] = Data;
        end
    end

    ---向前补齐结果
    local Slow = 1;
    for Fast, Data in ipairs(Products) do
        if Data.ProductID ~= 0 then
            Products[Slow].ProductID, Data.ProductID = Data.ProductID, Products[Slow].ProductID;
            ---如果有上锁，也要交换
            if Locks[Data.LockID] == true then
                Locks[Data.LockID] = false;
                Locks[Products[Slow].LockID] = true;
            end
            Slow = Slow + 1;
        end 
    end
    
    if self.PlayerDataCache.ShopV2.bInit == false or bForce == true then
        self.PlayerDataCache.ShopV2.bInit = true;
        self.PlayerDataCache.ShopV2.RandomRefreshEndTime = self:CalculateRefreshEndTime();
        self.RandomRefreshEndTime = self.PlayerDataCache.ShopV2.RandomRefreshEndTime;
        UnrealNetwork.RepLazyProperty(self, "RandomRefreshEndTime");
    else
        self.PlayerDataCache.ShopV2.FreeRefreshData.Count = self.PlayerDataCache.ShopV2.FreeRefreshData.Count + 1;
    end

    self:WritePlayerData(self.PlayerDataCache);
    self.RandomProductData.Products = Products;
    self.RandomProductData.Counter = self.RandomProductData.Counter or 0;
    if self.RandomProductData.Counter >= 1000 then
        self.RandomProductData.Counter = 0;
    end

    self.RandomProductData.Counter = self.RandomProductData.Counter + 1;

    UnrealNetwork.RepLazyProperty(self, "RandomProductData");
    self.FreeRefreshCount = self.PlayerDataCache.ShopV2.FreeRefreshData.Count;
    UnrealNetwork.RepLazyProperty(self, "FreeRefreshCount");
    self.LockData = self.PlayerDataCache.ShopV2.RefreshLock;
    UnrealNetwork.RepLazyProperty(self, "LockData");
end

function ShopV2Component:CalculateRefreshEndTime()
    
    local Time = 0;
    if self.ActivateRandomRefreshRule == ShopV2_ActivateRefreshRule.UseTime then
        local CurrentDate = Common.GetCurrentDate();
        Time = os.time({year=CurrentDate.year, month=CurrentDate.month, day=CurrentDate.day, hour=self.EndTime.Hour, min=self.EndTime.Min, sec=self.EndTime.Sec});
    elseif self.ActivateRandomRefreshRule == ShopV2_ActivateRefreshRule.UseDuration then
        Time = Common.GetCurrentTime() + self:GetDurationTime();
    end

    print(string.format("[ShopV2Component:GetRefreshEndTime] EndTime=%d", Time));
    return Time; 
end

function ShopV2Component:OnRemoveVirtualItem(Result)
    
    if Result.bSucceeded == true then
        self:RandomRefresh(false);
    end
end

function ShopV2Component:GetRandomRefreshPrice()
    
    if ShopV2Manager.RandomRefreshRule == nil then
        return 0;
    end

    local Num = self:GetFreeRefreshCount();
    for i, Rule in ipairs(ShopV2Manager.RandomRefreshRule) do
        if Num < Rule.RefreshNum then
            return Rule.Price;
        end
    end
    
    return ShopV2Manager.RandomRefreshRule[#ShopV2Manager.RandomRefreshRule].Price;
end

function ShopV2Component:GetDurationTime()
    
    local time = 0;
    time = time + self.RandomRefreshDuration.Day * 86400;
    time = time + self.RandomRefreshDuration.Hour * 3600;
    time = time + self.RandomRefreshDuration.Min * 60;
    time = time + self.RandomRefreshDuration.Sec;

    return time;
end

function ShopV2Component:ReadPlayerData()
    
    if self:GetOwner():HasAuthority() == false then
        return;
    end

    local UID = self:GetOwner():GetInt64UID();

    print(string.format("ShopV2Component: Begin read UID: %d PlayerData", UID));

    local PlayerData = UGCPlayerStateSystem.GetPlayerArchiveData(UID);

    local bChange = false;
    if PlayerData == nil then
        print(string.format("ShopV2Component: UID: %d PlayerData is empty, creating new one.", UID))
        PlayerData = {
            ShopV2 = 
            {
                RandomProducts = {},

                FreeRefreshData = {
                    Count = 0,
                    NextResetTime = 0,
                    PlayRounds = 0
                },

                RefreshLock = {
                    Locks = {},
                    NextUnlockTime = 0
                },
                
                bInit = false,
                RandomRefreshEndTime = 0,
            }
        };
        bChange = true;
    end

    if PlayerData["ShopV2"] == nil then
        print(string.format("ShopV2Component: UID: %d ShopV2Data is empty, creating new one.", UID));
        PlayerData["ShopV2"] = {};
        bChange = true;
    end

    if PlayerData["ShopV2"].RandomProducts == nil then
        print(string.format("ShopV2Component: UID: %d RandomProducts is empty, creating new one.", UID));
        PlayerData["ShopV2"].RandomProducts = {};
        PlayerData["ShopV2"].bInit = false;
        bChange = true;
    end

    if PlayerData["ShopV2"].FreeRefreshData == nil then
        print(string.format("ShopV2Component: UID: %d FreeRefreshData is empty, creating new one.", UID));
        PlayerData["ShopV2"].FreeRefreshData = {
            Count = 0,
            NextResetTime = 0
        };
        bChange = true;
    end

    if PlayerData["ShopV2"].RandomRefreshEndTime == nil then
        PlayerData["ShopV2"].RandomRefreshEndTime = 0;
        bChange = true;
    end

    if PlayerData["ShopV2"].RefreshLock == nil then
        print(string.format("ShopV2Component: UID: %d Locks is empty, creating new one.", UID));
        PlayerData["ShopV2"].RefreshLock = {
            Locks = {},
            NextUnlockTime = 0
        }
        bChange = true;
    end

    if bChange == true then
        UGCPlayerStateSystem.SavePlayerArchiveData(UID, PlayerData);
    end

    print(string.format("ShopV2Component: Read UID: %d PlayerData Success", UID));
    return PlayerData;
end

-- 写入玩家数据
---@param PlayerData table
function ShopV2Component:WritePlayerData(PlayerData)

    if self:GetOwner():HasAuthority() == false then
        return false;
    end

    local UID = self:GetOwner():GetInt64UID();
    print(string.format("ShopV2Component:Begin write PlayerKey:%d PlayerData", UID));
    local bSuccess = UGCPlayerStateSystem.SavePlayerArchiveData(UID, PlayerData);

    if bSuccess == true then
        print(string.format("ShopV2Component:Write UID:%d PlayerData Success", UID));
    else
        print(string.format("ShopV2Component:Write UID:%d PlayerData Failed", UID));
    end

    return bSuccess;
end

function ShopV2Component:GetAvailableServerRPCs()
    return
        "Server_ConfirmLocks",
        "Server_RefreshRandomProducts",
        "Server_ActivateRandomRefresh",
        "Server_DeactivateRandomRefresh";
end

function ShopV2Component:GetReplicatedProperties()
    return 
        {"LockData", "Lazy"},
        {"RandomProductData", "Lazy"},
        {"FreeRefreshCount", "Lazy"},
        {"RandomRefreshEndTime", "Lazy"},
        {"bActive", "Lazy"};
end

function ShopV2Component:OnRep_RandomProductData()
    
    print("[ShopV2Component:OnRep_RandomProductData] RandomProductData replicated!");

    self:SetValidRandomProducts();
    self.bBlockRefreshRandomProducts = false

    if ShopV2Manager:IsSelectingRandomTab() == true then
        ShopV2Manager:ResetSelectedProductID()
        ShopV2Manager:RefreshProducts();
    end
end

function ShopV2Component:OnRep_LockData()
    
    print("[ShopV2Component:OnRep_Locks] Locks replicated!");
    log_tree(self.LockData);

    if self.EnableRandomRefresh == false then
        return;
    end

    if self.LockData.Locks == nil then
        return;
    end

    self.LockedNum = 0;
    for DropID, bLocked in pairs(self.LockData.Locks) do
        if bLocked == true then
            self.LockedNum = self.LockedNum + 1;
        end
    end

    if ShopV2Manager:IsSelectingRandomTab() == true then
        -- ShopV2Manager:ResetSelectedProductID()
        ShopV2Manager:RefreshProducts();
    end
end

function ShopV2Component:OnRep_FreeRefreshCount()
    
    print("[ShopV2Component:OnRep_FreeRefreshCount] FreeRefreshCount replicated!");

    if self.EnableRandomRefresh == false then
        return;
    end


    if ShopV2Manager:IsSelectingRandomTab() == true then
        ShopV2Manager:RefreshProducts();
    end
end

function ShopV2Component:OnRep_RandomRefreshEndTime()
    
    print("[ShopV2Component:OnRep_RandomRefreshEndTime] RandomRefreshEndTime replicated!");
    ShopV2Manager:UpdateRandomRefreshTab();

    if Common.GetCurrentTime() < self.RandomRefreshEndTime and self.bActive == true then
        ShopV2Manager:SetEntryButtonVisibility(ESlateVisibility.SelfHitTestInvisible);
    else
        ShopV2Manager:SetEntryButtonVisibility(ESlateVisibility.Collapsed);
    end
end

function ShopV2Component:OnRep_bActive()
    
    print("[ShopV2Component:OnRep_bActive] bActive replicated!");

    if self.bActive == true then
        ShopV2Manager:SetEntryButtonVisibility(ESlateVisibility.SelfHitTestInvisible);
    else
        ShopV2Manager:SetEntryButtonVisibility(ESlateVisibility.Collapsed);
    end
end

function ShopV2Component:SetValidRandomProducts()
    
    self.ValidLockIDs = {};
    self.ValidRandomProductIDs = {};

    if self.RandomProductData.Products ~= nil then
        for _, Data in pairs(self.RandomProductData.Products) do
            if Data.ProductID ~= nil and Data.ProductID > 0 then
                table.insert(self.ValidLockIDs, Data.LockID);
                table.insert(self.ValidRandomProductIDs, Data.ProductID);
            end
        end 
    end

    ugcprint("[ShopV2Component:SetValidRandomProducts] Valid RandomProducts");
    log_tree("ValidLockIDs=", self.ValidLockIDs);
    log_tree("ValidRandomProducts=", self.ValidRandomProducts);
end

function ShopV2Component:ReadShopLockSetting()
    
    print("[ShopV2Component:ReadShopLockSetting] Start read shop lock setting");

    if self.LockSettingPath == nil then
        print("[ShopV2Component:ReadShopRefreshSetting] RefreshSettingPath is nil!");
        return;
    end

    local Table = UGCGameSystem.GetTableData(Common.GetDataTablePath(self.LockSettingPath));

    ShopV2Manager.OrderedLockList = {};
    for _, Data in pairs(Table) do
        table.insert(ShopV2Manager.OrderedLockList, Data.LockID);
    end
end

function ShopV2Component:ReadRandomRefreshRule()
    
    print("[ShopV2Component:ReadRandomRefreshRule] Start read shop random refresh rule");

    if self.RandomRefreshRulePath == nil then
        print("[ShopV2Component:ReadRandomRefreshRule] RandomRefreshRulePath is nil!");
        return;
    end

    local Table = UGCGameSystem.GetTableData(Common.GetDataTablePath(self.RandomRefreshRulePath));

    ShopV2Manager.RandomRefreshRule = {};
    for _, Data in pairs(Table) do
        table.insert(ShopV2Manager.RandomRefreshRule, {RefreshNum=Data.RefreshNum, Price=Data.Price});
    end
end

function ShopV2Component:ReadItemQualityTable()
    
    print("[ShopV2Component:ReadItemQualityTable] Start read item quality rank");
    ShopV2Manager.ItemQuality = {};

    if self.ItemQualityTablePath == nil then
        print("[ShopV2Component:ReadItemQualityTable] ItemQualityTablePath is nil");
        return;
    end

    local Path = Common.GetDataTablePath(self.ItemQualityTablePath);
    if Path == "" then
        print("[ShopV2Component:ReadItemQualityTable] ItemQualityTablePath is empty");
        return;
    end

    local Table = UGCGameSystem.GetTableData(Common.GetDataTablePath(self.ItemQualityTablePath));
    for _, Data in pairs(Table) do
        ShopV2Manager.ItemQuality[Data.ItemID] = Data.QualityRank;
    end
end

return ShopV2Component
