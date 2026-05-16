local Monster_Remote2 = 
{
    LuaLogicPart = nil,
    MonsterID = 10001,
    MonsterType = 'Monster',
}

function Monster_Remote2:ReceiveBeginPlay()
    ugcprint("Monster_Remote2:ReceiveBeginPlay")
    Monster_Remote2.SuperClass.ReceiveBeginPlay(self)

    self.LuaLogicPart = UGCGameSystem.UGCRequire("Script.Blueprint.Prefabs.Monsters.LuaMonsterLogicPart"):New()
    self.LuaLogicPart.Owner = self
    self.LuaLogicPart:ReceiveBeginPlay()
end

--[[
function Monster_Remote2:ReceiveTick(DeltaTime)
    Monster_Remote2.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function Monster_Remote2:ReceiveEndPlay()
    Monster_Remote2.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function Monster_Remote2:GetReplicatedProperties()
    return
end
--]]

--[[
-- 	 * 受击前置事件
--	 * 生效范围：服务器
--	 * @param float Damage 伤害值
--	 * @param AController EventInstigator 伤害来源的Controller
--	 * @param AActor DamageCauser 伤害来源
--	 * @param FGameMagnitudeContext DamageContext 伤害上下文
function Monster_Remote2:PreTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
     
end
--]]

--[[
-- 	 * 受击后置事件
--	 * 生效范围：服务器
--	 * @param float Damage 伤害值
--	 * @param AController EventInstigator 伤害来源的Controller
--	 * @param AActor DamageCauser 伤害来源
--	 * @param FGameMagnitudeContext DamageContext 伤害上下文
function Monster_Remote2:PostTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
    
end
--]]

--[[
-- 	 * 受击后置事件
--	 * 生效范围：服务器
--	 * @param float Damage 伤害值
--	 * @param int32 DamageType 伤害类型
--	 * @param AController EventInstigator 伤害来源的Controller
--	 * @param AActor DamageCauser 伤害来源
--	 * @param FHitResult Hit 伤害上下文
--   * @return float 修改后的伤害值
function Monster_Remote2:PreOverrideDamageValue(Damage, DamageType, EventInstigator, DamageCauser, Hit)
    return Damage
end
--]]

--[[
-- 	 * 受击后置事件
--	 * 生效范围：服务器
--	 * @param float Damage 伤害值
--	 * @param int32 DamageType 伤害类型
--	 * @param AController EventInstigator 伤害来源的Controller
--	 * @param AActor DamageCauser 伤害来源
--	 * @param FHitResult Hit 伤害上下文
--   * @return float 修改后的伤害值
function Monster_Remote2:PostOverrideDamageValue(Damage, DamageType, EventInstigator, DamageCauser, Hit)
    return Damage
end
--]]

--[[
-- 	 * 状态进入事件
--	 * 生效范围：服务器&客户端
--	 * @param DynamicState 进入状态
function Monster_Remote2:OnEnterTagState_BP(DynamicState)

end
--]]

--[[
-- 	 * 状态退出事件
--	 * 生效范围：服务器&客户端
--	 * @param DynamicState 进入状态
function Monster_Remote2:OnEnterTagState_BP(DynamicState)

end
--]]

--[[
-- 	 * 状态打断事件
--	 * 生效范围：服务器&客户端
--	 * @param DynamicState 进入状态
function Monster_Remote2:OnEnterTagState_BP(DynamicState)

end
--]]

--[[
-- 	 * 行为树消息
--	 * 生效范围：服务器
--	 * @param NotifyMsg 消息
function Monster_Remote2:OnEnterTagState_BP(DynamicState)

end
--]]

function Monster_Remote2:BPDie(Damage, Killer, DamageCauser, DamageEvent, DamageTypeID)
    ugcprint("Monster_Remote2:BPDie")
    self.LuaLogicPart:BPDie(Damage, Killer, DamageCauser, DamageEvent, DamageTypeID)
end

return Monster_Remote2