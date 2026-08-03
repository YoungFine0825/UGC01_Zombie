UGCGameSystem.UGCRequire("Script.Blueprint.Arts_UI.Lobby.TalentTreeManager")

TalentTreeTestManager = TalentTreeTestManager or {
    UIBP_Test,
}

function TalentTreeTestManager:Init(InComponent)
    ugcprint("[TalentTree] TalentTreeTestManager:Init")
    --UGCDebugSystem.DefaultDuration = 3
    self.TalentTreeComponent = InComponent
    self:UpdateCachedVariables()
    self:LoadTestUI()

    TalentTreeManager.OnMainWidgetOpened:Add(self.OnMainWidgetOpened, self)
    TalentTreeManager.OnMainWidgetClosed:Add(self.OnMainWidgetClosed, self)
end

function TalentTreeTestManager:LoadTestUI()
    local ClassPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Arts_UI/Lobby/UIBP/TalentTree/Test/UIBP_Test.UIBP_Test_C')
    local TestUIClass = UGCObjectUtility.LoadClass(ClassPath)
    if TestUIClass then
        self.UIBP_Test = UserWidget.NewWidgetObjectBP(self.TalentTreeComponent, TestUIClass)
        self.UIBP_Test:AddToViewport(10)
        self.UIBP_Test:SetVisibility(ESlateVisibility.Collapsed)
    else
        ugcprint("TalentTreeTestManager:LoadTestUI() TestUIClass is nil")
    end
end

function TalentTreeTestManager:UpdateCachedVariables()
    if self.TalentTreeComponent then
        self.PlayerController = UGCGameSystem.GetAllPlayerController()[1]
        if self.PlayerController then
            self.PlayerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(self.PlayerController)
            self.PlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(self.PlayerController)
        else
            ugcprint("[TalentTre] TalentTreManagerImpl:UpdateCachedVariables(): PlayerController is nil")
        end
    else
        ugcprint("[TalentTre] TalentTreManagerImpl:UpdateCachedVariables(): TalentTreeActor is nil")
    end
end

function TalentTreeTestManager:SetTalentPoints(TalentPoints)
    ugcprint(string.format("[TalentTree] TalentTreeManagerImpl:SetTalentPoints(): SetTalentPoints for PlayerController = %s, TalentTreeComponent = %s, PlayerKey = %s, TalentPoints = %s", self.PlayerController, self.TalentTreeComponent, self.PlayerKey, TalentPoints))
    UnrealNetwork.CallUnrealRPC(self.PlayerController, self.TalentTreeComponent, "Server_SetTalentPoints", self.PlayerKey, TalentPoints)
end

function TalentTreeTestManager:OnMainWidgetOpened()
    ugcprint("TalentTreeTestManager:UIBP_Test Open")
    self.UIBP_Test:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
end

function TalentTreeTestManager:OnMainWidgetClosed()
    ugcprint("TalentTreeTestManager:UIBP_Test Close")
    self.UIBP_Test:SetVisibility(ESlateVisibility.Collapsed)
end