local EquipmentAffixManager = {}

local GameData = UGCGameSystem.UGCRequire("Script.Blueprint.UGCGameData");

---输出词条对应属性信息，方便调试
---@param PlayerCharacter PlayerPawn @玩家角色
---@param Affix table @词条信息结构体{AffixId, TargetAttrType, RandomModifier/SkillId}
function EquipmentAffixManager.DebugShowAttrValue(PlayerCharacter, Affix)
    -- 修改属性
    local AttrContainer = Affix.TargetAttrType;
    local CurAttr = UGCAttributeSystem.GetGameAttributeValue(PlayerCharacter, AttrContainer.AttributeName);
    ugcprint(string.format("[EquipmentAffixManager.DebugShowAttrValue] [CurAttr:%.4f]", CurAttr));
end

---为角色生效单个词条
---@param PlayerCharacter PlayerPawn @玩家角色
---@param Affix table @词条信息结构体{AffixId, TargetAttrType, RandomModifier/SkillId}
function EquipmentAffixManager.DoAffixEffect(PlayerCharacter, Affix)
    -- DS才起作用
    if Affix == nil or PlayerCharacter == nil or not UGCActorComponentUtility.HasAuthority(PlayerCharacter) then
        ugcprint("[EquipmentAffixManager.DoAffixEffect] Affix or PlayerCharacter is nil");
        return;
    end

    -- 根据AffixId查询词条信息
    local AffixInfo = GameData.GetAffixDetailsConfig(Affix.AffixId);
    if AffixInfo == nil then
        ugcprint("[EquipmentAffixManager.DoAffixEffect] AffixInfo don't exist!");
        return;
    end
    Affix.TargetAttrType = AffixInfo.TargetAttrType;


    local Record = {}
    if Affix.RandomModifier then
        -- [[ 非被动技能，修改玩家属性 ]]
        local AttrContainer = Affix.TargetAttrType;
        if AttrContainer == nil then
            ugcprint("[EquipmentAffixManager.DoAffixEffect] AttrContainer is nil");
            return;
        end

        -- 修改属性
        local CurAttr = UGCAttributeSystem.GetGameAttributeValue(PlayerCharacter, AttrContainer.AttributeName);

        local ModifyId = UGCAttributeSystem.AddGameAttributeOperation(PlayerCharacter, AttrContainer.AttributeName, EAttrOperator.Plus, Affix.RandomModifier);
        -- 调试用，打印修改后的属性值
        local ModifiedAttr = UGCAttributeSystem.GetGameAttributeValue(PlayerCharacter, AttrContainer.AttributeName);
        -- ugcprint(string.format("[EquipmentAffixManager.DoAffixEffect] [ModifyId:%s, %s] [BeforeAttr:%.4f] [AfterAttr:%.4f]", tostring(ModifyId), AttrContainer.AttributeName, CurAttr, ModifiedAttr));

        return ModifyId;
    elseif Affix.SkillId then
        -- 被动技能，直接给角色挂技能蓝图
        local PersistClient = PlayerCharacter:GetPlayerPersistClientState();
        if PersistClient == nil then
            ugcprint("[EquipmentAffixManager.DoAffixEffect] PersistClient is nil");
            return;
        end

        -- 根据SkillId读取技能信息 {id, Description, Blueprint}
        local SkillInfo = GameData.GetSkillDetailsConfig(Affix.SkillId);
        if SkillInfo == nil then
            ugcprint("[EquipmentAffixManager.DoAffixEffect] SkillInfo is nil");
            return;
        end

        local SkillClass = SkillInfo.Blueprint;
        if SkillClass == nil then
            ugcprint("[EquipmentAffixManager.DoAffixEffect] SkillClass is invalid");
            return;
        end

        -- 给玩家应用技能
        local SkillInstance = PersistClient:ApplyPersistEffectDataByClass(SkillClass, -1.0);
        if SkillInstance == nil then
            ugcprint("[EquipmentAffixManager.DoAffixEffect] SkillInstance is invalid");
            return;
        end
        return SkillInstance;
    end
