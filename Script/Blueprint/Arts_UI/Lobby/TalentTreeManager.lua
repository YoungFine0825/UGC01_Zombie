UGCGameSystem.UGCRequire("Script.Blueprint.Arts_UI.Lobby.TalentTreeTypes")

---@type TalentTreeManagerImpl
local TalentTreeManagerImpl = UGCGameSystem.UGCRequire("Script.Blueprint.Arts_UI.Lobby.TalentTreeManagerImpl")

---@class TalentTreeManager
TalentTreeManager = {
    --- delegates
    OnMainWidgetOpened = TalentTreeManagerImpl.OnMainWidgetOpened, -- 打开了天赋树面板
    OnMainWidgetClosed = TalentTreeManagerImpl.OnMainWidgetClosed, -- 关闭了天赋树面板
    OnHeroSelected = TalentTreeManagerImpl.OnHeroSelected,          --> (HeroIdx) 点选某个英雄时触发
    OnTabSelected = TalentTreeManagerImpl.OnTabSelected,            --> (TabIdx) 点选某个页签时触发
    OnTalentSelected = TalentTreeManagerImpl.OnTalentSelected,      --> (TalentID) 点选某个天赋时触发
    OnTalentPointsUpdate = TalentTreeManagerImpl.OnTalentPointsUpdate,  --> (TalentPoints) 天赋点数更改时触发
    OnTalentInfoUpdate = TalentTreeManagerImpl.OnTalentInfoUpdate,      --> (TalentID, Level) 天赋信息有更新时触发
    OnButtonStatesUpdate = TalentTreeManagerImpl.OnButtonStatesUpdate,  --> (isPlus, ButtonStatus) 天赋按钮状态有更新时触发
}

--- Begin Public API ------------------------------------------------------------

function TalentTreeManager:Init(TalentTreeComponent)
    ugcprint("[TalentTree] TalentTreeManager:Init")
    return TalentTreeManagerImpl:Init(TalentTreeComponent)
end

--- UI API --------------------------------------------------------------------

--- 打开UI
function TalentTreeManager:OpenMainWidget()
    return TalentTreeManagerImpl:OpenMainWidget()
end

--- 关闭UI
function TalentTreeManager:CloseMainWidget()
    return TalentTreeManagerImpl:CloseMainWidget()
end

--- 打开天赋升级详情面板
function TalentTreeManager:OpenTalentTip(TalentID, IsUnlock)
    return TalentTreeManagerImpl:OpenTalentTip(TalentID, IsUnlock)
end

--- 关闭天赋升级详情面板
function TalentTreeManager:CloseTalentTip()
    return TalentTreeManagerImpl:CloseTalentTip()
end

--- 打开二次确认面板
function TalentTreeManager:OpenPopup(popupType)
    return TalentTreeManagerImpl:OpenPopup(popupType)
end

--- 关闭二次确认面板
function TalentTreeManager:ClosePopup()
    return TalentTreeManagerImpl:ClosePopup()
end

--- 选择英雄
function TalentTreeManager:SelectHero(HeroIdx)
    return TalentTreeManagerImpl:SelectHero(HeroIdx)
end

--- 选择天赋
function TalentTreeManager:SelectTalent(TalentID)
    return TalentTreeManagerImpl:SelectTalent(TalentID)
end

--- 选择天赋页签
function TalentTreeManager:SelectTab(TabIdx)
    return TalentTreeManagerImpl:SelectTab(TabIdx)
end

--- 更新天赋点
function TalentTreeManager:UpdateTalentPoints()
    return TalentTreeManagerImpl:UpdateTalentPoints()
end

--- 更新天赋信息
function TalentTreeManager:UpdateTalentInfo()
    return TalentTreeManagerImpl:UpdateTalentInfo()
end

--- 更新加点面板按钮状态
function TalentTreeManager:UpdateButtonState()
    return TalentTreeManagerImpl:UpdateButtonState()
end

