---@class BP_WeaponSystemComponent_C:ActorComponent
---@field WeaponConfigID int32
--Edit Below--
local BP_WeaponSystemComponent = {}
 
--[[--]]
function BP_WeaponSystemComponent:ReceiveBeginPlay()
    BP_WeaponSystemComponent.SuperClass.ReceiveBeginPlay(self)
    self.m_ammoItemId = nil
    ---@type BP_UGC_ShootWeaponBase_C
    local weaponActor = UGCActorComponentUtility.GetOwner(self)
    --
    self.m_weaponActor = weaponActor
    ---@type UGCPlayerPawn_C
    local weaponOwner = weaponActor:GetOwner()
    self.m_weaponOwner = weaponOwner

    --
    self:ResetBulletDefineID()
end


--[[
function BP_WeaponSystemComponent:ReceiveTick(DeltaTime)
    BP_WeaponSystemComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_WeaponSystemComponent:ReceiveEndPlay()
    BP_WeaponSystemComponent.SuperClass.ReceiveEndPlay(self) 
end
--]]

function BP_WeaponSystemComponent:ResetBulletDefineID()
    local weaponConfig = GameplaySystem.WeaponConfigMgr:GetWeaponConfigData(self.WeaponConfigID)
    if not weaponConfig then
        GameplayUtils.Print("BP_WeaponSystemComponent.ResetBulletDefineID: 未找到武器配置 ",self.WeaponConfigID)
        return
    end
    local ammoItemId = weaponConfig.AmmoItemId
    self.m_ammoItemId = ammoItemId
    local bulletDefineID = GameplaySystem.BackpackSystem:GetGainedItemDefineId(self.m_weaponOwner,ammoItemId)
    self.m_weaponActor.ShootWeaponEntity.BulletType = bulletDefineID
    UGCTimerUtility.CreateLuaTimer(0.5,function()
        if UE.IsValid(self) and UE.IsValid(self.m_weaponActor) and UE.IsValid(self.m_weaponOwner) then
            local bulletDefineID = GameplaySystem.BackpackSystem:GetGainedItemDefineId(self.m_weaponOwner,self.m_ammoItemId)
            self.m_weaponActor.ShootWeaponEntity.BulletType = bulletDefineID
        end
    end,false)
end

return BP_WeaponSystemComponent