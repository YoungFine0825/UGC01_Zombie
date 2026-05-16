---@class ShopV2_ShopEntranceBut_UIBP_C:UUserWidget
---@field EntryButton UButton
--Edit Below--
local ShopV2_ShopEntranceBut_UIBP = 
{ 
    bInitDoOnce = false;

    RandomTabID = -1;
} 

function ShopV2_ShopEntranceBut_UIBP:Construct()
	
    self.EntryButton.OnClicked:Add(self.OnEntryButtonClick, self);
end

function ShopV2_ShopEntranceBut_UIBP:Destruct()
    self.EntryButton.OnClicked:Remove(self.OnEntryButtonClick, self);

    if self.CheckTimer ~= nil then
        UGCTimerUtility.RemoveLuaTimer(self.CheckTimer)
        self.CheckTimer = nil
    end
end

function ShopV2_ShopEntranceBut_UIBP:OnEntryButtonClick()
    
    ShopV2Manager:OpenMainUI(self.RandomTabID);
end

function ShopV2_ShopEntranceBut_UIBP:CheckTime()
    
    if ShopV2Manager:GetCountDownTime() <= 0 then
        self:SetVisibility(ESlateVisibility.Collapsed);
        UGCTimerUtility.RemoveLuaTimer(self.CheckTimer);
        self.CheckTimer = nil;
        return;
    end

    if self.CheckTimer == nil then
        self.CheckTimer = UGCTimerUtility.CreateLuaTimer(
            1,
            function ()
                if self ~= nil then
                    self:CheckTime();
                end
            end,
            true
        )
    end
end

return ShopV2_ShopEntranceBut_UIBP
