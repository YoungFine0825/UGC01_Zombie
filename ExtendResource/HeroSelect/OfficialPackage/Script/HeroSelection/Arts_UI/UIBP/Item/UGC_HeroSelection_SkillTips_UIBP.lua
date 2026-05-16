---@class UGC_HeroSelection_SkillTips_UIBP_C:UUserWidget
---@field Button_Close UButton
---@field SkillPanel UCanvasPanel
---@field Text_Skill_Name UTextBlock
---@field TextBlock_Skill_Explain UTextBlock
--Edit Below--
local Delegate = UGCGameSystem.UGCRequire("common.Delegate")


local UGC_HeroSelection_SkillTips_UIBP = {
    bInitDoOnce = false,
    OnCloseClicked = Delegate.New()
}


function UGC_HeroSelection_SkillTips_UIBP:Construct()
	self:LuaInit();
end

function UGC_HeroSelection_SkillTips_UIBP:SetData(Data)
    if Data then
        self.Data = Data
    else
        ugcprint('[HeroSelection] UGC_HeroSelection_SkillTips_UIBP:SetData() Data is nil')
        return
    end

    self.Text_Skill_Name:SetText(self.Data.Name)
    self.TextBlock_Skill_Explain:SetText(self.Data.Detail)
end

function UGC_HeroSelection_SkillTips_UIBP:SetParent(Parent)
    self.Parent = Parent
end

-- [Editor Generated Lua] function define Begin:
function UGC_HeroSelection_SkillTips_UIBP:LuaInit()
    if self.bInitDoOnce then
        return;
    end
    self.bInitDoOnce = true;
    -- [Editor Generated Lua] BindingProperty Begin:
    -- [Editor Generated Lua] BindingProperty End;

    -- [Editor Generated Lua] BindingEvent Begin:
    self.Button_Close.OnClicked:Add(self.Button_Close_OnClicked, self)
    -- [Editor Generated Lua] BindingEvent End;
end

function UGC_HeroSelection_SkillTips_UIBP:Button_Close_OnClicked()
    self.OnCloseClicked()
end

-- [Editor Generated Lua] function define End;

function UGC_HeroSelection_SkillTips_UIBP:SetPosition()
    local Pos = { X = 0.0, Y = 0.0 }
    local ParentPos = { X = 0.0, Y = 0.0 }
    local MinPadding = 8
    local ParentGeometry = self.Parent:GetCachedGeometry()
    local ViewportGeometry = UGCWidgetManagerSystem.GetViewportWidgetGeometry()
    local TipGeometry = self.SkillPanel:GetCachedGeometry()
    local ParentSize = SlateBlueprintLibrary.GetLocalSize(ParentGeometry)
    local TipSize = { X = 213.0, Y = 140.0 } -- SlateBlueprintLibrary.GetLocalSize(TipGeometry)
    local ViewportSize = SlateBlueprintLibrary.GetLocalSize(ViewportGeometry)
    local ViewportScale = UGCWidgetManagerSystem.GetViewportScale(self)

    ParentPos.X = UGCWidgetManagerSystem.GetAbsolutePosition(ParentGeometry).X
    ParentPos.Y = UGCWidgetManagerSystem.GetAbsolutePosition(ParentGeometry).Y
    Pos.X = UGCWidgetManagerSystem.AbsoluteToLocal(ViewportGeometry, ParentPos).X
    Pos.Y = UGCWidgetManagerSystem.AbsoluteToLocal(ViewportGeometry, ParentPos).Y

    Pos.X = Pos.X + (ParentSize.X * ViewportScale) + MinPadding

    -- 只处理左下
    local UIRectOffsetStrArray = string.split(Client.GetUIRectOffset(), ',')
    local OffsetLeft = tonumber(UIRectOffsetStrArray[1])
    local OffsetBottom = tonumber(UIRectOffsetStrArray[4])
    local MinX = OffsetLeft
    local MaxY = ViewportSize.Y - OffsetBottom - MinPadding

    self.SkillPanel:ForceLayoutPrepass()

    -- 左侧显示位置大于 MinX，并且大于 Item 格子的宽度
     if Pos.X < MinX then
         Pos.X = MinX
     end

    -- 处理超出底部的问题
    if Pos.Y + TipSize.Y > MaxY then
        Pos.Y = MaxY - TipSize.Y
    end

    self.SkillPanel.Slot:SetPosition(Pos)
end

return UGC_HeroSelection_SkillTips_UIBP
