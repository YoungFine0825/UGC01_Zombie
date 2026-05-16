local ProjGM = {}
local FreezeExpSwitch = false

function ProjGM:Register(DebugUI)
    local UGCGMUI = require("client.ingame.ugc.ugc_gmui")

    local LocalPawn = UGCGameSystem.GetLocalPlayerPawn()
    local PawnLevel = UGCAttributeSystem.GetGameAttributeValue(LocalPawn, 'Level')

    ugcprint("Function FreezeExpSwitch: "..tostring(FreezeExpSwitch))

    local CurFuncList = {}
    CurFuncList["调试"] = {
        ["SubTab1"] = {
            {UGCGMUI.ItemTypeEnum.TextInput, {{"修改等级", tostring(PawnLevel)}}, "CS_ModifyLevel"},
            {UGCGMUI.ItemTypeEnum.SwitchButton, {{"冻结经验", function() return FreezeExpSwitch and "open" or "close" end}}, "CS_FreezeExp"},
        },
        ["词条"] = {
            {UGCGMUI.ItemTypeEnum.TextInput, {{"指定武器ID生成随机词条", "ID"}, {"生成装备词条功能"}}, "C_AssignRandomAffix"},
        },
        ["关卡流程"] = {
            {UGCGMUI.ItemTypeEnum.Button, {{"关卡结算"}}, "S_LevelSettle"},
            {UGCGMUI.ItemTypeEnum.Button, {{"游戏结算"}}, "S_GameSettle"},
            {UGCGMUI.ItemTypeEnum.Button, {{"关卡加分"}}, "S_LevelAddScore"},
            {UGCGMUI.ItemTypeEnum.Button, {{"关卡跳转"}}, "S_GoToNextLevelForPlayers"}
        },
        ["商城模板"] = {
            {UGCGMUI.ItemTypeEnum.Button, {{"打开商城"}}, "C_OpenShop"},
            {UGCGMUI.ItemTypeEnum.Button, {{"激活限时商城"}}, "S_ActivateRandomShop"},
            {UGCGMUI.ItemTypeEnum.Button, {{"关闭限时商城"}}, "S_DeactivateRandomShop"}
        }
    }
    return CurFuncList
end

function ProjGM:C_TeleportToLocation(param)
    ugcprint("PublicUGCGM:C_TeleportToLocation"..tostring(param))
    local PC = UGCGameSystem.GetLocalPlayerController()
    if PC ~= nil then
        PC:ServerCMD_RPC("TeleportTo " .. tostring(param))
    end
end

function ProjGM:CS_Func()
    ugcprint("Function called CS_Func")
end

function ProjGM:CS_SliderbarFunc(value)
    ugcprint("Function called CS_SliderbarFunc " .. tostring(value))
end

function ProjGM:CS_Switch(str)
    ugcprint("Function called CS_Switch"..str)
end

-- 修改等级
function ProjGM:CS_ModifyLevel(Str, PC)
    if not UGCGameSystem.IsServer() then
        return
    end

    ugcprint("Function called S_ModifyLevel: "..tostring(PC)..", Str:"..Str)
    if PC then
        local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(PC)
        if PlayerState then
            PlayerState:ModifyLevel(tonumber(Str))
        end
    end
end

-- 冻结经验值
function ProjGM:CS_FreezeExp(Str, PC)
    if not UGCGameSystem.IsServer() then
        FreezeExpSwitch = not FreezeExpSwitch
    else
        if PC then
            local PlayerState = UGCGameSystem.GetPlayerStateByPlayerController(PC)
            if PlayerState then
                PlayerState:ToggleFreezeExp()
            end
        end
    end   
end

function ProjGM:C_AssignRandomAffix(EquipID)
    ugcprint("ProjGM:C_AssignRandomAffix")
    local EAM = UGCGameSystem.UGCRequire('Script.Blueprint.Affix.EquipmentAffixManager')
    ugcprint(tostring(EAM))

    local result = EAM.AssignRandomAffixesToEquipment(EquipID)
    ugcprint(StringFormat_Dev("[ProjGM:C_AssignRandomAffix] [result:%s]", ExportText_Dev(result)));

    local AffixShow = EAM.GetAffixShowInfos(result);

    local ShowStringList = {}
    for _, ShowInfo in pairs(AffixShow) do
        local Modifier = ShowInfo.Modifier;
        local Description = ShowInfo.Description;
        local AffixesLevel = ShowInfo.AffixesLevel;
        
        local AString = nil;
        if Modifier then
            AString = Modifier .. "   " .. Description;
        else
            AString = Description;
        end

        table.insert(ShowStringList, {Description = AString, AffixesLevel = AffixesLevel});
    end

    local PC = UGCGameSystem.GetLocalPlayerController()
    ugcprint(StringFormat_Dev("[ProjGM:C_AssignRandomAffix] [ShowStringList:%s]", ExportText_Dev(ShowStringList)));
  
end

function ProjGM:S_LevelSettle()
    ugcprint("ProjGM:S_LevelSettle")
    local allpc = UGCGameSystem.GetAllPlayerController(false)
    UGCLevelFlowSystem.LevelSettle(allpc[1].TeamID, true)
end

function ProjGM:S_GameSettle()
    ugcprint("ProjGM:S_GameSettle")
    UGCLevelFlowSystem.GameSettle(true)
end

function ProjGM:S_LevelAddScore()
    local allpc = UGCGameSystem.GetAllPlayerController(false)
    UGCLevelFlowSystem.LevelAddScore(allpc[1].TeamID, 1000)
end

function ProjGM:S_GoToNextLevelForPlayers()
    UGCLevelFlowSystem.GoToNextLevelForAllPlayers()
end

function ProjGM:C_OpenShop()
    if ShopV2Manager ~= nil then
        ShopV2Manager:OpenMainUI();
    end
end

function ProjGM:S_ActivateRandomShop()
    if ShopV2Manager ~= nil then
        local PC = UGCGameSystem.GetPlayerControllerByPlayerPawn(self.DsRelativePawn)
        ShopV2Manager:ActivateRandomRefreshTab(PC);
    end
end

function ProjGM:S_DeactivateRandomShop()
    if ShopV2Manager ~= nil then
        local PC = UGCGameSystem.GetPlayerControllerByPlayerPawn(self.DsRelativePawn)
        ShopV2Manager:DeactivateRandomRefreshTab(PC);
    end
end

return ProjGM