end

---为角色生效词条列表(服务端执行)
---@param PlayerCharacter PlayerPawn @玩家角色
---@param AffixList table @词条结构列表{{AffixId, RandomModifier/SkillId}, ..}
function EquipmentAffixManager.DoAffixEffectList(PlayerCharacter, AffixList)
    if AffixList == nil or PlayerCharacter == nil or not UGCActorComponentUtility.HasAuthority(PlayerCharacter) then
        ugcprint("[EquipmentAffixManager.DoAffixEffectList] AffixList or PlayerCharacter is nil");
        return;
    end


    -- [[ 根据词条Id查询词条信息 ]]
    local AffixTable = {}
    for _, AffixInfo in pairs(AffixList) do
        local DataRow = GameData.GetAffixDetailsConfig(AffixInfo.AffixId);
        if DataRow then
            local AffixRow = {}
            AffixRow.TargetAttrType = DataRow.TargetAttrType;

            AffixRow.SkillId = AffixInfo.SkillId;
            AffixRow.RandomModifier = AffixInfo.RandomModifier;
            AffixRow.AffixId = AffixInfo.AffixId

            table.insert(AffixTable, AffixRow); 
        else
            ugcprint(string.format("[EquipmentAffixManager.DoAffixEffectList] DataRow not found"));
        end
    end

    local ModifyRecords = {}
    for _, Affix in pairs(AffixTable) do
        local ModifyId = EquipmentAffixManager.DoAffixEffect(PlayerCharacter, Affix);

        if ModifyId then
            table.insert(ModifyRecords, ModifyId);
        end
    end

    return ModifyRecords;
end

---为角色失效词条
---@param PlayerCharacter PlayerPawn @玩家角色
---@param ModifyRecord table @记录的已生效词条信息 ModifyId/SkillInstance
function EquipmentAffixManager.UndoAffixEffect(PlayerCharacter, ModifyRecord)
    -- DS才起作用
    if ModifyRecord == nil or PlayerCharacter == nil or not UGCActorComponentUtility.HasAuthority(PlayerCharacter) then
        ugcprint("[EquipmentAffixManager.DoAffixEffectList] ModifyRecord or PlayerCharacter is nil");
        return;
    end


    if type(ModifyRecord) == "userdata" then
        local PersistClient = PlayerCharacter:GetPlayerPersistClientState();
        if PersistClient == nil then
            ugcprint("[EquipmentAffixManager.UndoAffixEffect] PersistClient is nil");
            return;
        end

        PersistClient:UnApplyPersistEffectData(ModifyRecord, EPersistEffectUnApplyReason.Normal);
    elseif type(ModifyRecord) == "string" then
        if string.len(ModifyRecord) == 0 then
            ugcprint("[EquipmentAffixManager.UndoAffixEffect] ModifyRecord is nil");
            return;
        end

        -- 移除属性修改
        UGCAttributeSystem.RemoveGameAttributeOperation(PlayerCharacter, ModifyRecord);
    end
end

---为角色失效词条列表
---@param PlayerCharacter PlayerPawn @玩家角色
---@param ModifyRecords table @失效词条的记录列表 {ModifyId/SkillInstance, ..}
function EquipmentAffixManager.UndoAffixEffectList(PlayerCharacter, ModifyRecords)
    if ModifyRecords == nil or PlayerCharacter == nil or not UGCActorComponentUtility.HasAuthority(PlayerCharacter) then
        ugcprint("[EquipmentAffixManager.DoAffixEffectList] ModifyRecords or PlayerCharacter is nil");
        return;
    end

    for _, ModifyRecord in pairs(ModifyRecords) do
        EquipmentAffixManager.UndoAffixEffect(PlayerCharacter, ModifyRecord);
    end
end

