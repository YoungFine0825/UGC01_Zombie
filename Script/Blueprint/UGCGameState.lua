---@class UGCGameState_C:BP_UGCGameState_C
---@field MatchTimeout int32
--Edit Below--
UGCGameSystem.UGCRequire('Script.Common.ue_enum_custom')
UGCGameSystem.UGCRequire("Script.Blueprint.PortalDoor.PortalManager")
local Delegate = require("common.Delegate")
local UGCGameData = UGCGameSystem.UGCRequire('Script.Blueprint.UGCGameData')
local UGCGameState = {};
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

function UGCGameState:StartPortalCountDown()
   if UGCActorComponentUtility.HasAuthority(self) and self.PortalInfo.CurrentPortalCountDown <= 0 then
      ugcprint("UGCGameState:StartPortalCountDown")
      self.PortalCountDownStartTime = UGCGameSystem.GetServerTimeSec()
      self:CalculatePortalCountDown()
   end
end

function UGCGameState:StopPortalCountDown()
   if UGCActorComponentUtility.HasAuthority(self) and self.PortalInfo.CurrentPortalCountDown > 0 then
      ugcprint("UGCGameState:StopPortalCountDown")
      if self.PortalCountDownTimer ~= nil then
         UGCTimerUtility.RemoveLuaTimer(self.PortalCountDownTimer)
         self.PortalCountDownTimer = nil
      end
      
      self.PortalInfo.CurrentPortalCountDown = -1
      UnrealNetwork.RepLazyProperty(self, "PortalInfo")
   end
end

function UGCGameState:CalculatePortalCountDown()
   local CurrentTime = UGCGameSystem.GetServerTimeSec()
   self.PortalInfo.CurrentPortalCountDown = self.PortalCountDown - (CurrentTime - self.PortalCountDownStartTime)
   UnrealNetwork.RepLazyProperty(self, "PortalInfo")

   if self.PortalInfo.CurrentPortalCountDown > 0 then
      self.PortalCountDownTimer = UGCTimerUtility.CreateLuaTimer(1, 
         function ()
            self:CalculatePortalCountDown()
         end,
         false
      )
   else
      --倒计时结束传送到下一关
      ugcprint("UGCGameState:CalculatePortalCountDown Teleport to next level")
      self.PortalCountDownTimer = nil
      UGCLevelFlowSystem.GoToNextLevelForAllPlayers()
   end
end

function UGCGameState:StartRespawnChanceCountDown()
   if UGCActorComponentUtility.HasAuthority(self) and self.CurrentRespawnChanceCountDown <= 0 then
      ugcprint("UGCGameState:StartRespawnChanceCountDown")
      self.RespawnChanceCountDownStartTime = UGCGameSystem.GetServerTimeSec()
      self:CalCulateRespawnChanceCountDown()
   end
end

function UGCGameState:StopRespawnChanceCountDown()
   if UGCActorComponentUtility.HasAuthority(self) and self.CurrentRespawnChanceCountDown > 0 then
      ugcprint("UGCGameState:StopRespawnChanceCountDown")
      if self.RespawnChanceCountDownTimer ~= nil then
         UGCTimerUtility.RemoveLuaTimer(self.RespawnChanceCountDownTimer)
         self.RespawnChanceCountDownTimer = nil
      end
      
      self.CurrentRespawnChanceCountDown = -1
      UnrealNetwork.RepLazyProperty(self, "CurrentRespawnChanceCountDown")
   end
end

function UGCGameState:CalCulateRespawnChanceCountDown()
   local CurrentTime = UGCGameSystem.GetServerTimeSec()
   self.CurrentRespawnChanceCountDown = self.RespawnChanceCountDown - (CurrentTime - self.RespawnChanceCountDownStartTime)
   UnrealNetwork.RepLazyProperty(self, "CurrentRespawnChanceCountDown")

   if self.CurrentRespawnChanceCountDown > 0 then
      self.RespawnChanceCountDownTimer = UGCTimerUtility.CreateLuaTimer(1, 
         function ()
            self:CalCulateRespawnChanceCountDown()
         end,
         false
      )
   else
      -- 触发结算
      ugcprint("UGCGameState:CalCulateRespawnChanceCountDown Begin settlement")
      self.RespawnChanceCountDownTimer = nil
      if #self.PlayerArray > 0 then
         UGCLevelFlowSystem.GameSettle(false)
      end
   end
end

function UGCGameState:OnPlayerDead(PlayerKey)
   if self.DeadPlayerKeys[PlayerKey] == true then
      return
   end
   self.DeadPlayerKeys[PlayerKey] = true

   local DeadPlayerNum = 0
   for PlayerKey, Value in pairs(self.DeadPlayerKeys) do
      DeadPlayerNum = DeadPlayerNum + 1
   end
   ugcprint("UGCGameState:OnPlayerDead Current DeadPlayerNum=" .. tostring(DeadPlayerNum))

   local PlayerNum = #self.PlayerArray
   if DeadPlayerNum >= PlayerNum then
      self:StartRespawnChanceCountDown()
   end
end

function UGCGameState:OnPlayerAlive(PlayerKey)
   if self.DeadPlayerKeys[PlayerKey] == nil then
      return
   end
   self.DeadPlayerKeys[PlayerKey] = nil

   local DeadPlayerNum = 0
   for PlayerKey, Value in pairs(self.DeadPlayerKeys) do
      DeadPlayerNum = DeadPlayerNum + 1
   end
   ugcprint("UGCGameState:OnPlayerAlive Current DeadPlayerNum=" .. tostring(DeadPlayerNum))

   local PlayerNum = #self.PlayerArray
   if DeadPlayerNum < PlayerNum then
      self:StopRespawnChanceCountDown()
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
   PortalManager.OnCountDownUpdate(self.CurrentPortalCountDown)
end

function UGCGameState:OnRep_PortalInfo()
   PortalManager.OnCountDownUpdate(self.PortalInfo.CurrentPortalCountDown, self.PortalInfo.InPortalPlayerKeys)
end

function UGCGameState:OnRep_CurrentRespawnChanceCountDown()
   BreakthroughManager:RefreshRespawnUICountDown(self.CurrentRespawnChanceCountDown)
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

return UGCGameState;
