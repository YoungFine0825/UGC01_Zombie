---@type HeroSelectionManagerImpl
local HeroSelectionManagerImpl = UGCGameSystem.UGCRequire("ExtendResource.HeroSelect.OfficialPackage." .. "Script.HeroSelection.HeroSelectionManagerImpl")


---@class HeroSelectionManager
HeroSelectionManager = HeroSelectionManager or {
    --- delegates
    OnInitialized = HeroSelectionManagerImpl.OnInitialized, -- 初始化完成
    OnMainWidgetOpened = HeroSelectionManagerImpl.OnMainWidgetOpened, -- 打开了选择英雄面板
    OnMainWidgetClosed = HeroSelectionManagerImpl.OnMainWidgetClosed, -- 关闭了选择英雄面板
    OnHeroFocused = HeroSelectionManagerImpl.OnHeroFocused, --> (HeroID) 点选中某个英雄格子时触发
    OnHeroSelected = HeroSelectionManagerImpl.OnHeroSelected, --> (PlayerKey, HeroID)
}


---------------------------------------------------------------------------------
--- Begin Public API ------------------------------------------------------------

function HeroSelectionManager:Init(InHeroSelectionActor)
    self.HeroSelectionActor = InHeroSelectionActor
    return HeroSelectionManagerImpl:Init(InHeroSelectionActor)
end

function HeroSelectionManager:InitWidget()
    return HeroSelectionManagerImpl:InitWidget()
end

function HeroSelectionManager:IsInitialized()
    return HeroSelectionManagerImpl.bInitialized
end

---------------------------------------------------------------------------------
--- 数据 API

---获取所有英雄数据
---生效范围：客户端、服务器
---@return table<number, Hero>
function HeroSelectionManager:GetAllUGCHeroData()
    return HeroSelectionManagerImpl:GetAllUGCHeroData()
end

---获取单个英雄数据。HeroID 支持传入 number 索引值。
---生效范围：客户端、服务器
---@param HeroID number @要查询的英雄 ID
---@return Hero
function HeroSelectionManager:GetUGCHeroData(HeroID)
    return HeroSelectionManagerImpl:GetUGCHeroData(HeroID)
end

---获取所有英雄 UI 数据
---生效范围：客户端、服务器
---@return HeroUI[]
function HeroSelectionManager:GetAllUGCHeroUIData()
    return HeroSelectionManagerImpl:GetAllUGCHeroUIData()
end

---获取单个英雄 UI 数据
---生效范围：客户端、服务器
---@param HeroID number @要查询的英雄 ID
---@return HeroUI
function HeroSelectionManager:GetUGCHeroUIData(HeroID)
    return HeroSelectionManagerImpl:GetUGCHeroUIData(HeroID)
end

---获取所有英雄技能标签数据
---生效范围：客户端、服务器
---@return HeroAbilityLabel[]
function HeroSelectionManager:GetAllUGCHeroAbilityLabelData()
    return HeroSelectionManagerImpl:GetAllUGCHeroAbilityLabelData()
end

---获取单个英雄的技能标签数据，如果不传入 ID 默认使用当前正在聚焦的英雄 ID
---生效范围：客户端、服务器
---@param HeroID number @要查询的英雄 ID
---@return HeroAbilityLabel
function HeroSelectionManager:GetUGCHeroAbilityLabelData(HeroID)
    return HeroSelectionManagerImpl:GetUGCHeroAbilityLabelData(HeroID)
end

---获取所有英雄限免配置数据
---生效范围：客户端、服务器
---@return HeroFreeConfig[]
function HeroSelectionManager:GetAllUGCHeroFreeConfigData()
    return HeroSelectionManagerImpl:GetAllUGCHeroFreeConfigData()
end

---获取单个英雄限免配置数据
---生效范围：客户端、服务器
---@param HeroID number @要查询的英雄 ID
---@return HeroFreeConfig
function HeroSelectionManager:GetUGCHeroFreeConfigData(HeroID)
    return HeroSelectionManagerImpl:GetUGCHeroFreeConfigData(HeroID)
end

---获取所有用于显示的英雄数据
---生效范围：客户端、服务器
---@return Hero[]
function HeroSelectionManager:GetDisplayedHeroDataList()
    return HeroSelectionManagerImpl:GetDisplayedHeroDataList()
end

---获取第一个在英雄选择中显示且永久免费的英雄 ID
---生效范围：客户端&服务器
---@return number
function HeroSelectionManager:GetFirstAvailableHeroID()
    return HeroSelectionManagerImpl:GetFirstAvailableHeroID()
end

---获取英雄数量
---生效范围：客户端、服务器
---@return number
function HeroSelectionManager:GetHeroNum()
    return HeroSelectionManagerImpl:GetHeroNum()
end

---查询购买所需货币全部信息
---生效范围：客户端、服务器
---@param HeroID number @要查询的英雄 ID
---@return HeroCoinInfo
function HeroSelectionManager:GetHeroPurchaseInfo(HeroID)
    return HeroSelectionManagerImpl:GetHeroPurchaseInfo(HeroID)
end

---获取当前聚焦的英雄 ID
---生效范围：客户端、服务器
---@return number
function HeroSelectionManager:GetCurrentFocusedHeroID()
    return HeroSelectionManagerImpl:GetCurrentFocusedHeroID()
