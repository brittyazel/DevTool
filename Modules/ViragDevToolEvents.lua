local ViragDevTool = ViragDevTool

-----------------------------------------------------------------------------------------------
-- EVENTS
-----------------------------------------------------------------------------------------------
function ViragDevTool:GetListenerFrame()
    if (self.listenerFrame == nil) then
        self.listenerFrame = CreateFrame("Frame", "ViragDevToolListenerFrame", UIParent);
    end
    return self.listenerFrame
end

function ViragDevTool:StartMonitorEvent(event, unit)
    if not event then return end

    local tEvent = self:GetMonitoredEvent(event, unit)

    if not tEvent then
        tEvent = { event = event, unit = unit, active = true }
        table.insert(self.db.profile.events, tEvent)
    end

    local f = self:GetListenerFrame()

    if event == "ALL" then
        f:RegisterAllEvents()
    elseif type(unit) == "string" then
        f:RegisterUnitEvent(event, unit)
    else
        f:RegisterEvent(event)
    end

    tEvent.active = true

    local eventName = event
    if unit then eventName = eventName .. " " .. tostring(unit) end
    self:Print(self.colors.green:WrapTextInColorCode("Start") ..
            " event monitoring: " ..
            self.colors.lightblue:WrapTextInColorCode(eventName))
end

function ViragDevTool:StopMonitorEvent(event, unit)
    if not event then return end
    local tEvent = self:GetMonitoredEvent(event, unit)

    if tEvent and tEvent.active then
        local f = self:GetListenerFrame()
        tEvent.active = false
        if event == "ALL"  then
            f:UnregisterAllEvents()
            for _, thisEvent in pairs(self.db.profile.events) do
                if thisEvent.active then
                    self:StartMonitorEvent(thisEvent.event, thisEvent.unit)
                end
            end
        else
            f:UnregisterEvent(event)
        end

        local eventName = event
        if unit then eventName = eventName .. " " .. tostring(unit) end

        self:Print(self.colors.red:WrapTextInColorCode("Stop") ..
                " event monitoring: " ..
                self.colors.lightblue:WrapTextInColorCode(eventName))
    end
end

function ViragDevTool:ToggleMonitorEvent(tEvent)
    if tEvent then
        if tEvent.active then
            self:StopMonitorEvent(tEvent.event, tEvent.unit)
        else
            self:StartMonitorEvent(tEvent.event, tEvent.unit)
        end
    end
end

function ViragDevTool:SetMonitorEventScript()
    local f = self:GetListenerFrame()

    f:SetScript("OnEvent", function(_, ...)
        local args = { ... }
        local event = args[1]

        local showAllEvents = ViragDevTool:GetMonitoredEvent("ALL")
        if ViragDevTool:GetMonitoredEvent(event) or (showAllEvents and showAllEvents.active) then
            if #args == 1 then args = args[1] end
            ViragDevTool:Add(args, date("%X") .. " " .. event)
        end
    end);
end

function ViragDevTool:GetMonitoredEvent(event)

    if self.db.profile.events == nil then
        return
    end

    local found

    for _, tEvent in pairs(self.db.profile.events) do
        if tEvent.event == event then
            found = tEvent
            break
        end
    end

    if found then
        return found
    end
end
