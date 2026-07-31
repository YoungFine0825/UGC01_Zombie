---@class BP_UGCBackpack_C:BP_BackpackComponentV2_C
---@field MainWeaponAffixType TEnumAsByte<Enum_MainWeaponAffixType>
--Edit Below--
---@type BP_UGCBackpack_C
local BP_UGCBackpack = {}

BP_UGCBackpack.AffixRecords = {}

local GameData = UGCGameSystem.UGCRequire("Script.Blueprint.UGCGameData");

function BP_UGCBackpack:ReceiveBeginPlay()
    BP_UGCBackpack.SuperClass.ReceiveBeginPlay(self);
    ugcprint("[BP_UGCBackpack:ReceiveBeginPlay] Enter");
end

function BP_UGCBackpack:CanUseItemV2(ItemDefineID)
    local Ret = BP_UGCBackpack.SuperClass.CanUseItemV2(self, ItemDefineID);
    
    -- 局外不显示
    if GameData.GetGameModeName(UGCMultiMode.GetModeID()) == GameData.ModeName.Lobby then
        return false;
    end

    return Ret;
end

function BP_UGCBackpack:CanDropItemV2(ItemDefineID, Count)
    local Ret = BP_UGCBackpack.SuperClass.CanDropItemV2(self, ItemDefineID, Count);

    -- 局外不可丢弃
    if GameData.GetGameModeName(UGCMultiMode.GetModeID()) == GameData.ModeName.Lobby then
        return 0;
    end

    return Ret;
end

function BP_UGCBackpack:InitField()
    self.OwnerController = UGCActorComponentUtility.GetOwner(self);
    if self.OwnerController == nil then
        ugcprint("[BP_UGCBackpack:InitPersistDataAfterPlayerEnter] OwnerController is nil");
        return;
    end

    -- 大厅没创建Character
    self.OwnerCharacter = UGCGameSystem.GetPlayerPawnByPlayerController(self.OwnerController);
    if self.OwnerCharacter == nil then
        ugcprint("[BP_UGCBackpack:InitEventAfterPlayerEnter] OwnerCharacter is nil!");
    end

    local GS = UGCGameSystem.GetGameState();
    if GS == nil then
        ugcprint("[BP_UGCBackpack:InitEventAfterPlayerEnter] GS is nil!");
        return;
    end

    self.AffixManager = GS.EquipmentAffixManager;
    if self.AffixManager == nil then
        ugcprint("[BP_UGCBackpack:InitEventAfterPlayerEnter] AffixManager is nil!");
        return;
    end
end

---背包初始化函数
function BP_UGCBackpack:InitEventAfterPlayerEnter()
    -- 由父lua中触发，在持久化数据初始化之前
    ugcprint("[BP_UGCBackpack:InitEventAfterPlayerEnter] Enter");
    
    self:InitField();

    --先保证背包里有默认武器
    self:EnsureDefaultWeapons(true)

    if self.OwnerController ~= nil then
        -- 在玩家PostLogin之后执行初始化逻辑
        local Message = UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnRespawn;
        UGCGenericMessageSystem.ListenGlobalMessage(self, Message, self.OwnerController, 
            function ()
                ugcprint("[BP_UGCBackpack:InitEventAfterPlayerEnter] Bind PawnRespawn");
                self:OnPawnRespawn();
            end
        );
    else
        ugcprint("[BP_UGCBackpack:InitEventAfterPlayerEnter] OwnerController is nil");
    end

    -- 绑定装备事件
    self.ItemEquipDelegate:Add(function(SlotName, DefineID)
        ugcprint("[BP_UGCBackpack:InitEventAfterPlayerEnter] Bind ItemEquipDelegate");
        self:OnEquipItem(SlotName, DefineID);
    end);

    -- 绑定卸装事件
    self.ItemUnEquipDelegate:Add(function(SlotName, DefineID)
        ugcprint("[BP_UGCBackpack:InitEventAfterPlayerEnter] Bind ItemUnEquipDelegate");
        self:OnUnequipItem(SlotName, DefineID);
    end);

    if self.OwnerCharacter then
        -- 绑定切换武器
        self.OwnerCharacter.OnPlayerSwitchWeaponDelegate:Add(self.OnPlayerSwitchWeapon, self);
    end
end