--- 更新选中英雄
function TalentTreeManager:UpdateSelectedHero(HeroID)
    return TalentTreeManagerImpl:UpdateSelectedHero(HeroID)
end

--- 更新并缓存玩家引用(PlayerController, PlayerPawn, PlayerKey)
---@return boolean @所有引用都成功更新时返回true
--- 生效范围：客户端/服务端
function TalentTreeManager:UpdateCachedVariables()
    return TalentTreeManagerImpl:UpdateCachedVariables()
end
--- UI API end --------------------------------------------------------------------

--- Gameplay API --------------------------------------------------------------------
--- 升级天赋
function TalentTreeManager:UpgradeTalent(TalentID)
    return TalentTreeManagerImpl:UpgradeTalent(TalentID)
end

--- 天赋减点
function TalentTreeManager:ReduceTalent(TalentID)
    return TalentTreeManagerImpl:ReduceTalent(TalentID)
end

--- 重置当前界面的天赋
function TalentTreeManager:ResetTalent(TalentCategoryID)
    return TalentTreeManagerImpl:ResetTalent(TalentCategoryID)
end

--- 确认升级天赋操作
function TalentTreeManager:ConfirmChanges(TalentID)
    return TalentTreeManagerImpl:ConfirmChanges(TalentID)
end

--- 取消不可重置类别增加的天赋等级
function TalentTreeManager:CancelChanges()
    return TalentTreeManagerImpl:CancelChanges()
end

