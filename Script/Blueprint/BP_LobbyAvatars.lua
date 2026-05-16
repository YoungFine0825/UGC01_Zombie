---@class BP_LobbyAvatars_C:AActor
---@field P4 USkeletalMeshComponent
---@field P3 USkeletalMeshComponent
---@field P2 USkeletalMeshComponent
---@field P1 USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local PromiseFuture = require("common.PromiseFuture")

local BP_LobbyAvatars = 
{
    TeammateAvatars = nil,
    bInited = false
}
 
function BP_LobbyAvatars:ReceiveBeginPlay()
    BP_LobbyAvatars.SuperClass.ReceiveBeginPlay(self)

    ugcprint("BP_LobbyAvatars:ReceiveBeginPlay")

     -- 英雄选择结果回调
    if not HeroSelectionManager then
        UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionManager")
    end

    if not UGCActorComponentUtility.HasAuthority(self) then
        self.TeammateAvatars = {}
        self.P1:SetVisibility(false)
        table.insert(self.TeammateAvatars, self.P2)
        self.P2:SetVisibility(false)
        table.insert(self.TeammateAvatars, self.P3)
        self.P3:SetVisibility(false)
        table.insert(self.TeammateAvatars, self.P4)
        self.P4:SetVisibility(false)

        ugcprint("BP_LobbyAvatars:ReceiveBeginPlay All avatar set to invisible")

        --确保当玩家进入游戏时同步更新大厅
        local PC = UGCGameSystem.GetLocalPlayerController()
        if PC then
            self:ClientHandleHeroSelectionDependency()
            PC.OnLobbyTeammatePlayerKeysUpdate:Add(self.RequestUpdateLobbyAvatars, self)
        else
            PromiseFuture.New():Set(
                function (PromiseFuture)
                    while not UGCObjectUtility.IsObjectValid(UGCGameSystem.GetLocalPlayerController()) do
                        PromiseFuture:Yield()
                    end

                    self:ClientHandleHeroSelectionDependency()
                    PC.OnLobbyTeammatePlayerKeysUpdate:Add(self.RequestUpdateLobbyAvatars, self)
                end
            ):AutoResume(self, 0.5, 10)
        end
    end
end

function BP_LobbyAvatars:ClientHandleHeroSelectionDependency()
    if HeroSelectionManager:IsInitialized() then
        ---Actor可能还没进入PersistentLevel会导致DS的ClientRPC失败，所以可能需要重复发几次Request
        PromiseFuture.New():Set(
            function (PromiseFuture)
                while not self.bInited do
                    self:RequestUpdateLobbyAvatars()
                    PromiseFuture:Yield()
                end
            end
        ):AutoResume(self, 0.5, 5)

        
        HeroSelectionManager.OnHeroSelected:Add(self.OnPlayerSelectHero, self)
    else
        HeroSelectionManager.OnInitialized:Add(function ()
            ---Actor可能还没进入PersistentLevel会导致DS的ClientRPC失败，所以可能需要重复发几次Request
            PromiseFuture.New():Set(
                function (PromiseFuture)
                    while not self.bInited do
                        self:RequestUpdateLobbyAvatars()
                        PromiseFuture:Yield()
                    end
                end
            ):AutoResume(self, 0.5, 5)

            
            HeroSelectionManager.OnHeroSelected:Add(self.OnPlayerSelectHero, self)
        end)
    end
end

function BP_LobbyAvatars:RequestUpdateLobbyAvatars()
    ugcprint("BP_LobbyAvatars:RequestUpdateLobbyAvatars")
    UnrealNetwork.CallUnrealRPC(UGCGameSystem.GetLocalPlayerController(), self, "Server_SetupTeammateAvatar", UGCGameSystem.GetLocalPlayerKey())
end

function BP_LobbyAvatars:Server_SetupTeammateAvatar(PlayerKey)
    ugcprint("BP_LobbyAvatars:Server_SetupTeammateAvatar PlayerKey="..tostring(PlayerKey))
    local PC = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
    local TeammatePlayerKeys = PC.LobbyTeammatePlayerKeys

    local PlayerKeyAndHeroIDs = {}
    for _, PlayerKey in ipairs(TeammatePlayerKeys) do
        PlayerKeyAndHeroIDs[PlayerKey] = HeroSelectionManager:GetSelectedHeroID(PlayerKey)
    end

    UnrealNetwork.CallUnrealRPC(UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey), self, "Client_UpdateLobbyAvatars", PlayerKeyAndHeroIDs)
