---@class PortalDoor_C:ActivityBaseActor
---@field DisappearEffects UParticleSystemComponent
---@field P_convey_01 UParticleSystemComponent
---@field Trigger UCapsuleComponent
---@field Mesh UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
---@field Group int32
---@field FaceDirection TArray<bool>
---@field AudioEvent UAkEventObject
---@field CustomDistance int32
---@field PortalDoorClass UClass
--Edit Below--
UGCGameSystem.UGCRequire("Script.Blueprint.PortalDoor.PortalManager")
local PortalDoor = { };

-- 在表中查找值，如果不存在则添加并返回索引
local function FindOrAddValueInTable(InTable, InValue)
    for i, v in ipairs(InTable) do
        if v == InValue then
            return i
        end
    end
    table.insert(InTable, InValue)
    return #InTable
end

-- 检查值是否存在，存在则返回索引，否则返回nil
local function FindValue(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

-- 移除表中第一个匹配的值(如果存在)，返回是否移除成功
local function RemoveValue(t, value)
    local index = FindValue(t, value)
    if index then
        table.remove(t, index)
        return true  -- 返回移除状态
    end
    return false
end


-- 传送门部分逻辑为原无用设置，只关注OnBeginOverlap即可
function PortalDoor:ReceiveBeginPlay()
    ugcprint(string.format("[PortalDoor:ReceiveBeginPlay] self=%s", UGCObjectUtility.GetObjectFullName(self)))
    PortalDoor.SuperClass.ReceiveBeginPlay(self)

    self.CurrentIndex.StateIndex = 998
    if UGCGameSystem.IsServer() then 
        self:InitDoor()

        UGCGenericMessageSystem.ListenGlobalMessage(self, UGCGenericMessageSystem.Messages.UGC.LevelFlow.LevelBegin, self, self.OnLevelBegin)
    end
end

function PortalDoor:OnLevelBegin(CurStage)
    ugcprint(string.format("PortalDoor:OnLevelBegin CurrentStage = %d, PortalDoor's Location =[%s %s %s]", CurStage, self:K2_GetActorLocation().X, self:K2_GetActorLocation().Y, self:K2_GetActorLocation().Z))
    UGCGameSystem.GameState.LevelState = UGCGameSystem.GameState.LevelStateEnum.Game
    PortalManager:RegisterPortalActor(self)

    UGCGenericMessageSystem.UnListenMessage(self, UGCGenericMessageSystem.Messages.UGC.LevelFlow.LevelBegin)
end

function PortalDoor:InitDoor()
    if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
    ugcprint(string.format("[PortalDoor:InitDoor]"))
    self.Trigger.OnComponentBeginOverlap:Add(self.OnBeginOverlap, self)
    self.Trigger.OnComponentEndOverlap:Add(self.Trigger_OnComponentEndOverlap, self);
end

function PortalDoor:ReceiveEndPlay()
    ugcprint(string.format("[PortalDoor:ReceiveEndPlay]"))

    if UGCGameSystem.IsServer() then 
        self.Trigger.OnComponentBeginOverlap:Remove(self.OnBeginOverlap, self)
        self.Trigger.OnComponentEndOverlap:Remove(self.Trigger_OnComponentEndOverlap, self)
        PortalManager:UnregisterPortalActor(self)
    end
end

function PortalDoor:GetReplicatedProperties()
    return
    "IsPlay"
end

function PortalDoor:OnBeginOverlap(OverlappedComp, Actor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    ugcprint(string.format("[PortalDoor:OnBeginOverlap] Actor=%s", tostring(Actor)))
    -- 当玩家的Pawn和传送门折叠后，触发传送玩家
    local PlayerState = UGCGameSystem.GetPlayerStateByPlayerPawn(Actor)
    if not PlayerState then
        return
    end
    PlayerState.bIsPlayerInPortalDoor = true
    UnrealNetwork.RepLazyProperty(PlayerState, "bIsPlayerInPortalDoor")
    if Actor and UGCGameSystem.GetPlayerKeyByPlayerPawn(Actor) then
        FindOrAddValueInTable(UGCGameSystem.GameState.PortalInfo.InPortalPlayerKeys, UGCGameSystem.GetPlayerKeyByPlayerPawn(Actor))
    end
    
    local AllPlayer = UGCLevelFlowSystem.GetAllPlayerControllerInCurrentLevel()

    -- 加保底逻辑，如果玩家通关后还死，确保他在进入传送门之前是或者的状态
    for k, Player in pairs(AllPlayer) do
        if Player and UE.IsValid(Player) then
            -- 如果玩家在通关的时候仍然处于倒地状态，则扶起
            local pawn = UGCGameSystem.GetPlayerPawnByPlayerController(Player)
            local DyingTag = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Dying")
            local DeadTag = UGCGameplayTagSystem.RequestGameplayTag("PawnState.Dead")
            if pawn and UGCPersistEffectSystem.HasDynamicState(pawn, DyingTag) then
                ugcprint("SingleMode_1_Settle:LuaExecuteWithFinish Player"..tostring(UGCGameSystem.GetPlayerKeyByPlayerController(Player)).." is dying")
                pawn.RescueOtherComponent:RescueSucImmediately(pawn)
            end

            -- 如果玩家在通关的时候仍然处于死亡状态，则复活
            if not pawn or UGCPersistEffectSystem.HasDynamicState(pawn, DeadTag) then
                ugcprint("SingleMode_1_Settle:LuaExecuteWithFinish Player"..tostring(UGCGameSystem.GetPlayerKeyByPlayerController(Player)).." is dead")
                UGCPlayerPawnSystem.RespawnPlayer(UGCGameSystem.GetPlayerKeyByPlayerController(Player), _, true)
            else
                UGCPawnAttrSystem.SetHealth(pawn, UGCPawnAttrSystem.GetHealthMax(pawn))
            end
        end
    end

    if #UGCGameSystem.GameState.PortalInfo.InPortalPlayerKeys == #AllPlayer then
        UGCLevelFlowSystem.GoToNextLevelForAllPlayers()
        PortalManager:StopPortalCountDown()
    else   
        PortalManager:StartPortalCountDown()
    end
end 

function PortalDoor:PlayDisappear(Actor, LinkDoorLocation_X, LinkDoorLocation_Y)
    self.DisappearEffects:SetActive(true, true)
    UGCSoundManagerSystem.PlaySoundAtLocation(self.AudioEvent, Vector.New(LinkDoorLocation_X, LinkDoorLocation_Y, 0))
end

function PortalDoor:OnEnterState_BP(StateName)
    if not UGCGameSystem.IsServer() then 
        self.CurrentIndex.StateIndex = 998
    end
end

-- [Editor Generated Lua] function define Begin:

function PortalDoor:Trigger_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if OtherActor and UGCGameSystem.GetPlayerKeyByPlayerPawn(OtherActor) then
        local PlayerState = UGCGameSystem.GetPlayerStateByPlayerPawn(OtherActor)
        if not PlayerState then
            return
        end
        PlayerState.bIsPlayerInPortalDoor = false
        UnrealNetwork.RepLazyProperty(PlayerState, "bIsPlayerInPortalDoor")
        RemoveValue(UGCGameSystem.GameState.PortalInfo.InPortalPlayerKeys, UGCGameSystem.GetPlayerKeyByPlayerPawn(OtherActor))

        if #UGCGameSystem.GameState.PortalInfo.InPortalPlayerKeys == 0 then
            PortalManager:StopPortalCountDown()
        end
    end

end

-- [Editor Generated Lua] function define End;

return PortalDoor
