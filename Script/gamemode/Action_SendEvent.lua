local Action_SendEvent = 
{
	SendEventName = "";
}


function Action_SendEvent:Execute()
    ugcprint(string.format("Action_SendEvent:Execute SendEventName[%s]", self.SendEventName));

    UGCGameSystem.SendModeCustomEvent(self.SendEventName);

    return true;
end


return Action_SendEvent