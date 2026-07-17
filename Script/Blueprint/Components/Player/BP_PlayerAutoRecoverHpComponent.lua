---@class BP_PlayerAutoRecoverHpComponent_C:ActorComponent
--Edit Below--
---@type BP_PlayerAutoRecoverHpComponent_C
local BP_PlayerAutoRecoverHpComponent = {}

---@type UGCPlayerPawn_C
BP_PlayerAutoRecoverHpComponent.Owner = nil

--[[--]]
function BP_PlayerAutoRecoverHpComponent:ReceiveBeginPlay()
    BP_PlayerAutoRecoverHpComponent.SuperClass.ReceiveBeginPlay(self)
    --
    ---@type UGCPlayerPawn_C
    local playerPawn = UGCActorComponentUtility.GetOwner(self)
    self.Owner = playerPawn
    --
    if UGCGameSystem.IsServer() then
        self:OnBeginPlayServer()
    end
end

--[[
function BP_PlayerAutoRecoverHpComponent:ReceiveTick(DeltaTime)
    BP_PlayerAutoRecoverHpComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function BP_PlayerAutoRecoverHpComponent:ReceiveEndPlay()
    BP_PlayerAutoRecoverHpComponent.SuperClass.ReceiveEndPlay(self)
    if UGCGameSystem.IsServer() then
        self:OnEndPlayerServer()
    end
    self.Owner = nil
end


function BP_PlayerAutoRecoverHpComponent:OnBeginPlayServer()
    GameplayUtils.Print("BP_PlayerAliveStateControlComponent.OnBeginPlayServer!")
    --监听受伤
    UGCGenericMessageSystem.ListenGlobalMessage(self.Owner,"UGC.PlayerPawn.PostTakeDamage",self,self.LuaPostTakeDamage)

    local RecoverBuffClass = self:TryLoadRecoverHPBuffClass()
    if RecoverBuffClass then
        ugcprint("UGCPlayerPawn:InitInServer "..tostring(self.PlayerName).." Load RecoverBuff Class Successful!")
    else
        ugcprint("UGCPlayerPawn:InitInServer "..tostring(self.PlayerName).." Load RecoverBuff Class Failed!")
    end
    self.RecoverBuffClass = RecoverBuffClass
end

function BP_PlayerAutoRecoverHpComponent:OnEndPlayerServer()
    UGCTimerUtility.RemoveLuaTimerByName("RecoverBuffTimer")
end

--判断武器伤害类型
---生效范围：服务器
---@param VictimPlayer ASTExtraBaseCharacter|AUGCMobCharacter @造成伤害的玩家角色|怪物
---@param DamageCauserActor AActor @伤害来源
---@param EventInstigator Controller @伤害来源的玩家控制器
---@param Damage float @伤害值
---@param DamageContext FGameMagnitudeContext @伤害事件上下文
function BP_PlayerAutoRecoverHpComponent:LuaPostTakeDamage(VictimPlayer, DamageCauserActor, EventInstigator, Damage, DamageContext)
    GameplayUtils.Print("BP_PlayerAutoRecoverHpComponent.LuaPostTakeDamage： "..tostring(self.Owner.PlayerName))

    --先清理Timer
    UGCTimerUtility.RemoveLuaTimerByName("RecoverBuffTimer")

    if not self.RecoverBuffClass then
        local RecoverBuffClass = self:TryLoadRecoverHPBuffClass()
        if not RecoverBuffClass then
            ugcprint("BP_PlayerAutoRecoverHpComponent:LuaPostTakeDamage: Cannot load RecoverHPBuff class !")
            return
        end
    end

    --清理Buff
    UGCPersistEffectSystem.RemoveBuffByClass(self.Owner,self.RecoverBuffClass)

    local aliveState = self.Owner.PlayerAliveStateControlComponent:GetAliveState()
    if aliveState == EPlayerAliveState.Alive then
        --受伤若干秒后添加回血Buff
        UGCTimerUtility.CreateLuaTimer(2,function()
            ugcprint("BP_PlayerAutoRecoverHpComponent:LuaPostTakeDamage "..tostring(self.Owner.PlayerName).." Add RecoverBuff")
            UGCPersistEffectSystem.AddBuffByClass(self.Owner,self.RecoverBuffClass)
        end,false,"RecoverBuffTimer")
    end
end

---@private
function BP_PlayerAutoRecoverHpComponent:TryLoadRecoverHPBuffClass()
    local RecoverBuffPath = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Prefabs/Buffs/Buff_RecoverHP.Buff_RecoverHP_C')
    local RecoverBuffClass = UE.LoadClass(RecoverBuffPath)
    self.RecoverBuffClass = RecoverBuffClass
    return RecoverBuffClass
end

return BP_PlayerAutoRecoverHpComponent