---重生后处理事宜
function BP_UGCBackpack:OnPawnRespawn()
    ugcprint("[BP_UGCBackpack:OnPawnRespawn] Enter");

    self:InitField();

    if self.AffixManager == nil then
        ugcprint("[BP_UGCBackpack:OnPawnRespawn] AffixManager or OwnerCharacter is nil!");
        return;
    end

    if self.OwnerCharacter then
        -- 重生，重新绑定切换武器
        self.OwnerCharacter.OnPlayerSwitchWeaponDelegate:Add(self.OnPlayerSwitchWeapon, self);

        -- 已有词条效果先失效
        for _, AffixRecord in pairs(self.AffixRecords) do
            self.AffixManager.UndoAffixEffectList(self.OwnerCharacter, AffixRecord);
        end
    end

    self.AffixRecords = {};
    self.LastWeapon = nil;

    -- 根据装备物品生成词条
    local EquipSlots = self:GetEquipSlots();
    for _, EquipSlot in pairs(EquipSlots) do
        -- 主武器手持时才生效
        local mainWeaponSlots = GameplaySystem.WeaponSystem:GetMainWeaponSlots()
        if self:TableContains(EquipSlot, mainWeaponSlots) and self:IsMainWeaponHandType() then
            ugcprint(string.format("[BP_UGCBackpack:OnPawnRespawn] EquipSlot [%s]", EquipSlot));
        else
            local EquipItem = self:GetEquippedItemBySlotName(EquipSlot);
            ugcprint(string.format("[BP_UGCBackpack:OnPawnRespawn] %s, %s", tostring(EquipSlot), ExportText(totable(EquipItem))));
            self:ApplyEquipAffixEffect(EquipItem);
        end
    end
end

---判断ItemID是不是一个有效实例
---@param ItemDefineID FItemDefineID @物品实例ID
---@return bool @是否有效
function BP_UGCBackpack:IsValidInstance(ItemDefineID)
    return ItemDefineID ~= nil and ItemDefineID.Type ~= 0 and ItemDefineID.TypeSpecificID ~= 0 and ItemDefineID.InstanceID ~= 0;
end

---背包添加物品时回调
---@param ItemDefineID FItemDefineID @物品实例ID
---@param Count number @物品数量
function BP_UGCBackpack:OnAddItemV2(ItemDefineID, Count)
    -- BP_UGCBackpack.SuperClass.OnAddItemV2(self, ItemDefineID, Count);
    ugcprint(string.format("[BP_UGCBackpack:OnAddItemV2] [ItemDefineID:%s,%s] [Count:%d]", type(ItemDefineID), ExportText(totable(ItemDefineID)), Count));

    if self:IsValidInstance(ItemDefineID) == false then
        ugcprint("[BP_UGCBackpack:OnAddItemV2] ItemDefineID is invalid");
        return;
    end

    -- 为装备生成词条信息
    if self.AffixManager == nil then
        self:InitField();
    end

    if self.AffixManager then
        local CustomData = UGCItemSystemV2.LoadItemCustomData(ItemDefineID);
        if CustomData == nil then
            ugcprint("[BP_UGCBackpack:OnAddItemV2] CustomData is nil");
            CustomData = {};
        end

        if CustomData.AffixData == nil then
            -- 根据装备ID生成词条
            local ConfigData = GameData.GetItemMapAffixIDConfig(ItemDefineID.TypeSpecificID);
            if ConfigData == nil or ConfigData.EquipAffixId == nil then
                ugcprint("[BP_UGCBackpack:OnAddItemV2] ConfigData or EquipAffixId is nil");
                return;
            end

            CustomData["AffixData"] = self.AffixManager.AssignRandomAffixesToEquipment(ConfigData.EquipAffixId);

            ugcprint(string.format("[BP_UGCBackpack:OnAddItemV2] [CustomData Save:%s]", ExportText(CustomData)));
            UGCItemSystemV2.SaveItemCustomData(ItemDefineID, CustomData); -- 存到实例数据中
        else
            ugcprint(string.format("[BP_UGCBackpack:OnAddItemV2] AffixData:%s", ExportText(CustomData.AffixData)));
        end
    else
        ugcprint("[BP_UGCBackpack:OnAddItemV2] AffixManager is nil");
    end
end

