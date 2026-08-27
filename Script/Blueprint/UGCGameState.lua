---@class UGCGameState_C:BP_UGCGameState_C
---@field GameplayStateComponent BP_GameplayStateComponent_C
---@field MatchTimeout int32
--Edit Below--
UGCGameSystem.UGCRequire('Script.Common.ue_enum_custom')
UGCGameSystem.UGCRequire("Script.Blueprint.PortalDoor.PortalManager")
local Delegate = require("common.Delegate")
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
---@type UGCGameState_C
local UGCGameState = {}
-- 装备词缀管理器
UGCGameState.EquipmentAffixManager = UGCGameSystem.UGCRequire('Script.Blueprint.Affix.EquipmentAffixManager')
-- -- 重叠玩家表（用于处理玩家重叠状态）
-- UGCGameState.OverlappingPlayer = {}

-- 传送门倒计时总时长（秒）
UGCGameState.PortalCountDown = 30
-- 当前传送门剩余倒计时
UGCGameState.CurrentPortalCountDown = 0
-- 复活机会倒计时总时长（秒）
UGCGameState.RespawnChanceCountDown = 10
-- 当前复活机会剩余倒计时
UGCGameState.CurrentRespawnChanceCountDown = 0
-- 死亡玩家键值表（记录已死亡玩家）
UGCGameState.DeadPlayerKeys = {}
-- 濒死玩家键值表（记录濒死玩家）
UGCGameState.DyingPlayerKeys = {}

UGCGameState.LevelStateEnum = {
   Game = 0,    -- 进行中
   Victory = 1, -- 胜利
   Failure = 2, -- 失败
}
UGCGameState.LevelState = UGCGameState.LevelStateEnum.Game

UGCGameState.PortalInfo = {
   CurrentPortalCountDown = 0,
   InPortalPlayerKeys = {}
}

function UGCGameState:ReceiveBeginPlay()
   self.SuperClass.ReceiveBeginPlay(self)
   self:ListenMessage()
end

function UGCGameState:ListenMessage()
   UGCGenericMessageSystem.ListenGlobalMessage(self, "UGC.LevelFlow.LevelBegin", self, self.ResetData)
   if UGCGameSystem.IsServer() then
      GameplaySystem.EventSystem:Listen(GameplayEvents.Server.OnPlayerAliveStateChanged,self,self.OnPlayerAliveStateChanged)
      --UGCGenericMessageSystem.ListenGlobalMessage(self,GameplayEvents.Server.OnPlayerAliveStateChanged,self,self.OnPlayerAliveStateChanged)
   end
end

function UGCGameState:ReceiveEndPlay()
   self.SuperClass.ReceiveEndPlay(self)
   GameplaySystem.EventSystem:UnlistenAll(self)
end

function UGCGameState:ResetData()
   -- self.OverlappingPlayer = {}
   self.PortalInfo.CurrentPortalCountDown = 0
   self.PortalInfo.InPortalPlayerKeys = {}
   self.LevelState = self.LevelStateEnum.Game

   UGCGameState.DeadPlayerNum = 0

   if not self:HasAuthority() and ShopV2Manager then
      ShopV2Manager:CloseMainUI()
   end
end

function UGCGameState:IsAllLobbyTeammateReady()
   local bIsUGCPIE = UGCBlueprintFunctionLibrary.IsUGCPIE(self)

   local bReady = true
   if bIsUGCPIE then ---PIE 默认全部玩家都是一个大厅队伍
      for _, PlayerState in ipairs(self.PlayerArray) do
         bReady = bReady and PlayerState.bIsReadyInLobby
      end
   else
      local PC = UGCGameSystem.GetLocalPlayerController()

      if PC ~= nil then
         for _, PlayerKey in ipairs(PC.LobbyTeammatePlayerKeys) do
            for _, PlayerState in ipairs(self.PlayerArray) do
               if UGCGameSystem.GetPlayerKeyByPlayerState(PlayerState) == PlayerKey then
                  bReady = bReady and PlayerState.bIsReadyInLobby
                  break
               end
            end
         end
      else
         bReady = false
      end
   end

   return bReady
end

---@private 作用范围：服务端
---@param playerController UGCPlayerController_C
function UGCGameState:OnPlayerAliveStateChanged(playerController,newState,previousState)
   local playerKey = UGCGameSystem.GetPlayerKeyByPlayerController(playerController)
   GameplayUtils.Print("UGCGameState.OnPlayerAliveStateChanged: Player ",playerKey," alive state changed to ",newState)
   if newState == EPlayerAliveState.Dying then
      --设置为原地复活
      UGCPlayerPawnSystem.SetDefaultPlayerRespawnPointSelectionMethod(EUGCPlayerRespawnPointSelectionMethod.RespawnOnTheSpot)
      self:OnPlayerDying(playerKey)
   elseif newState == EPlayerAliveState.Dead then
      --设置为原地复活
      UGCPlayerPawnSystem.SetDefaultPlayerRespawnPointSelectionMethod(EUGCPlayerRespawnPointSelectionMethod.RespawnOnTheSpot)
      self:OnPlayerDead(playerKey)
   elseif newState == EPlayerAliveState.Alive then
      self:OnPlayerAlive(playerKey)
   end
