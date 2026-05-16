---@class BP_HeroSelectionActor_C:AActor
---@field SkeletalMesh USkeletalMeshComponent
---@field Arrow UArrowComponent
---@field Camera UCameraComponent
---@field AvatarPoseComponent_BP CharmAvatarPoseComponent_BP_C
---@field Floor UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
---@field UGCHeroTable FString
---@field UGCHeroAbilityLabelTable FString
---@field MainWidgetClass FSoftClassPath
---@field bEnableAtStart bool
---@field UGCHeroUITable FString
---@field UGCHeroFreeConfigTable FString
---@field BuyHeroPopupClass FSoftClassPath
---@field CurrencyTipsPopupClass FSoftClassPath
--Edit Below--

UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionManager")


---@type BP_HeroSelectionActor_C
local BP_HeroSelectionActor = {
    SelectedHeroID = {},
    SelectedHeroID_Local = {},
}

function BP_HeroSelectionActor:ReceiveBeginPlay()
    print("[HeroSelection] BP_HeroSelectionActor:ReceiveBeginPlay, self = " .. tostring(self))
    BP_HeroSelectionActor.SuperClass.ReceiveBeginPlay(self)

    if HeroSelectionManager:IsInitialized() then
        return
    end

    HeroSelectionManager:Init(self)
    if self:HasAuthority() then
    else
        if UGCMultiMode.GetModeID() == 1001 then
            HeroSelectionManager:InitWidget()
            HeroSelectionManager.OnHeroFocused:Add(self.HandleOnHeroFocused, self)
        end
    end
end

function BP_HeroSelectionActor:ReceiveEndPlay(EndPlayReason)
    print("[HeroSelection] BP_HeroSelectionActor:ReceiveEndPlay, self = " .. tostring(self))
    if self:HasAuthority() then
    else
        HeroSelectionManager.OnHeroFocused:Remove(self.HandleOnHeroFocused, self)
    end
end

function BP_HeroSelectionActor:HandleOnHeroFocused(HeroID)
    if HeroID then
        local HeroData = HeroSelectionManager:GetUGCHeroData(HeroID)
        if HeroData and HeroData.HeroMeshPath then
            ugcprint("[HeroSelection] BP_HeroSelectionActor:HandleOnHeroFocused: HeroData:")
            log_tree(HeroData)

            Common.LoadObjectWithSoftPathAsync(HeroData.HeroMeshPath, function(Asset)
                self.SkeletalMesh:SetSkeletalMesh(Asset, true)
            end)
        else
            ugcprint("[HeroSelection] BP_HeroSelectionActor:HandleOnHeroFocused: HeroData or SKMeshPath is nil.")
        end
    else
        ugcprint("[HeroSelection] BP_HeroSelectionActor:HandleOnHeroFocused: param HeroID is nil.")
    end
end

function BP_HeroSelectionActor:GetSelectedHeroID(PlayerKey)
    if not self.SelectedHeroID[PlayerKey] then
        print("[HeroSelection] Warning: Trying to get selected hero id for player " .. tostring(PlayerKey) .. ", but it is not set")
        return -1
    end
    return self.SelectedHeroID[PlayerKey]
end

function BP_HeroSelectionActor:SetSelectedHeroID(PlayerKey, HeroID)
    assert(UGCGameSystem.IsServer())
    self.SelectedHeroID[PlayerKey] = HeroID
    UnrealNetwork.RepLazyProperty(self, "SelectedHeroID")
end

function BP_HeroSelectionActor:OnRep_SelectedHeroID()
    for PlayerKey, HeroID in pairs(self.SelectedHeroID) do
        if self.SelectedHeroID_Local[PlayerKey] and self.SelectedHeroID_Local[PlayerKey] == HeroID then
        else
            print("[HeroSelection] Received SelectedHeroID Change: PlayerKey: " .. tostring(PlayerKey) .. ", HeroID: " .. tostring(HeroID))
            self.SelectedHeroID_Local[PlayerKey] = HeroID
            HeroSelectionManager.OnHeroSelected(PlayerKey, HeroID)
        end
    end
end

function BP_HeroSelectionActor:Server_SelectHero(PlayerKey, HeroID)
    HeroSelectionManager:SelectHero(PlayerKey, HeroID)
end

function BP_HeroSelectionActor:GetReplicatedProperties()
    return { "SelectedHeroID", "Lazy" }
end

function BP_HeroSelectionActor:GetAvailableServerRPCs()
    return "Server_SelectHero"
end

return BP_HeroSelectionActor