---生效装备词条
---@param EquipDefineID FItemDefineID @装备物品ID
function BP_UGCBackpack:ApplyEquipAffixEffect(EquipDefineID)
    ugcprint(string.format("[BP_UGCBackpack:ApplyEquipAffixEffect] EquipDefineID:%s", ExportText(EquipDefineID)));

    if self.OwnerCharacter == nil or self.AffixManager == nil then
        ugcprint("[BP_UGCBackpack:ApplyEquipAffixEffect] OwnerCharacter or AffixManager is nil!");
        return;
    end

    if self:IsValidInstance(EquipDefineID) then
        local CustomData = UGCItemSystemV2.LoadItemCustomData(EquipDefineID);

        if CustomData == nil or CustomData.AffixData == nil then
            -- 为装备生成词条信息
            if self.AffixManager then
                if CustomData == nil then
                    CustomData = {};
                end

                -- 根据装备ID生成词条
                local ConfigData = GameData.GetItemMapAffixIDConfig(EquipDefineID.TypeSpecificID);
                if ConfigData == nil or ConfigData.EquipAffixId == nil then
                    ugcprint("[BP_UGCBackpack:ApplyEquipAffixEffect] ConfigData or EquipAffixId is nil");
                    return;
                end

                CustomData["AffixData"] = self.AffixManager.AssignRandomAffixesToEquipment(ConfigData.EquipAffixId);

                ugcprint(string.format("[BP_UGCBackpack:OnAddItemV2] [CustomData Save:%s]", ExportText(CustomData)));
                UGCItemSystemV2.SaveItemCustomData(EquipDefineID, CustomData); -- 存到实例数据中
            else
                ugcprint("[BP_UGCBackpack:OnAddItemV2] AffixManager is nil");
            end
        end

        if CustomData ~= nil and CustomData.AffixData ~= nil then
            ugcprint(string.format("[BP_UGCBackpack:ApplyEquipAffixEffect] [CustomData Load:%s]", ExportText(CustomData)));

            if self.AffixRecords[tostring(EquipDefineID.InstanceID)] ~= nil then
                -- 如果装备词条已生效, 先移除
                self.AffixManager.UndoAffixEffectList(self.OwnerCharacter, self.AffixRecords[tostring(EquipDefineID.InstanceID)]);
            end
            self.AffixRecords[tostring(EquipDefineID.InstanceID)] = self.AffixManager.DoAffixEffectList(self.OwnerCharacter, CustomData.AffixData);
            ugcprint(string.format("[BP_UGCBackpack:ApplyEquipAffixEffect] AffixRecord: [%s:%s]", tostring(EquipDefineID.InstanceID), ExportText(totable(self.AffixRecords[tostring(EquipDefineID.InstanceID)]))));
        else
            ugcprint("[BP_UGCBackpack:ApplyEquipAffixEffect] CustomData or AffixData is nil!");
        end
    else
        ugcprint("[BP_UGCBackpack:ApplyEquipAffixEffect] EquipDefineID is invalid instance!");
    end
end

---装备词条失效
---@param EquipDefineID FItemDefineID @装备物品ID
function BP_UGCBackpack:UnApplyEquipAffixEffect(EquipDefineID)
    ugcprint(string.format("[BP_UGCBackpack:UnApplyEquipAffixEffect] EquipDefineID:%s", ExportText(EquipDefineID)));

    if self.AffixManager == nil or self.OwnerCharacter == nil then
        ugcprint("[BP_UGCBackpack:UnApplyEquipAffixEffect] OwnerCharacter or AffixManager is nil!");
        return;
    end

    -- 移除当前装备的词条效果
    if self:IsValidInstance(EquipDefineID) then
        local AffixRecord = self.AffixRecords[tostring(EquipDefineID.InstanceID)];
        if AffixRecord then
            ugcprint(string.format("[BP_UGCBackpack:UnApplyEquipAffixEffect] [AffixRecord:%s]", ExportText(AffixRecord)));
            self.AffixManager.UndoAffixEffectList(self.OwnerCharacter, AffixRecord);
            self.AffixRecords[tostring(EquipDefineID.InstanceID)] = nil;
        else
            ugcprint("[BP_UGCBackpack:UnApplyEquipAffixEffect] AffixRecord is nil!");
        end
    else
        ugcprint("[BP_UGCBackpack:UnApplyEquipAffixEffect] EquipDefineID is invalid instance!");
    end
