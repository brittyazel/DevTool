-- DevTool is a World of Warcraft® addon development tool.
-- Copyright (c) 2021-2025 Britt W. Yazel
-- Copyright (c) 2016-2021 Peter aka "Varren"
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace
local DevTool = addonTable.DevTool

-----------------------------------------------------------------------------------------------
--- EVENTS
-----------------------------------------------------------------------------------------------
function DevTool:GetListenerFrame()
	if not self.listenerFrame then
		self.listenerFrame = CreateFrame("Frame", "DevToolListenerFrame", UIParent);
	end
	return self.listenerFrame
end

function DevTool:StartMonitorEvent(event, unit)
	if not event then
		return
	end

	--handle to event in database
	local tEvent = self:GetMonitoredEvent(event, unit)

	if not tEvent then
		tEvent = { event = event, unit = unit, active = true }
		table.insert(self.db.profile.events, tEvent)
	end

	local frame = self:GetListenerFrame()

	local result = true

	if tEvent.event == "ALL" then
		frame:RegisterAllEvents()
	elseif tEvent.unit then
		--safety in case event doesn't exist
		result = pcall(frame.RegisterUnitEvent, frame, tEvent.event, tEvent.unit);
		if not result then
			self:Print("Failed to register event: " .. self.colors.lightblue:WrapTextInColorCode(tEvent.event .. " " .. tEvent.unit))
		end
	else
		--safety in case event doesn't exist
		result = pcall(frame.RegisterEvent, frame, tEvent.event);
		if not result then
			self:Print("Failed to register event: " .. self.colors.lightblue:WrapTextInColorCode(tEvent.event))
		end
	end

	--if event doesn't exist, we need to remove it from the database and the sidebar list
	if not result then
		for i, thisEvent in pairs(self.db.profile.events) do
			if thisEvent.event == event and unit and thisEvent.unit == unit then
				table.remove(self.db.profile.events, i)
				break
			elseif thisEvent.event == event and not unit then
				table.remove(self.db.profile.events, i)
				break
			end
		end
		return
	else
		--set event to active (tEvent is a handle to the database entry)
		tEvent.active = true
	end

	--refresh our sidebar view for any status changes
	self:UpdateSideBarUI()

	local eventName = tEvent.event
	if tEvent.unit then
		eventName = eventName .. " " .. tostring(tEvent.unit)
	end
	self:Print(self.colors.green:WrapTextInColorCode("Start") .. " event monitoring: " ..
			self.colors.lightblue:WrapTextInColorCode(eventName))
end

function DevTool:StopMonitorEvent(event, unit)
	if not event then
		return
	end
	local tEvent = self:GetMonitoredEvent(event, unit)

	if tEvent and tEvent.active then
		local frame = self:GetListenerFrame()
		tEvent.active = false
		if tEvent.event == "ALL" then
			frame:UnregisterAllEvents()
			for _, thisEvent in pairs(self.db.profile.events) do
				if thisEvent.active then
					self:StartMonitorEvent(thisEvent.event, thisEvent.unit)
				end
			end
		else
			frame:UnregisterEvent(tEvent.event)
		end

		--refresh our sidebar view for any status changes
		self:UpdateSideBarUI()

		local eventName = tEvent.event
		if tEvent.unit then
			eventName = eventName .. " " .. tostring(tEvent.unit)
		end

		self:Print(self.colors.red:WrapTextInColorCode("Stop") .. " event monitoring: " ..
				self.colors.lightblue:WrapTextInColorCode(eventName))
	end
end

function DevTool:ToggleMonitorEvent(tEvent)
	if tEvent then
		if tEvent.active then
			self:StopMonitorEvent(tEvent.event, tEvent.unit)
		else
			self:StartMonitorEvent(tEvent.event, tEvent.unit)
		end
	end
end

function DevTool:SetMonitorEventScript()
	local f = self:GetListenerFrame()

	f:SetScript("OnEvent", function(_, ...)
		local args = { ... }
		local event = args[1]
		local unit
		if #args > 1 and type(args[2]) == "string" and string.find(event, "UNIT") then
			unit = args[2]
		end

		--In 9.0 Blizzard removed the payload from COMBAT_LOG_EVENT_UNFILTERED
		--Intercept this event and manually query the info
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			args = { event, CombatLogGetCurrentEventInfo() }
		end

		local showAllEvents = self:GetMonitoredEvent("ALL")
		if self:GetMonitoredEvent(event, unit) or (showAllEvents and showAllEvents.active) then
			local data
			if #args == 1 then
				data = args[1]
			else
				data = args
			end

			if unit then
				self:AddData(data, date("%X") .. " " .. event .. self.colors.gray:WrapTextInColorCode(" (" .. unit .. ")"))
			else
				self:AddData(data, date("%X") .. " " .. event)
			end
		end
	end);
end

function DevTool:GetMonitoredEvent(event, unit)
	if not self.db.profile.events then
		return
	end

	for _, thisEvent in pairs(self.db.profile.events) do

		if thisEvent.event == event and not thisEvent.unit then
			return thisEvent
		elseif thisEvent.event == event and thisEvent.unit and unit and thisEvent.unit == unit then
			return thisEvent
		end
	end
end
