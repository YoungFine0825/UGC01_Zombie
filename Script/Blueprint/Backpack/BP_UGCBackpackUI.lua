---@class BP_UGCBackpackUI_C:BP_BackpackUIComponentV2_C
--Edit Below--
local GameData = UGCGameSystem.UGCRequire("Script.Blueprint.UGCGameData");

local BP_UGCBackpackUI = {}

--[[
function BP_UGCBackpackUI:ReceiveBeginPlay()
    BP_UGCBackpackUI.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function BP_UGCBackpackUI:ReceiveTick(DeltaTime)
    BP_UGCBackpackUI.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_UGCBackpackUI:ReceiveEndPlay()
    BP_UGCBackpackUI.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_UGCBackpackUI:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_UGCBackpackUI:GetAvailableServerRPCs()
    return
end
--]]

function BP_UGCBackpackUI:IsDiscardAreaVisible()
    if GameData.GetGameModeName(UGCMultiMode.GetModeID()) == GameData.ModeName.Lobby then
        return false;
    else
        return true;
    end
end

function BP_UGCBackpackUI:OpenBattleMainUIStyle(Style, Mode)
    if GameData.GetGameModeName(UGCMultiMode.GetModeID()) == GameData.ModeName.Lobby then
        -- 打开大厅仓库
        self:OpenLobbyBackpackMainUI(3);
    else
        -- 打开局内背包
        self:OpenBattleMainPanel(Style, Mode);
    end
end

function BP_UGCBackpackUI:ClosePanel()
    if GameData.GetGameModeName(UGCMultiMode.GetModeID()) == GameData.ModeName.Lobby then
        -- 关闭大厅仓库
        self:CloseLobbyPanel();
    else
        -- 关闭局内背包
        self:CloseBattleMainPanel()
    end
end

-- UI兼容大厅逻辑
function BP_UGCBackpackUI:OnOpenDeletePanel(Panel)
    print("BP_UGCBackpackUI:OpenDeletePanel")
    Panel:RemoveFromParent()
    Panel:AddToViewport(10000)
end

function BP_UGCBackpackUI:OnClickLockBackpackItem(Panel)
    print("BP_UGCBackpackUI:OnClickLockBackpackItem")
    Panel:RemoveFromParent()
    Panel:AddToViewport(10000)
end
function BP_UGCBackpackUI:OnOpenSaveOrWithDrawPanel(Panel)
    print("BP_UGCBackpackUI:OpenSaveOrWithDrawPanel")
    Panel:RemoveFromParent()
    Panel:AddToViewport(10000)
end

function BP_UGCBackpackUI:ShowWeaponExtraTipsPanel()

    if ShopV2Manager:IsMainUIOpenned() == true then
        return false;
    end

    return true
end

return BP_UGCBackpackUI