end

function BP_LobbyAvatars:ReceiveEndPlay()
    if not UGCActorComponentUtility.HasAuthority(self) then
        local PC = UGCGameSystem.GetLocalPlayerController()
        if PC ~= nil then
            PC.OnLobbyTeammatePlayerKeysUpdate:Remove(self.RequestUpdateLobbyAvatars, self)
        end

        HeroSelectionManager.OnHeroSelected:Remove(self.OnPlayerSelectHero, self)
    end
end

function BP_LobbyAvatars:Client_UpdateLobbyAvatars(PlayerKeyAndHeroIDs)
    for PlayerKey, HeroID in pairs(PlayerKeyAndHeroIDs) do
        local MeshPath = UGCObjectUtility.GetPathBySoftObjectPath(HeroSelectionManager:GetUGCHeroData(HeroID).HeroMeshPath)
        UGCObjectUtility.AsyncLoadObject(MeshPath, 
            function (Mesh)
                if self ~= nil then
                    self:ApplyAvatarMesh(PlayerKey, Mesh)           
                end
            end
        )
    end

    self.bInited = true
end

function BP_LobbyAvatars:OnPlayerSelectHero(PlayerKey, HeroID)
    local MeshPath = UGCObjectUtility.GetPathBySoftObjectPath(HeroSelectionManager:GetUGCHeroData(HeroID).HeroMeshPath)
    UGCObjectUtility.AsyncLoadObject(MeshPath, 
        function (Mesh)
            if Mesh ~= nil and self ~= nil then
                self:ApplyAvatarMesh(PlayerKey, Mesh)           
            end
        end
    )
end

function BP_LobbyAvatars:ApplyAvatarMesh(PlayerKey, Mesh)
    if UGCActorComponentUtility.HasAuthority(self) then
        return
    end

    local LocalPlayerKey = UGCGameSystem.GetLocalPlayerKey()
    if PlayerKey == LocalPlayerKey then
        if Mesh ~= nil then
            self.P1:SetSkeletalMesh(Mesh, true) 
        end
        self.P1:SetVisibility(true)

        --更新对应玩家的大厅铭牌信息
        LobbyUtils.UpdateWidget(LobbyWidgetType.LWT_MainLobby, {Index=1, PlayerState=UGCGameSystem.GetLocalPlayerState()})
        return
    end

    local TeammatePlayerKeys = UGCGameSystem.GetLocalPlayerController().LobbyTeammatePlayerKeys
    if #TeammatePlayerKeys == 1 then
        return
    end

    local Index = 0
    local TeammatePlayerState = nil
    for _, TeammatePlayerKey in ipairs(TeammatePlayerKeys) do
        if TeammatePlayerKey ~= LocalPlayerKey then
            Index = Index + 1

            if TeammatePlayerKey == PlayerKey then
                if Mesh ~= nil then
                    self.TeammateAvatars[Index]:SetSkeletalMesh(Mesh, true)
                end

                self.TeammateAvatars[Index]:SetVisibility(true)
                
                TeammatePlayerState = UGCTeamSystem.GetTeammatePlayerStateByPlayerKey(TeammatePlayerKey)
                --PlayerState可能还没同步到客户端
                PromiseFuture.New():Set(
                    function (PromiseFuture)
                        while not TeammatePlayerState do
                            print("BP_LobbyAvatars:ApplyAvatarMesh TeammatePlayerState is nil, try to get new one")
                            TeammatePlayerState = UGCTeamSystem.GetTeammatePlayerStateByPlayerKey(TeammatePlayerKey)
                            PromiseFuture:Yield()
                        end

                        --更新对应玩家的大厅铭牌信息
                        LobbyUtils.UpdateWidget(LobbyWidgetType.LWT_MainLobby, {Index=Index+1, PlayerState=TeammatePlayerState})
                    end
                ):AutoResume(self, 0.5, 10)
                
                break
            end
        end
    end
end

function BP_LobbyAvatars:GetReplicatedProperties()
    return
end

function BP_LobbyAvatars:GetAvailableServerRPCs()
    return "Server_SetupTeammateAvatar"
end

return BP_LobbyAvatars