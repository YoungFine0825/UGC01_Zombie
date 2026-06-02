local UGCRequire = UGCGameSystem.UGCRequire

---@class GameplayBooter
local GameplayBooter = {}

---require全局子系统
GameplaySystem = {
    ---@type Gameplay.WeaponSystem
    WeaponSystem = UGCRequire("Script.Gameplay.Weapon.WeaponSystem"),
    ---@type Gameplay.WeaponConfigMgr
    WeaponConfigMgr = UGCRequire("Script.Gameplay.Weapon.WeaponConfigMgr"),
    ---@type Gameplay.BackpackSystem
    BackpackSystem = UGCRequire("Script.Gameplay.Backpack.BackpackSystem"),
}


---@public
function GameplayBooter.ReceiveBeginPlay()

end

---@public
function GameplayBooter.ReceiveEndPlay()
end

return GameplayBooter