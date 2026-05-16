---@class UIBP_Test_C:UUserWidget
---@field Button_0 UButton
--Edit Below--
UGCGameSystem.UGCRequire("Script.Blueprint.Arts_UI.Lobby.UIBP.TalentTree.Test.TalentTreeTestManager")
UGCGameSystem.UGCRequire("Script.Blueprint.Arts_UI.Lobby.TalentTreeTypes")

local UIBP_Test = { bInitDoOnce = false } 

function UIBP_Test:Construct()
	self:LuaInit()
end

function UIBP_Test:LuaInit()
    ugcprint("[TalentTree] UIBP_Test:LuaInit")
    if self.bInitDoOnce then
        return
    end

    self.bInitDoOnce = true

    self.Button_0.OnClicked:Add(self.Button_0_OnClicked, self)
end

function UIBP_Test:Button_0_OnClicked()
    ugcprint("UIBP_Test:Button_0_OnClicked")
    -- server_SetTalentPoints()
    TalentTreeManager:AddTalentPoints(9)
    -- TalentTreeTestManager:SetTalentPoints(9)
    -- TODO:通过Test改Component上的TalentPoints，再同步给客户端
end

-- function UIBP_Test:Tick(MyGeometry, InDeltaTime)

-- end

-- function UIBP_Test:Destruct()

-- end

return UIBP_Test