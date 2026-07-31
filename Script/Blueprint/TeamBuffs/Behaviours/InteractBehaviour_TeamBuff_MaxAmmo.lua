
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
local InteractBehaviour_TeamBuff_MaxAmmo = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_TeamBuff_MaxAmmo:ReceiveBeginPlay()
    InteractBehaviour_TeamBuff_MaxAmmo.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_TeamBuff_MaxAmmo:ReceiveTick(DeltaTime)
    InteractBehaviour_TeamBuff_MaxAmmo.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_TeamBuff_MaxAmmo:ReceiveEndPlay()
    InteractBehaviour_TeamBuff_MaxAmmo.SuperClass.ReceiveEndPlay(self) 
end

---@public
---@param playerKey number
function InteractBehaviour_TeamBuff_MaxAmmo:Execute(playerKey)
    --
    self.BaseClass.Execute(self,playerKey)
    --
    if self.m_isClient then
        self:OnFinish()
        return
    end
    --
    local allPlayerKeys = UGCGameSystem.GetAllPlayerKey()
    for k,pk in pairs(allPlayerKeys) do
        local weaponsConfigID = GameplaySystem.WeaponSystem:GetPlayerEquippedWeaponsConfigID(pk)
        if #weaponsConfigID > 0 then
            for _,weaponConfigID in pairs(weaponsConfigID) do
                local success = GameplaySystem.WeaponSystem:ServerReplenishWeaponAndAmmos(pk,weaponConfigID)
                if not success then
                    GameplayUtils.Exception("InteractBehaviour_TeamBuff_MaxAmmo.Execute: 为玩家 ",pk," 补充武器 ",weaponConfigID," 失败！")
                end
            end
        else
            GameplayUtils.Exception("InteractBehaviour_TeamBuff_MaxAmmo.Execute: 玩家 ",pk," 未装备任何武器！")
        end
    end
    --
    self:OnFinish()
end

return InteractBehaviour_TeamBuff_MaxAmmo