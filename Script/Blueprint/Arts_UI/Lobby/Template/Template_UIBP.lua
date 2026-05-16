---@class Template_UIBP_C : UUserWidget

---模板 UIBP，不要在此添加逻辑

---@type Template_UIBP_C
local Template_UIBP = {}

---默认的 UI 构造函数
function Template_UIBP:Construct()
end

---默认的 UI 析构函数
function Template_UIBP:Destruct()
end

---打开此 UI 时会调用，可添加自定义 Payload 传递数据
---@see LobbyUtils.OpenWidget
function Template_UIBP:OnOpen(...)
end

---关闭此 UI 时会调用
---@see LobbyUtils.CloseWidget
function Template_UIBP:OnClose()
end

---更新时会调用，可添加自定义 Payload 传递数据
---@see LobbyUtils.UpdateWidget
function Template_UIBP:OnUpdate(...)
end

return Template_UIBP