---根据实例物品ID返回UI显示信息
---@param DefineID FItemDefineID @实例物品ID
---@return AffixShow table @返回词条的UI信息 {{String1, Stirng2, AffixesLevel}, {String, AffixesLevel}, ..}
function EquipmentAffixManager.GetAffixShowInfosByDefineID(DefineID)

    local CustomData = UGCItemSystemV2.LoadItemCustomData(DefineID);
    -- 词条起作用
    if CustomData == nil or CustomData.AffixData == nil then
        ugcprint("[EquipmentAffixManager.GetAffixShowInfos] CustomData or AffixData is nil!");
        return;
    end

    local AffixList = CustomData.AffixData;

    return EquipmentAffixManager.GetAffixShowInfos(AffixList);
end

---根据词条Id列表返回UI显示信息
---@param AffixList table @读取物品的词条列表 {{AffixId, RandomModifier/SkillId}, ..}
---@return AffixShow table @返回词条的UI信息 {{String1, Stirng2, AffixesLevel}, {String, AffixesLevel}, ..}
function EquipmentAffixManager.GetAffixShowInfos(AffixList)

    -- [[ 查询字条展示信息 ]]
    local AffixTable = {}
    for _, Affix in pairs(AffixList) do
        local DataRow = GameData.GetAffixDetailsConfig(Affix.AffixId);

        local TableRow = {}
        TableRow.AffixId = Affix.AffixId;
        TableRow.RandomModifier = Affix.RandomModifier;
        TableRow.SkillId = Affix.SkillId;

        TableRow.AffixesLevel = DataRow.AffixesLevel;
        TableRow.DecimalPlaces = DataRow.DecimalPlaces;
        TableRow.DisplayPercentage = DataRow.DisplayPercentage;

        if DataRow.IsPassiveSkill and Affix.SkillId then
            -- ugcprint("[EquipmentAffixManager.GetAffixShowInfos] DataRow IsPassiveSkill:true");
            -- 从技能表读取描述
            local SkillDetail = GameData.GetSkillDetailsConfig(Affix.SkillId);
            if SkillDetail then
                TableRow.Description = SkillDetail.Description;
            else
                ugcprint("[EquipmentAffixManager.GetAffixShowInfos] SkillDetail don't found");
            end
        else
            ugcprint("[EquipmentAffixManager.GetAffixShowInfos] DataRow IsPassiveSkill:false or SkillId is nil");
            TableRow.Description = DataRow.Description;
        end

        table.insert(AffixTable, TableRow);
    end

    -- [[ 转换得到每个词条的String信息 ]]
    local AffixShow = {}
    for _, Data in pairs(AffixTable) do
        local ShowInfo = {};

        local AffixString = nil;
        if Data.SkillId then
            ShowInfo = {Description = Data.Description};
        elseif Data.RandomModifier then
            -- 是否百分比显示
            if Data.DisplayPercentage then
                local MinPlaces = math.max(Data.DecimalPlaces - 2, 0); -- 百分比显示最少保留两位小数
                local Modifier = Data.RandomModifier * 100;

                -- 是否保留整数
                if MinPlaces <= 0 then
                    AffixString = string.format("%d", math.floor(Modifier));
                else
                    AffixString = string.format("%." .. MinPlaces .. "f", Modifier);
                end
                AffixString = AffixString .. "%";
            else
                local MinPlaces = Data.DecimalPlaces;
                local Modifier = Data.RandomModifier;

                -- 是否保留整数
                if MinPlaces <= 0 then
                    AffixString = string.format("%d", math.floor(Modifier));
                else
                    AffixString = string.format("%." .. MinPlaces .. "f", Modifier);
                end
            end

            if Data.RandomModifier > 0 then
                AffixString = "+" .. AffixString;
            end

            ShowInfo = {Modifier = AffixString, Description = Data.Description};
        end

        ShowInfo.AffixesLevel = Data.AffixesLevel;
        table.insert(AffixShow, ShowInfo);
    end

    return AffixShow;
