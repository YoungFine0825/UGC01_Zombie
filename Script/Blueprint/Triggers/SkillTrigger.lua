---@class SkillTrigger_C:AActor
---@field Widget UWidgetComponent
---@field Box UBoxComponent
---@field Cube UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
---@field PESkill UClass
---@field TitleText FString
--Edit Below--
local SkillTrigger = {}
 
function SkillTrigger:SetTitleText(TitleTxt)
    self.Widget.Widget.TextBlock_Title:SetText(TitleTxt)
end

function SkillTrigger:ReceiveBeginPlay()
    SkillTrigger.SuperClass.ReceiveBeginPlay(self)

	if UGCGameSystem.IsServer() then
        self.Box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self)
    else
        self:SetTitleText(self.TitleText)
    end

end

function SkillTrigger:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
	-- if STExtraBlueprintFunctionLibrary.IsDedicatedServer(self) then
	if UGCGameSystem.IsServer() then
		ugcprint("SkillTrigger Log: Box_OnComponentBeginOverlap")
		local State = OtherActor:GetPlayerPersistClientState();
		if State then
			State:ApplyPersistEffectDataByClass(self.PESkill,-1.0);
		end
	end
	
	return nil;
end

function SkillTrigger:ReceiveEndPlay()
    SkillTrigger.SuperClass.ReceiveEndPlay(self) 

end

return SkillTrigger