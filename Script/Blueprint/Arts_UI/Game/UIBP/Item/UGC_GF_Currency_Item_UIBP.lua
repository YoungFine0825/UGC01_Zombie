---@class UGC_GF_Currency_Item_UIBP_C:UUserWidget
---@field Button_Currency UButton
---@field Image_Icon UImage
---@field TextBlock_CurrencyTitle UTextBlock
---@field TextBlock_CurrencyValue UTextBlock
--Edit Below--
local PromiseFuture = require("common.PromiseFuture")
local UGC_GF_Currency_Item_UIBP = { 
    bInitDoOnce = false,
    CoinID = 1005
} 


function UGC_GF_Currency_Item_UIBP:Construct()

    PromiseFuture.New():Set(
        function (PromiseFuture)
            while true do
                local LocalPC = UGCGameSystem.GetLocalPlayerController();
                local BackpackComp = UGCBackpackSystemV2.GetBackpackComponentV2(LocalPC);
                if BackpackComp then
                    BackpackComp.ItemChangeDelegateV2:Add(self.UpdateItem, self)
                    return
                end
                PromiseFuture:Yield()
            end
        end
    ):AutoResume(self, 0.2, 5)

    ugcprint("UGC_GF_Currency_Item_UIBP:Construct")

    PromiseFuture.New():Set(
        function (PromiseFuture)
            while true do
                local ItemData = self:GetBattleItemData(self.CoinID)
                if ItemData then
                    self.TextBlock_CurrencyValue:SetText(tostring(ItemData.Count))
                    self.TextBlock_CurrencyTitle:SetText(tostring(ItemData.ItemName))
                    local SoftObjPath = UGCObjectUtility.MakeSoftObjectPath(ItemData.ItemIcon)
                    if SoftObjPath then
                        self.Image_Icon:SetBrushImageReference(SoftObjPath)
                    end
                    return
                end
                PromiseFuture:Yield()
            end
        end
    ):AutoResume(self, 0.2, 5)
end

function UGC_GF_Currency_Item_UIBP:UpdateItem(ChangeType,ItemDefineID)
    ugcprint("UGC_GF_Currency_Item_UIBP:UpdateItem")
    local ItemData = self:GetBattleItemData(self.CoinID)
    if ItemData and ItemDefineID and ItemDefineID.TypeSpecificID == ItemData.ClassicItemID then
        self.TextBlock_CurrencyValue:SetText(tostring(ItemData.Count))
    end
end

function UGC_GF_Currency_Item_UIBP:GetBattleItemData(BattleItemID)
    ugcprint("UGC_GF_Currency_Item_UIBP:GetBattleItemData")
    local GlobalActor = UGCGamePartSystem.VirtualItemManager.GetGlobalActor()
    if GlobalActor then
        local ItemData = GlobalActor:GetItemData(BattleItemID)
        local pc = UGCGameSystem.GetLocalPlayerController();
        local Count = ItemData.Count or 0;
        if pc then
            Count = GlobalActor:GetItemNum(BattleItemID, pc)
        end
        ItemData.Count = Count
        return ItemData
    end
end

return UGC_GF_Currency_Item_UIBP