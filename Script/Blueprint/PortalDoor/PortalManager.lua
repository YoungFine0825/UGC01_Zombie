local Delegate = require("common.Delegate")

PortalManager = PortalManager or 
{
    PortalActor = nil,

    OnCountDownUpdate = Delegate.New()
}

function PortalManager:RegisterPortalActor(Actor)
    self.PortalActor = Actor
end

function PortalManager:UnregisterPortalActor(Actor)
    if Actor == self.PortalActor then
        self.PortalActor = nil 
    end
end

function PortalManager:RequestTeleportToPortal()
    local PC = UGCGameSystem.GetLocalPlayerController()

    if PC ~= nil then
        UnrealNetwork.CallUnrealRPC(PC, PC, "RPC_Server_TeleportToPortal")
    end
end

function PortalManager:StartPortalCountDown()
    if UGCGameSystem.GameState ~= nil then
        UGCGameSystem.GameState:StartPortalCountDown()
    end
end

function PortalManager:StopPortalCountDown()
    if UGCGameSystem.GameState ~= nil then
        UGCGameSystem.GameState:StopPortalCountDown()
    end
end