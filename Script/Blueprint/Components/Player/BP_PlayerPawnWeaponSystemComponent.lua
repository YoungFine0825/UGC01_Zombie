---@class BP_PlayerPawnWeaponSystemComponent_C:ActorComponent
---

---@type BP_PlayerPawnWeaponSystemComponent_C
local BP_PlayerPawnWeaponSystemComponent = {}
 
--[[--]]
function BP_PlayerPawnWeaponSystemComponent:ReceiveBeginPlay()
    BP_PlayerPawnWeaponSystemComponent.SuperClass.ReceiveBeginPlay(self)
    ---@type ASTExtraBaseCharacter
    self.OwnerCharacter = UGCActorComponentUtility.GetOwner(self)
    if self.OwnerCharacter then
        self.OwnerCharacter.OnCharacterShootDelegate:Add(self.OnPlayerShoot,self)
        ---@type UGCPlayerState_C
        self.PlayerState = UGCGameSystem.GetPlayerStateByPlayerPawn(self.OwnerCharacter)
    end
end


--[[
function BP_PlayerPawnWeaponSystemComponent:ReceiveTick(DeltaTime)
    BP_PlayerPawnWeaponSystemComponent.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function BP_PlayerPawnWeaponSystemComponent:ReceiveEndPlay()
    BP_PlayerPawnWeaponSystemComponent.SuperClass.ReceiveEndPlay(self)
    if self.OwnerCharacter then
        self.OwnerCharacter.OnCharacterShootDelegate:Remove(self.OnPlayerShoot,self)
    end
end


---@private
---@param Weapon ASTExtraWeapon
function BP_PlayerPawnWeaponSystemComponent:OnPlayerShoot(Weapon)
    if self.PlayerState then
        self.PlayerState.WeaponSystemComponent:OnPlayerShoot(Weapon)
    end
end

return BP_PlayerPawnWeaponSystemComponent