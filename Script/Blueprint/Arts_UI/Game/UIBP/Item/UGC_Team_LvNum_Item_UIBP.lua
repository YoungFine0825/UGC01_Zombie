---@class UGC_Team_LvNum_Item_UIBP_C:UUserWidget
---@field Image_gradeCD UImage
---@field TextBlock_grade UTextBlock
--Edit Below--
local UGC_Team_LvNum_Item_UIBP = { 
    bInitDoOnce = false,
    PlayerLevel = 1,
} 
local PromiseFuture = require("common.PromiseFuture")
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')


function UGC_Team_LvNum_Item_UIBP:Construct()
	self:LuaInit();

end

-- [Editor Generated Lua] function define Begin:
function UGC_Team_LvNum_Item_UIBP:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
    self.Slot:SetAutoSize(true)

    -- PromiseFuture.New():Set(
    --     function (PromiseFuture)
    --         while true do
    --             local PS = UGCGameSystem.GetLocalPlayerState()
    --             if PS then
    --                 PS.PlayerLevelChangedDelegate:Add(self.UpdateLevel, self)
    --                 PS.PlayerExpChangedDelegate:Add(self.UpdateExp, self)
    --                 self:UpdateLevel(PS.UGCPlayerLevel)
    --                 self:UpdateExp(PS.PlayerExp)
    --                 return
    --             end
    --             PromiseFuture:Yield()
    --         end
    --     end
    -- ):AutoResume(self, 0.2, 5)
end
-- [Editor Generated Lua] function define End;

function UGC_Team_LvNum_Item_UIBP:UpdateLevel(UGCPlayerLevel)
    ugcprint("UGC_Team_LvNum_Item_UIBP:UpdateLevel UGCPlayerLevel "..tostring(UGCPlayerLevel))
    self.TextBlock_grade:SetText(tostring(UGCPlayerLevel))
    self.PlayerLevel = UGCPlayerLevel
end

function UGC_Team_LvNum_Item_UIBP:UpdateExp(PlayerExp)
    ugcprint("UGC_Team_LvNum_Item_UIBP:UpdateExp PlayerExp "..tostring(PlayerExp))
    local MaxExp = 0
    local cfg = UGCGameData.GetLevelConfig(self.PlayerLevel)
    if cfg then
        MaxExp = cfg.Exp or 0
    end
    if MaxExp == 0 then
        MaxExp = PlayerExp
    end
    ugcprint("UGC_Team_LvNum_Item_UIBP:UpdateExp MaxExp "..tostring(MaxExp))
    local ImageCDMaterial = self.Image_gradeCD:GetDynamicMaterial()
    if ImageCDMaterial then
        local Percent = PlayerExp / MaxExp
        ImageCDMaterial:SetScalarParameterValue("Mask_Percent", Percent)
    end
end

function UGC_Team_LvNum_Item_UIBP:TeammateExpandWidget_UpdatePlayerState(PlayerStateNew, _)
    if not UGCObjectUtility.IsObjectValid(PlayerStateNew) then
        ugcprint("UGC_Team_LvNum_Item_UIBP:TeammateExpandWidget_UpdatePlayerState Invalid")
        return
    end

    ugcprint("UGC_Team_LvNum_Item_UIBP:TeammateExpandWidget_UpdatePlayerState PlayerStateNew=" .. tostring(PlayerStateNew))
    
    if PlayerStateNew then
        PlayerStateNew.PlayerLevelChangedDelegate:Add(self.UpdateLevel, self)
        PlayerStateNew.PlayerExpChangedDelegate:Add(self.UpdateExp, self)
        self:UpdateLevel(PlayerStateNew.UGCPlayerLevel)
        self:UpdateExp(PlayerStateNew.PlayerExp)
    end
    return true
end

return UGC_Team_LvNum_Item_UIBP