end

---获取当前选择的英雄 ID
---生效范围：客户端&服务器
---@param PlayerKey number @要查询的玩家 Key
---@return number
function HeroSelectionManager:GetSelectedHeroID(PlayerKey)
    return HeroSelectionManagerImpl:GetSelectedHeroID(PlayerKey)
end

---获取英雄技能标签数据大小
---生效范围：客户端&服务器
---@param HeroID number @要查询的英雄 ID
---@return number
function HeroSelectionManager:GetUGCHeroAbilityLabelDataSize(HeroID)
    return HeroSelectionManagerImpl:GetUGCHeroAbilityLabelDataSize(HeroID)
end

---------------------------------------------------------------------------------
--- 状态查询 API

---英雄是否可以被选择，不传入任何英雄 ID 默认采用当前界面聚焦的英雄
---生效范围：客户端，服务器
---@param HeroID number @要查询的英雄 ID
---@return boolean
function HeroSelectionManager:IsHeroCanSelect(HeroID)
    return HeroSelectionManagerImpl:IsHeroCanSelect(HeroID)
end

---英雄是否免费（包括永久免费和限免）
---生效范围：客户端，服务器
---@param HeroID number @要查询的英雄 ID
---@return boolean
function HeroSelectionManager:IsHeroFree(HeroID)
    return HeroSelectionManagerImpl:IsHeroFree(HeroID)
end

---英雄是否限免
---生效范围：客户端，服务器
---@param HeroID number @要查询的英雄 ID
---@return boolean
function HeroSelectionManager:IsHeroTimeLimitedFree(HeroID)
    return HeroSelectionManagerImpl:IsHeroTimeLimitedFree(HeroID)
end

---英雄是否永久免费
---生效范围：客户端，服务器
---@param HeroID number @要查询的英雄 ID
---@return boolean
function HeroSelectionManager:IsHeroPermanentFree(HeroID)
    return HeroSelectionManagerImpl:IsHeroPermanentFree(HeroID)
end

---英雄是否需要解锁
---生效范围：客户端，服务器
---@param HeroID number @要查询的英雄 ID
---@return boolean
function HeroSelectionManager:IsHeroLocked(HeroID)
    return HeroSelectionManagerImpl:IsHeroLocked(HeroID)
end

---英雄是否已购买
---生效范围：客户端，服务器
---@param HeroID number @要查询的英雄 ID
---@return boolean
function HeroSelectionManager:IsHeroPurchased(HeroID)
    return HeroSelectionManagerImpl:IsHeroPurchased(HeroID)
end

---购买英雄余额是否充足
---生效范围：客户端，服务器
---@param HeroID number @要查询的英雄 ID
---@return boolean
function HeroSelectionManager:IsHeroCanAfford(HeroID)
    return HeroSelectionManagerImpl:IsHeroCanAfford(HeroID)
end

---------------------------------------------------------------------------------
--- 交互功能 API


---打开英雄选择主界面
---生效范围：客户端
function HeroSelectionManager:OpenMainWidget()
    HeroSelectionManagerImpl:OpenMainWidget()
end

---关闭英雄选择主界面
---生效范围：客户端
function HeroSelectionManager:CloseMainWidget()
    HeroSelectionManagerImpl:CloseMainWidget()
end

---聚焦英雄
---生效范围：客户端
---@param HeroID number @要聚焦的英雄 ID
function HeroSelectionManager:FocusHero(HeroID)
    HeroSelectionManagerImpl:FocusHero(HeroID)
end

---选择英雄
---生效范围：客户端
---@param HeroID number @要选择的英雄 ID
function HeroSelectionManager:RequestSelectHero(PlayerKey, HeroID)
    HeroSelectionManagerImpl:RequestSelectHero(PlayerKey, HeroID)
end

---选择英雄
---生效范围：服务器
---@param PlayerKey number @PlayerKey
---@param HeroID number @要选择的英雄 ID
function HeroSelectionManager:SelectHero(PlayerKey, HeroID)
    HeroSelectionManagerImpl:SelectHero(PlayerKey, HeroID)
end

---购买英雄
---生效范围：客户端
---@param HeroID number @要购买的英雄 ID
function HeroSelectionManager:PurchaseHero(HeroID)
    HeroSelectionManagerImpl:PurchaseHero(HeroID)
end

---选择当前光标聚焦的英雄
---生效范围：客户端
function HeroSelectionManager:SelectCurrentFocusedHero()
    HeroSelectionManagerImpl:SelectCurrentFocusedHero()
end

---套用选择的英雄数据到玩家角色上
---生效范围：服务器
---@param PlayerKey number @玩家 Key
---@param HeroID number @英雄 ID，可选
function HeroSelectionManager:ApplySelectedHeroData(PlayerKey, HeroID)
    HeroSelectionManagerImpl:ApplySelectedHeroData(PlayerKey, HeroID)
end

--- End Public API --------------------------------------------------------------
---------------------------------------------------------------------------------

-- 只转发 function 的调用，隐藏 Implement 表中的内部成员
setmetatable(HeroSelectionManager, {
    __index = function(table, key)
        if HeroSelectionManagerImpl[key] and type(HeroSelectionManagerImpl[key]) == "function" then
            return HeroSelectionManagerImpl[key]
        end
        return nil
    end
})

return HeroSelectionManager