end

---@private
function UGCGameState:OnPlayerDying(PlayerKey)
   if self.DyingPlayerKeys[PlayerKey] then
      return
   end
   self.DyingPlayerKeys[PlayerKey] = true

   local DyingPlayerNum = 0
   for PlayerKey, Value in pairs(self.DyingPlayerKeys) do
      DyingPlayerNum = DyingPlayerNum + 1
   end
   ugcprint("UGCGameState:OnPlayerDying Current Dying Player Num=" .. tostring(DyingPlayerNum))

   local SelfRescue = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Buff.SelfRescue")
   local PlayerNum = GameplaySystem.PlayerSystem:GetCurrentPlayerNum()
   if PlayerNum > 1 then
      if DyingPlayerNum >= PlayerNum then--大于1名玩家时，如果所有玩家都倒地了，则判断为全员阵亡
         --所有濒死角色判定为死亡
         for playerKey,v in pairs(self.DyingPlayerKeys) do
            GameplaySystem.PlayerSystem:ServerKillPlayer(playerKey)
         end
      end
   else
      if GameplaySystem.PlayerSystem:ShouldPlayerDirectlyDie(PlayerKey) then--只有一名玩家，且没有自救能力，则判断为全员阵亡
         GameplaySystem.PlayerSystem:ServerKillPlayer(PlayerKey)
      else
         --让玩家开始自救
         GameplaySystem.PlayerSystem:ServerStartSelfRescue(PlayerKey)
      end
   end
end

---@private
function UGCGameState:OnPlayerDead(PlayerKey)
   if self.DeadPlayerKeys[PlayerKey] == true then
      return
   end
   self.DeadPlayerKeys[PlayerKey] = true

   local DeadPlayerNum = 0
   for PlayerKey, Value in pairs(self.DeadPlayerKeys) do
      DeadPlayerNum = DeadPlayerNum + 1
   end
   GameplayUtils.Print("UGCGameState:OnPlayerDead Current DeadPlayerNum=" .. tostring(DeadPlayerNum))

   local PlayerNum = GameplaySystem.PlayerSystem:GetCurrentPlayerNum()
   if DeadPlayerNum >= PlayerNum then
      --全员阵亡
      GameplaySystem.EventSystem:BroadcastGlobal(GameplayEvents.Server.OnAllPlayersDead)
   end
end

---@private
function UGCGameState:OnPlayerAlive(PlayerKey)
   local isDyingOrDead = self.DyingPlayerKeys[PlayerKey] == true or self.DeadPlayerKeys[PlayerKey] == true
   if not isDyingOrDead then
      return
   end
   self.DyingPlayerKeys[PlayerKey] = nil
   self.DeadPlayerKeys[PlayerKey] = nil

   local DeadPlayerNum = 0
   for PlayerKey, Value in pairs(self.DeadPlayerKeys) do
      DeadPlayerNum = DeadPlayerNum + 1
   end
   GameplayUtils.Print("UGCGameState:OnPlayerAlive Current DeadPlayerNum=" .. tostring(DeadPlayerNum))

   local PlayerNum = #self.PlayerArray
   if DeadPlayerNum < PlayerNum then

   end
end

function UGCGameState:GetAvailableServerRPCs()
   return
end

function UGCGameState:GetReplicatedProperties()
   return {"PortalInfo", "Lazy"},
   {"CurrentRespawnChanceCountDown", "Lazy"}
end

function UGCGameState:OnRep_CurrentPortalCountDown()

end

function UGCGameState:OnRep_PortalInfo()

end

function UGCGameState:OnRep_CurrentRespawnChanceCountDown()

end

function UGCGameState:OnRep_LobbyInfo()
   print("UGCGameState:OnRep_LobbyInfo")

   LobbyModel.CurrentSelectedModeID = LobbyModel:IsModeIDValid(self.LobbyInfo.SelectedModeID) and self.LobbyInfo.SelectedModeID or 1001
   LobbyEvent.OnModeSelected(self.LobbyInfo.SelectedModeID)
   LobbyUtils.UpdateWidget(LobbyWidgetType.LWT_MainLobby, { ModeID = self.LobbyInfo.SelectedModeID })
end

function UGCGameState.IsInLobby()
   return UGCGameData.GetGameModeName(UGCMultiMode.GetModeID()) == UGCGameData.ModeName.Lobby
end

---@public
---@return boolean
function UGCGameState:IsPlayerAllDead()
   local deadNum = 0
   for k,v in pairs(self.DeadPlayerKeys) do
      deadNum = deadNum + 1
   end
   local ret = deadNum >= #self.PlayerArray
   return ret
end

return UGCGameState;
