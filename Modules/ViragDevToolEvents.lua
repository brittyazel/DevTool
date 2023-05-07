-- DevTool is a World of Warcraft® addon development tool.
-- Copyright (c) 2021-2023 Britt W. Yazel
-- Copyright (c) 2016-2021 Peter Varren
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace
local ViragDevTool = addonTable.ViragDevTool

-----------------------------------------------------------------------------------------------
--- EVENTS
-----------------------------------------------------------------------------------------------
function ViragDevTool:GetListenerFrame()
	if not self.listenerFrame then
		self.listenerFrame = CreateFrame("Frame", "ViragDevToolListenerFrame", UIParent);
	end
	return self.listenerFrame
end

function ViragDevTool:StartMonitorEvent(event, unit)
	if not event then
		return
	end

	local tEvent = self:GetMonitoredEvent(event, unit)

	if not tEvent then
		tEvent = { event = event, unit = unit, active = true }
		table.insert(self.db.profile.events, tEvent)
	end

	local frame = self:GetListenerFrame()

	if event == "ALL" then
		frame:RegisterAllEvents()
	elseif type(unit) == "string" then
		frame:RegisterUnitEvent(event, unit)
	else
		frame:RegisterEvent(event)
	end

	tEvent.active = true

	local eventName = event
	if unit then
		eventName = eventName .. " " .. tostring(unit)
	end
	self:Print(self.colors.green:WrapTextInColorCode("Start") ..
			" event monitoring: " ..
			self.colors.lightblue:WrapTextInColorCode(eventName))
end

function ViragDevTool:StopMonitorEvent(event, unit)
	if not event then
		return
	end
	local tEvent = self:GetMonitoredEvent(event, unit)

	if tEvent and tEvent.active then
		local frame = self:GetListenerFrame()
		tEvent.active = false
		if event == "ALL" then
			frame:UnregisterAllEvents()
			for _, thisEvent in pairs(self.db.profile.events) do
				if thisEvent.active then
					self:StartMonitorEvent(thisEvent.event, thisEvent.unit)
				end
			end
		else
			frame:UnregisterEvent(event)
		end

		local eventName = event
		if unit then
			eventName = eventName .. " " .. tostring(unit)
		end

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

		--In 9.0 Blizzard removed the payload from COMBAT_LOG_EVENT_UNFILTERED
		--Intercept this event and manually query the info
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			args = { event, CombatLogGetCurrentEventInfo() }
		end

		local showAllEvents = self:GetMonitoredEvent("ALL")
		if self:GetMonitoredEvent(event) or (showAllEvents and showAllEvents.active) then
			if #args == 1 then
				args = args[1]
			end
			self:AddData(args, date("%X") .. " " .. event)
		end
	end);
end

function ViragDevTool:GetMonitoredEvent(event)
	if not self.db.profile.events then
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
