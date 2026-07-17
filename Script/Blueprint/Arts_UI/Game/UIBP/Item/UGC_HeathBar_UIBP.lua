---@class UGC_HeathBar_UIBP_C:UGC_Player_HealthBar_UIBP_C
--Edit Below--
local UGC_HeathBar_UIBP = { bInitDoOnce = false } 

--[==[ Construct
function UGC_HeathBar_UIBP:Construct()
	self.UGC_ReuseList2_AttrBar:SetVisibility(ESlateVisibility.Collapsed)
end
-- Construct ]==]

-- function UGC_HeathBar_UIBP:Tick(MyGeometry, InDeltaTime)

-- end

-- function UGC_HeathBar_UIBP:Destruct()

-- end

return UGC_HeathBar_UIBP