end

---为装备生成随机词条
---@param EquippmentId number @物品ID
---@return FinalResult table @{AffixId, RandomModifier/SkillId}, 对应UGCAffixDetails表中的字段
function EquipmentAffixManager.AssignRandomAffixesToEquipment(EquippmentId)
    if EquippmentId == nil then
        ugcprint("[EquipmentAffixManager.AssignRandomAffixesToEquipment] EquippmentId is nil!");
        return;
    end

    -- ugcprint(string.format("[EquipmentAffixManager.AssignRandomAffixesToEquipment] Enter111 EuippmentId:%d", EquippmentId));

    -- [[ 读取装备词缀配置 ]]
    local EquippmentTableRow = GameData.GetEquippmentAffixConfig(EquippmentId);
    if EquippmentTableRow == nil then
        ugcprint("[EquipmentAffixManager.AssignRandomAffixesToEquipment] EuippmentTableRow is nil!");
        return;
    end

    local EquippmentData = {};
    EquippmentData.IsRepeat = EquippmentTableRow["IsRepeat"];
    EquippmentData.QuantityOfAffixes = EquippmentTableRow["QuantityOfAffixes"];
    EquippmentData.RandomAffixes = EquippmentTableRow["RandomAffixes"];

    if EquippmentData == nil then
        ugcprint("[EquipmentAffixManager.AssignRandomAffixesToEquipment] EquippmentData is nil!");
    end

    -- [[ 读取词条属性 ]]
    local AffixTable = GameData.GetAffixDetailsAllConfig();

    -- [[ 取随机词条 ]]
    local FetchAffixes = {} -- 取出的词条id
    local ExistMutexExclusion = {} -- 存在的互斥类型
    for _, RandomAffix in ipairs(EquippmentData.RandomAffixes) do

        -- [[ 随机整数 ]]
        local NumberRange = {RandomAffix.NumberRange.Min, RandomAffix.NumberRange.Max};

        local AffixNumber = math.random(NumberRange[1], NumberRange[2]);
        -- ugcprint(string.format("[EquipmentAffixManager.AssignRandomAffixesToEquipment] AffixNumber:%d", AffixNumber));

        -- [[ 随机词条 ]]
        local AffixIds = {}
        for _, RA in ipairs(RandomAffix.AffixIds) do
            table.insert(AffixIds, RA);
        end

        -- 随机AffixNumber个词条
        EquipmentAffixManager.FetchRandomAffix(AffixIds, AffixNumber, FetchAffixes, ExistMutexExclusion, EquippmentData, AffixTable);
    end

    -- 断言词条数不大于配置上限
    assert(#FetchAffixes <= EquippmentData.QuantityOfAffixes);

    -- [[ 随机属性 ]]
    local FinalResult = {} -- 最终返回词条列表
    for _, Id in pairs(FetchAffixes) do
        local TempResult = {} -- 当前随机词条

        local CurAffix = AffixTable[tostring(Id)];
        -- ugcprint(string.format("[EquipmentAffixManager.AssignRandomAffixesToEquipment] [Id:%d]", Id));
        if CurAffix == nil then
            -- ugcprint("[EquipmentAffixManager.AssignRandomAffixesToEquipment] CurAffix is nil");
        else
            -- 区分被动技能
            if CurAffix["IsPassiveSkill"] then
                local PassiveSkillIds = {}
                for _, SkillId in pairs(CurAffix["SkillId"]) do
                    if SkillId then
                        table.insert(PassiveSkillIds, SkillId);
                    end
                end

                if #PassiveSkillIds >= 1 then
                    local RandomInt = math.random(1, #PassiveSkillIds);

                    TempResult.SkillId = PassiveSkillIds[RandomInt]; -- 返回技能id
                end
            else
                local AttrRange = {CurAffix.RandomModifier.Min, CurAffix.RandomModifier.Max};

                if AttrRange[2] < AttrRange[1] then
                    ugcprint("[EquipmentAffixManager.RandomFloatExclusionAndBeside] AttrRange.Max < AttrRange.Min !!!");
                    break;
                end

                local RandomFloat = EquipmentAffixManager.RandomFloatExclusionAndBeside(AttrRange, CurAffix.DecimalPlaces);

                TempResult.RandomModifier = RandomFloat; -- 返回随机属性值
            end

            TempResult.AffixId = Id;
            table.insert(FinalResult, TempResult);
        end
    end

    return FinalResult;
end

---生成随机浮点数 左开右闭
---@param AttrRange table @随机数范围{Min, Max}
---@param DecimalPlaces number @保留小数位数
function EquipmentAffixManager.RandomFloatExclusionAndBeside(AttrRange, DecimalPlaces)
    local upper = math.floor((AttrRange[2] - AttrRange[1]) * 10 ^ DecimalPlaces + 0.5);
    -- MinValue保留小数位数
    local MinValue = math.floor(AttrRange[1] * 10 ^ DecimalPlaces);
    return (MinValue + math.random(1, upper)) * 10 ^ (-1 * DecimalPlaces);
end

---从词条候选中选择若干词条
---@param AffixIds table @当前装备可生成
---@param AffixNumber number @要选择的词条数量
---@param FetchAffixes table @已选择的词条ID
---@param ExistMutexExclusion table @已选择词条的互斥类型，用于排除词条互斥
---@param EquippmentData table @装备数据 {IsRepeat, QuantityOfAffixes, RandomAffixes}
---@param AffixTable any @UGCAffixDetails读表的数据
function EquipmentAffixManager.FetchRandomAffix(AffixIds, AffixNumber, FetchAffixes, ExistMutexExclusion, EquippmentData, AffixTable)
    -- 当前品质选完了，或者，已经到达词条上限
    if AffixIds == nil or #AffixIds < 1 or AffixNumber < 1 or #FetchAffixes >= EquippmentData.QuantityOfAffixes then
        return;
    end

    if EquippmentData.IsRepeat then
        -- 可重复，随意选
        if #AffixIds < 1 then
            return;
        end

        local RandomInt = math.random(1, #AffixIds);
        table.insert(FetchAffixes, AffixIds[RandomInt]);

        -- 继续选
        EquipmentAffixManager.FetchRandomAffix(AffixIds, AffixNumber - 1, FetchAffixes, ExistMutexExclusion, EquippmentData, AffixTable);
    else
        -- 不可重复，需要排除互斥的
        local AffixesLeave = {}
        for _, Id in pairs(AffixIds) do
            local AffixRow = AffixTable[tostring(Id)]
            if AffixRow == nil then
                -- ugcprint("[EquipmentAffixManager.FetchRandomAffix] AffixRow is nil!");
            else
                if ExistMutexExclusion[AffixRow.MutexExclusion] then
                    -- ugcprint("[EquipmentAffixManager.FetchRandomAffix] TableFindMutexItem true");
                else
                    table.insert(AffixesLeave, Id);
                    -- ugcprint("[EquipmentAffixManager.FetchRandomAffix] TableFindMutexItem false");
                end
            end
        end

        if #AffixesLeave < 1 then
            return;
        end

        -- 随机选一个出来
        local RandomInt = math.random(1, #AffixesLeave);
        table.insert(FetchAffixes, AffixesLeave[RandomInt]);

        local AffixRow = AffixTable[tostring(AffixesLeave[RandomInt])];
        ExistMutexExclusion[AffixRow.MutexExclusion] = true;

        -- 接着选剩下的
        EquipmentAffixManager.FetchRandomAffix(AffixesLeave, AffixNumber - 1, FetchAffixes, ExistMutexExclusion, EquippmentData, AffixTable);
    end
end

return EquipmentAffixManager