end

---检查table中是否有该元素
---@param _Item any @表格元素
---@param _Table any @表格
---@return bool @是否存在
function BP_UGCBackpack:TableContains(_Item, _Table)
    for _, _V in pairs(_Table) do
        if _V == _Item then
            return true;
        end
    end
    return false;
end

function BP_UGCBackpack:IsMainWeaponHandType()
    return self.MainWeaponAffixType == Enum_MainWeaponAffixType.Hand;
end

---当背包装备物品时回调
---@param SlotName string @槽位名称
---@param DefineID FItemDefineID @物品实例ID
function BP_UGCBackpack:OnEquipItem(SlotName, DefineID)
    ugcprint(string.format("[BP_UGCBackpack:OnEquipItem] %s", ExportText(totable(DefineID))));
    local mainWeaponSlots = GameplaySystem.WeaponSystem:GetMainWeaponSlots()
    -- 主武器手持时才生效
    if self:TableContains(SlotName, mainWeaponSlots) and self:IsMainWeaponHandType() then
        ugcprint(string.format("[BP_UGCBackpack:OnEquipItem] Equip MainSlot [%s]", SlotName));
        return;
    end

    self:ApplyEquipAffixEffect(DefineID);
end

---当背包卸下装备时回调
---@param SlotName string @槽位名称
---@param DefineID FItemDefineID @物品实例ID
function BP_UGCBackpack:OnUnequipItem(SlotName, DefineID)
    ugcprint(string.format("[BP_UGCBackpack:OnUnequipItem] %s", ExportText(totable(DefineID))));

    self:UnApplyEquipAffixEffect(DefineID);
end

---当切换武器时回调
---@param SlotName string @槽位名称
function BP_UGCBackpack:OnPlayerSwitchWeapon(SlotName)
    ugcprint(string.format("[BP_UGCBackpack:OnPlayerSwitchWeapon] [SlotName:%s]", SlotName));

    if self.OwnerCharacter == nil then
        ugcprint("[BP_UGCBackpack:OnPlayerSwitchWeapon] OwnerCharacter is nil!");
        return;
    end

    if self:IsMainWeaponHandType() == false then
        ugcprint("[BP_UGCBackpack:OnPlayerSwitchWeapon] MainWeaponEquipAffix");
        return;
    end

    -- 失效主武器效果
    if self.LastWeapon ~= nil then
        ugcprint(string.format("[BP_UGCBackpack:OnPlayerSwitchWeapon] LastWeapon:%s", ExportText(totable(self.LastWeapon))));
        --self:UnApplyEquipAffixEffect(self.LastWeapon);
    end

    local Weapon = UGCWeaponManagerSystem.GetCurrentWeapon(self.OwnerCharacter);
    if Weapon and Weapon.ItemDefineID then
        -- 生效词条
        ugcprint(string.format("[BP_UGCBackpack:OnPlayerSwitchWeapon] Weapon:%s", ExportText(totable(Weapon.ItemDefineID))));
        --self:ApplyEquipAffixEffect(Weapon.ItemDefineID);
        self.LastWeapon = Weapon.ItemDefineID;
    else
        ugcprint("[BP_UGCBackpack:OnPlayerSwitchWeapon] Don't Hold Weapon");
    end
end

---下发默认武器
function BP_UGCBackpack:EnsureDefaultWeapons(bNeedEquip)
    if not UGCGameSystem.IsServer() then
        return false
    end
    if GameData.GetGameModeName(UGCMultiMode.GetModeID) == GameData.ModeName.Lobby then
        return false
    end

    self:InitField()

    local pc = self.OwnerController
    if pc == nil then
        ugcprint("[BP_UGCBackpack:EnsureDefaultWeapon] OwnerController is nil")
        return false
    end
    local playerKey = UGCGameSystem.GetPlayerKeyByPlayerController(self.OwnerController)
    local defaultWeapons = GameplaySystem.WeaponSystem:GetDefaultWeaponIDList(playerKey)
    for k,v in pairs(defaultWeapons) do
        GameplaySystem.WeaponSystem:ServerDeliverAndEquipWeaponToPlayer(playerKey,v,false)
    end
end

return BP_UGCBackpack