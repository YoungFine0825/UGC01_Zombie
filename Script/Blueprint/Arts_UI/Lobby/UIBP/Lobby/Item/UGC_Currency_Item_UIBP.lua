---@class UGC_Currency_Item_UIBP_C:UUserWidget
---@field Image_Currency_Icon UImage
---@field Image_Currency_Status1 UImage
---@field NewButton_Currency_Increase UButton
---@field NewButton_Currency_Tips UButton
---@field TextBlock_Currency_Amount UTextBlock
---@field CoinItemID int32
---@field CoinIcon UTexture2D
--Edit Below--

---@type BP_VirtualItemManager_GlobalActor
local VirtualItemManager = nil


---@type UGC_Currency_Item_UIBP_C
local UGC_Currency_Item_UIBP = {}


function UGC_Currency_Item_UIBP:Construct()
    if UGCGameSystem.IsServer() then
    else
        UGCGenericMessageSystem.ListenGlobalMessage(self, "UGC.GamePart.GamePartLoaded", self, self.OnGamePartLoaded)
    end

    self.NewButton_Currency_Increase.OnClicked:Add(self.OnIncreaseClicked, self)
end

function UGC_Currency_Item_UIBP:Destruct()
    if self:IsOasisCoin() then
        UGCCommoditySystem.UGCCommodityPlayerDataChangedDelegate:Remove(self.OnPlayerDataChanged, self)
    else
        if VirtualItemManager then
            VirtualItemManager.OnVirtualItemNumUpdatedDelegate:Remove(self.OnVirtualItemNumUpdated, self)
        end
    end

    self.NewButton_Currency_Increase.OnClicked:Remove(self.OnIncreaseClicked, self)
end

function UGC_Currency_Item_UIBP:OnUpdate(Data)
    self.TextBlock_Currency_Amount:SetText(tostring(Data))
    self.Image_Currency_Icon:SetBrushFromTexture(self.CoinIcon, false)
end

function UGC_Currency_Item_UIBP:OnGamePartLoaded()
    VirtualItemManager = UGCBlueprintFunctionLibrary.GetGamePartGlobalActor(UGCGameSystem.GameState, "VirtualItemManager")

    if self:IsOasisCoin() then
        UGCCommoditySystem.UGCCommodityPlayerDataChangedDelegate:Add(self.OnPlayerDataChanged, self)
        self:OnPlayerDataChanged()
    else
        if VirtualItemManager then
            VirtualItemManager.OnVirtualItemNumUpdatedDelegate:Add(self.OnVirtualItemNumUpdated, self)
            UGCTimerUtility.CreateLuaTimer(0.4,  function() self:OnVirtualItemNumUpdated() end, true, "OnVirtualItemNumUpdated", 0)
        end
    end
end

function UGC_Currency_Item_UIBP:OnPlayerDataChanged()
    self:OnUpdate(UGCCommoditySystem.GetTicket())
end

function UGC_Currency_Item_UIBP:OnVirtualItemNumUpdated()
    if VirtualItemManager then
        self:OnUpdate(VirtualItemManager:GetItemNum(self.CoinItemID, self:GetOwningPlayer()))
    end
end

function UGC_Currency_Item_UIBP:IsOasisCoin()
    return self.CoinItemID == -1
end

function UGC_Currency_Item_UIBP:OnIncreaseClicked()
    if ShopV2Manager then
        ShopV2Manager:OpenMainUI()
    else
        ugcprint("[HeroSelection] ShopV2Manager is nil, can't open shop panel. Please check if shop template is currently set up.")
    end
end

return UGC_Currency_Item_UIBP