---@class InteractBehaviour_Grant_C:BP_InteractEntityBehaviourComponent_C
---@field GrantType TEnumAsByte<EInteractBehaviourGrantType>
---@field WeaponConfigID int32
---@field BuffID int32
---@field bGrantToAllPlayers bool
--Edit Below--
local BPExtent = UGCGameSystem.UGCRequire("Script.Gameplay.BPExtend")
---@type InteractBehaviour_Grant_C
local InteractBehaviour_Grant = BPExtent({},"Script.Blueprint.InteractEntity.Behaviours.BP_interactEntityBehaviourComponent")
 
--[[--]]
function InteractBehaviour_Grant:ReceiveBeginPlay()
    InteractBehaviour_Grant.SuperClass.ReceiveBeginPlay(self)
end


--[[
function InteractBehaviour_Grant:ReceiveTick(DeltaTime)
    InteractBehaviour_Grant.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[--]]
function InteractBehaviour_Grant:ReceiveEndPlay()
    InteractBehaviour_Grant.SuperClass.ReceiveEndPlay(self) 
end

function InteractBehaviour_Grant:Execute(playerKey)
    if self.m_isClient then
        return
    end
    self.BaseClass.Execute(self,playerKey)
    if self.GrantType == EInteractBehaviourGrantType.Weapon then
        if self.WeaponConfigID > 0 then
            GameplaySystem.WeaponSystem:ServerDeliverAndEquipWeaponToPlayer(playerKey,self.WeaponConfigID)
        end
    end
end

return InteractBehaviour_Grant