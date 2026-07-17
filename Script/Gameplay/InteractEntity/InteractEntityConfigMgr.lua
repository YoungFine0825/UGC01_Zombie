---@class Gameplay.InteractEntityConfigMgr
local InteractEntityConfigMgr = LuaClass("Gameplay.InteractEntityConfigMgr")

local TABLE_PATH = 'Asset/Data/Table/InteractEntity/DT_InteractEntitiesConfig.DT_InteractEntitiesConfig'
local TABLE_UI_PATH = 'Asset/Data/Table/InteractEntity/DT_InteractEntitiesUIScheme.DT_InteractEntitiesUIScheme'

local EMPTY_ARRAY = {}

function InteractEntityConfigMgr:Ctor()
    ---@type table|boolean|nil  nil=未加载, false=加载失败, table=已加载
    self.m_rawTable = nil
    ---@type table|boolean|nil
    self.m_rawUITable = nil
    ---@type table<number, Struct_InteractEntityConfig>  InteractConfigID → 配置行
    self.m_configByID = {}
    ---@type table<number, Struct_InteractEntityConfig[]>  BehaviourType → 配置行数组
    self.m_configsByBehaviourType = {}
    ---@type table<number, Struct_InteractEntityUIScheme>  InteractConfigID → UI方案配置行
    self.m_uiSchemeByID = {}
end

---@private 按需加载原始 DataTable, 失败后不重试
---@return table|boolean
function InteractEntityConfigMgr:EnsureTableLoaded()
    if self.m_rawTable ~= nil then
        return self.m_rawTable
    end
    local fullPath = UGCGameSystem.GetUGCResourcesFullPath(TABLE_PATH)
    local raw = UGCGameSystem.GetTableData(fullPath)
    if not raw then
        GameplayUtils.Exception("[InteractEntityConfigMgr] 配置表加载失败: " .. TABLE_PATH)
        self.m_rawTable = false
        return false
    end
    self.m_rawTable = raw
    return raw
end

-- ====================== 查询接口 ======================

---@public 根据 InteractConfigID 获取单条配置
---@param configID number
---@return Struct_InteractEntityConfig|nil
function InteractEntityConfigMgr:GetByConfigID(configID)
    local cached = self.m_configByID[configID]
    if cached then
        return cached
    end
    local raw = self:EnsureTableLoaded()
    if not raw then
        return nil
    end
    for _, row in pairs(raw) do
        if row.InteractConfigID == configID then
            self.m_configByID[configID] = row
            return row
        end
    end
    return nil
end

---@public 获取全部配置(按 InteractConfigID 索引)
---@return table<number, Struct_InteractEntityConfig>
function InteractEntityConfigMgr:GetAll()
    local raw = self:EnsureTableLoaded()
    if not raw then
        return {}
    end
    for _, row in pairs(raw) do
        if row.InteractConfigID and not self.m_configByID[row.InteractConfigID] then
            self.m_configByID[row.InteractConfigID] = row
        end
    end
    return self.m_configByID
end

-- ====================== UI方案配置 ======================

---@private
---@return table|boolean
function InteractEntityConfigMgr:EnsureUITableLoaded()
    if self.m_rawUITable ~= nil then
        return self.m_rawUITable
    end
    local fullPath = UGCGameSystem.GetUGCResourcesFullPath(TABLE_UI_PATH)
    local raw = UGCGameSystem.GetTableData(fullPath)
    if not raw then
        GameplayUtils.Exception("[InteractEntityConfigMgr] UI方案配置表加载失败: " .. TABLE_UI_PATH)
        self.m_rawUITable = false
        return false
    end
    self.m_rawUITable = raw
    return raw
end

---@public 根据 InteractConfigID 获取UI方案配置
---@param configID number
---@return Struct_InteractEntityUIScheme|nil
function InteractEntityConfigMgr:GetUISchemeByConfigID(configID)
    local cached = self.m_uiSchemeByID[configID]
    if cached then
        return cached
    end
    local raw = self:EnsureUITableLoaded()
    if not raw then
        return nil
    end
    for _, row in pairs(raw) do
        if row.ID == configID then
            self.m_uiSchemeByID[configID] = row
            return row
        end
    end
    return nil
end

-- ====================== 生命周期 ======================

function InteractEntityConfigMgr:BeginPlayOnServer()
end

function InteractEntityConfigMgr:BeginPlayOnClient()
end

function InteractEntityConfigMgr:EndPlayOnServer()
    self:Clear()
end

function InteractEntityConfigMgr:EndPlayOnClient()
    self:Clear()
end

---@public
function InteractEntityConfigMgr:Clear()
    self.m_rawTable = nil
    self.m_rawUITable = nil
    self.m_configByID = {}
    self.m_configsByBehaviourType = {}
    self.m_uiSchemeByID = {}
end

return InteractEntityConfigMgr