--- 为指定玩家或者所有玩家添加天赋点
---@param TalentPoints number @添加的天赋点数
---@param TargetPlayerKey number|nil @（可选）目标玩家PlayerKey (nil表示所有玩家，仅服务端为nil时会加到所有玩家身上）
--- 生效范围：客户端/服务端
function TalentTreeManager:AddTalentPoints(TalentPoints, PlayerKey)
    return TalentTreeManagerImpl:AddTalentPoints(TalentPoints, PlayerKey)
end

--- Gameplay API end --------------------------------------------------------------------

--- Data API --------------------------------------------------------------------

---应用单个天赋到Pawn上
function TalentTreeManager:ApplyTalents(TalentDataParams, TalentID, InPawnObj)
    return TalentTreeManagerImpl:ApplyTalents(TalentDataParams, TalentID, InPawnObj)
end

---应用指定英雄的技能
---生效范围：服务端
function TalentTreeManager:ApplySelectedHeroSkill(HeroID)
    return TalentTreeManagerImpl:ApplySelectedHeroSkill(HeroID)
end

---获取单个天赋的数据，TalentID支持传入int32索引值
function TalentTreeManager:GetTalentDataByTalentID(TalentID)
    return TalentTreeManagerImpl:GetTalentDataByTalentID(TalentID)
end

---获取单个页签的数据，CategoryID支持传入int32索引值
function TalentTreeManager:GetCategoryDataByCategoryID(CategoryID)
    return TalentTreeManagerImpl:GetCategoryDataByCategoryID(CategoryID)
end

---返回TalentDataMap
function TalentTreeManager:GetTalentDataMap()
    return TalentTreeManagerImpl:GetTalentDataMap()
end

---获取所有英雄的信息
function TalentTreeManager:GetUGCHeroDataMap()
    return TalentTreeManagerImpl:GetUGCHeroDataMap()
end

---获取所有天赋页签的信息
function TalentTreeManager:GetTalentCategoryDataMap()
    return TalentTreeManagerImpl:GetTalentCategoryDataMap()
end

---通过HeroID获取该英雄的数据
function TalentTreeManager:GetHeroDataByHeroID(HeroID)
    return TalentTreeManagerImpl:GetHeroDataByHeroID(HeroID)
end

---通过CategoryID获取对应页签的所有天赋ID
function TalentTreeManager:GetTalentIDsByCategoryID(CategoryID)
    return TalentTreeManagerImpl:GetTalentIDsByCategoryID(CategoryID)
end

---通过列表Idx获取英雄数据
function TalentTreeManager:GetHeroDataByIdx(Idx)
    return TalentTreeManagerImpl:GetHeroDataByIdx(Idx)
end

---通过列表Idx获取类别数据
function TalentTreeManager:GetCategoryDataByIdx(Idx)
    return TalentTreeManagerImpl:GetCategoryDataByIdx(Idx)
end

---通过CategoryID和列表Idx获取该类别Idx层包含的天赋ID，层数，如果没有传Idx则返回所有的天赋
function TalentTreeManager:GetLayerTalentIDs(CategoryID, Idx)
    return TalentTreeManagerImpl:GetLayerTalentIDs(CategoryID, Idx)
end

---通过CategoryID和列表Idx获取该类别Idx层包含的天赋数据，层数，如果没有传Idx则返回所有天赋数据
function TalentTreeManager:GetLayerTalentData(CategoryID, Idx)
    return TalentTreeManagerImpl:GetLayerTalentData(CategoryID, Idx)
end

--- 通过CategoryID获取该类别的层级数据,返回一个包含每一层LimitParameter、TalentIDs、层描述Description和解锁描述UnlockDescription的表
function TalentTreeManager:GetLayerData(CategoryID)
    return TalentTreeManagerImpl:GetLayerData(CategoryID)
end

--- 获取类别的层数解锁状态
function TalentTreeManager:GetUnlockState(CategoryID, Idx)
    return TalentTreeManagerImpl:GetUnlockState(CategoryID, Idx)
end

--- 获取Component
function TalentTreeManager:GetTalentTreeComponent(PlayerController)
    return TalentTreeManagerImpl:GetTalentTreeComponent(PlayerController)
end

--- 注册Component类型
function TalentTreeManager:RegisterTalentTreeComponentClass(CompClass)
    return TalentTreeManagerImpl:RegisterTalentTreeComponentClass(CompClass)
end

--- 获取天赋点
function TalentTreeManager:GetTalentPoints()
    return TalentTreeManagerImpl:GetTalentPoints()
end

--- 是否有可用的天赋点，大厅红点用
function TalentTreeManager:HasAvailableTalentPoints()
    return TalentTreeManagerImpl:HasAvailableTalentPoints()
end

--- 通过TalentID获取天赋等级
function TalentTreeManager:GetTalentLevel(TalentID)
    return TalentTreeManagerImpl:GetTalentLevel(TalentID)
end

--- 获取当前选中的TabIdx
function TalentTreeManager:GetSelectedTabIdx()
    return TalentTreeManagerImpl:GetSelectedTabIdx()
end

--- 获取当前选中的英雄Idx
function TalentTreeManager:GetSelectedHeroIdx()
    return TalentTreeManagerImpl:GetSelectedHeroIdx()
end

--- 获取等级和天赋点对应的表
function TalentTreeManager:GetTalentPointsByLevel()
    return TalentTreeManagerImpl:GetTalentPointsByLevel()
end

--- 检查指定英雄的天赋是否包含技能配置
--- 生效范围：客户端\服务端
function TalentTreeManager:HasTalentSkillsForHero(HeroID)
    return TalentTreeManagerImpl:HasTalentSkillsForHero(HeroID)
end

--- 检查当前天赋等级是否大于打开Tip时的初始等级
function TalentTreeManager:HasAdditionalPoints(TalentID)
    return TalentTreeManagerImpl:HasAdditionalPoints(TalentID)
end

--- 保存打开Tip时的等级信息
function TalentTreeManager:SaveTempTalentInfo()
    return TalentTreeManagerImpl:SaveTempTalentInfo()
end

--- End Public API ------------------------------------------------------------

function TalentTreeManager:SubUTF8String(str, maxChars)
    return TalentTreeManagerImpl:SubUTF8String(str, maxChars)
end

--- 弹提示框
function TalentTreeManager:ShowNotice(FailureReason)
    return TalentTreeManagerImpl:ShowNotice(FailureReason)
end