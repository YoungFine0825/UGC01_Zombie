EUITag = EUITag or
{
    SignInEvent = 0;
}

UIManager = UIManager or {
    UIList = {};
}

UGCGameSystem.UGCRequire("ExtendResource.ShopV2.OfficialPackage." .. "Script.Common.Common");
print("Create UIManager.lua");

---创建UI
---@param UIClassPath FSoftClassPath
---@param UITag EUIType
function UIManager:CreateUI(UIClassPath, UITag, ZOrder)

    local UIClass = Common.GetClassWithSoftPath(UIClassPath);

    if UIClass == nil or UGCGameSystem.GameState == nil then
        return;
    end

    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    local UI = UserWidget.NewWidgetObjectBP(PlayerController, UIClass);

    if self.UIList[UITag] == nil then
        self.UIList[UITag] = UI
        self.UIList[UITag]:AddToViewport(ZOrder);
        self.UIList[UITag]:SetVisibility(ESlateVisibility.Collapsed);
    else
        print("UIManager:CreateUI Failed, UI is Exist!");
    end
    
    return self.UIList[UITag];
end

---打开UI
---@param UITag EUIType
function UIManager:OpenUI(UITag)
    --- 不存在则创建、已存在则显示
    if self.UIList[UITag] == nil then
        print("UIManager:ShowUI Failed, UI is Nil!");
        return;
    end

    self.UIList[UITag]:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
end

---关闭UI
---@param UITag EUIType
function UIManager:CloseUI(UITag)
    if self.UIList[UITag] == nil then
        print("UIManager:HideUI Failed, UI is Nil!");
        return;
    end

    self.UIList[UITag]:SetVisibility(ESlateVisibility.Collapsed);
end

---通过名称获取UI
---@param UIType EUIType
function UIManager:GetUIByTag(UITag)
    if self.UIList[UITag] == nil then
        print("UIManager:GetUIByName Failed, UI is Nil!");
        return nil;
    end

    return self.UIList[UITag];
end

---判断UI是否存在
---@param UITag EUIType
function UIManager:CheckUIExist(UITag)
    if self.UIList[UITag] == nil then
        return false;  
    else
        return true;
    end
end
