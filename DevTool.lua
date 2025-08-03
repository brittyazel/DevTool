-- DevTool is a World of Warcraft® addon development tool.
-- Copyright (c) 2021-2025 Britt W. Yazel
-- Copyright (c) 2016-2021 Peter aka "Varren"
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace

---@class DevTool : AceAddon-3.0 @define The main addon object for the DevTool addon
addonTable.DevTool = LibStub("AceAddon-3.0"):NewAddon("DevTool", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local DevTool = addonTable.DevTool

--add global reference to the addon object
_G["DevTool"] = addonTable.DevTool

--store the colors outside the database in a class level table
DevTool.colors = {}
DevTool.colors["gray"] = CreateColorFromHexString("FFBEB9B5")
DevTool.colors["lightblue"] = CreateColorFromHexString("FF96C0CE")
DevTool.colors["lightgreen"] = CreateColorFromHexString("FF98FB98")
DevTool.colors["red"] = CreateColorFromHexString("FFFF0000")
DevTool.colors["green"] = CreateColorFromHexString("FF00FF00")
DevTool.colors["darkred"] = CreateColorFromHexString("FFC25B56")
DevTool.colors["parent"] = CreateColorFromHexString("FFBEB9B5")
DevTool.colors["error"] = CreateColorFromHexString("FFFF0000")
DevTool.colors["ok"] = CreateColorFromHexString("FF00FF00")

-- Holds the contents of the current view window.
DevTool.list = {}


-------------------------------------------------------------------------
--------------------Start of Functions-----------------------------------
-------------------------------------------------------------------------

--- Called directly after the addon is fully loaded.
--- We do initialization tasks here, such as loading our saved variables or setting up slash commands.
function DevTool:OnInitialize()

	self.db = LibStub("AceDB-3.0"):New("DevToolDatabase", self.DatabaseDefaults)
	
end

--- Called during the PLAYER_LOGIN event when most of the data provided by the game is already present.
--- We perform more startup tasks here, such as registering events, hooking functions, creating frames, or getting 
--- information from the game that wasn't yet available during :OnInitialize()
function DevTool:OnEnable()
	
	self:CreateChatCommands()

	self.MainWindow = CreateFrame("Frame", "DevToolFrame", UIParent, "DevToolMainFrame")

	--create the colors from the values stored in the database
	self.colors["table"] = CreateColor(unpack(self.db.profile.colorVals["table"]))
	self.colors["string"] = CreateColor(unpack(self.db.profile.colorVals["string"]))
	self.colors["number"] = CreateColor(unpack(self.db.profile.colorVals["number"]))
	self.colors["function"] = CreateColor(unpack(self.db.profile.colorVals["function"]))
	self.colors["default"] = CreateColor(unpack(self.db.profile.colorVals["default"]))

	self:LoadSettings()
	self:UpdateMainTableUI()
	self:UpdateSideBarUI()

	--register update scrollFrame
	self.MainWindow.scrollFrame.update = function()
		self:UpdateMainTableUI()
	end

	self.MainWindow.sideFrame.sideScrollFrame.update = function()
		self:UpdateSideBarUI()
	end

	local function chatFunction(message)
		if not message or message == "" then
			self:ToggleUI()
		else
			self:ExecuteCMD(message, true)
		end
	end

	self:RegisterChatCommand("dev", chatFunction)
	self:RegisterChatCommand("devtool", chatFunction)
	-- legacy command for muscle memory reasons
	self:RegisterChatCommand("vdt", chatFunction)

end

--- Called when our addon is manually being disabled during a running session.
--- We primarily use this to unhook scripts, unregister events, or hide frames that we created.
function DevTool:OnDisable()
	-- Empty --
end

-------------------------------------------------

function DevTool:CreateChatCommands()
	-- you can use "/dev find <some string> <parent name>" (can be in format _G.Frame.Button)
	-- for example "/dev find DevTool" will find every variable in _G that has *DevTool* pattern
	-- "/dev find Data DevTool" will find every variable that has *Data* in their name in _G.DevTool object if it exists
	-- same for "startswith"
	self.CMD = {
		--"/dev help"
		HELP = function()
			print(" ")
			self:Print("DevTool is a World of Warcraft® addon development tool.")
			self:Print("Available commands:")
			print(self.colors.lightblue:WrapTextInColorCode("/dev: ") .. "Show/Hide the DevTool interface")
			print(self.colors.lightblue:WrapTextInColorCode("/dev help: ") .. "Display help information in the chat window")
			print(self.colors.lightblue:WrapTextInColorCode("/dev <name> <parent (optional)>: ") .. "Add a table within _G or _G.parent to the list")
			print(self.colors.lightblue:WrapTextInColorCode("/dev find <part_of_name> <parent (optional)>: ") .. "Add tables containing this partial name within _G or _G.parent to the list")
			print(self.colors.lightblue:WrapTextInColorCode("/dev startswith <part_of_name> <parent (optional)>: ") .. "Add tables beginning with this partial name within _G or _G.parent to the list")
			print(self.colors.lightblue:WrapTextInColorCode("/dev eventadd <event> <unit (optional)>: ") .. "Add event or unit event to the list")
			print(self.colors.lightblue:WrapTextInColorCode("/dev eventstart <event> <unit (optional)>: ") .. "Begin monitoring this event or unit event")
			print(self.colors.lightblue:WrapTextInColorCode("/dev eventstop <event> <unit (optional)>: ") .. "Stop monitoring this event or unit event")
			print(self.colors.lightblue:WrapTextInColorCode("/dev logfn <function> <parent>: ") .. "Log all calls made to the function")
			print(self.colors.lightblue:WrapTextInColorCode("/dev mouseover: ") .. "Add the currently hovered frame to the list")
			print(self.colors.lightblue:WrapTextInColorCode("/dev reposition: ") .. "Reset the position of the DevTool window")
			print(" ")
			return

		end,

		FIND = function(message2, message3)
			local parent = message3 and DevTool.FromStrToObject(message3) or _G
			return DevTool.FindIn(parent, message2, string.match)
		end,

		STARTSWITH = function(message2, message3)
			local parent = message3 and DevTool.FromStrToObject(message3) or _G
			return DevTool.FindIn(parent, message2, DevTool.starts)
		end,

		EVENTADD = function(message2, message3)
			DevTool:StartMonitorEvent(message2, message3)
		end,

		EVENTSTART = function(message2, message3)
			DevTool:StartMonitorEvent(message2, message3)
		end,

		EVENTSTOP = function(message2, message3)
			DevTool:StopMonitorEvent(message2, message3)
		end,

		LOGFN = function(message2, message3)
			DevTool:StartLogFunctionCalls(message2, message3)
		end,

		MOUSEOVER = function()
			local focusedFrame
			--WoW 11.0 added GetMouseFoci() which now returns a table of frames in order of their on-screen stacking
			if GetMouseFoci then
				focusedFrame = GetMouseFoci()[1]
			else
				focusedFrame = GetMouseFocus()
			end
			return focusedFrame, focusedFrame:GetName()
		end,

		REPOSITION = function()
			self.MainWindow:ClearAllPoints()
			self.MainWindow:SetPoint("CENTER", UIParent)
			self.MainWindow:SetSize(750, 400)
		end
	}
end

-----------------------------------------------------------------------------------------------
--- LIFECYCLE
-----------------------------------------------------------------------------------------------

function DevTool:LoadSettings()
	-- setup open or closed main window
	if self.db.profile.isWndOpen then
		self.MainWindow:Show()
	end

	-- setup open or closed sidebar
	if self.db.profile.isSideBarOpen then
		self.MainWindow.sideFrame:Show()
	end

	-- setup selected sidebar tab history/events/logs
	self:EnableSideBarTab(self.db.profile.sideBarTabSelected)

	-- setup logs. Just disable all of them for now on startup
	for _, tLog in pairs(self.db.profile.logs) do
		tLog.active = false
	end

	-- setup events part 1 register listeners
	for _, tEvent in pairs(self.db.profile.events) do
		if tEvent.active then
			self:StartMonitorEvent(tEvent.event, tEvent.unit)
		end
	end

	-- show in UI fn saved args if you have them
	local args = ""
	local delim = ""
	for _, arg in pairs(self.db.profile.tArgs) do
		args = tostring(arg) .. delim .. args
		delim = ", "
	end

	self.MainWindow.editbox:SetText(args)

	-- setup events part 2 set scripts on frame to listen registered events
	self:SetMonitorEventScript()

	--we store colors not in saved settings for now
	if self.db.profile.colorVals then
		for k, v in pairs(self.db.profile.colorVals) do
			self.colors[k]:SetRGBA(unpack(v))
		end
	end

	self:LoadInterfaceOptions()

	self:ResizeColumn(true)
end

-----------------------------------------------------------------------------------------------
--- DevTool main
-----------------------------------------------------------------------------------------------

--- The main (and the only) function you can use in DevTool API
--- Adds data to the list so you can explore its values in UI list
--- @param data <any type> - is object you would like to track.
--- Default behavior is shallow copy
--- @param dataName <string or nil> - name tag to show in UI for you variable.
function DevTool:AddData(data, dataName)
	-- If the data is nil, print an error and abort
	if not data then
		self:Print("Error: The data being added does not exist. Aborting.")
		return
	end

	if not dataName then
		dataName = tostring(data)
	end

	if not self.list then
		print("Error: DevTool list is not fully initialized. Please try again later in the loading process. Aborting.")
	end

	table.insert(self.list, self:NewElement(data, tostring(dataName)))
	self:UpdateMainTableUI()
end

function DevTool:NewElement(data, dataName, indentation, parent)
	return {
		name = dataName,
		value = data,
		indentation = indentation == nil and 0 or indentation,
		parent = parent or self.list
	}
end

function DevTool:ClearAllData()
	table.wipe(self.list)
	collectgarbage("collect")
	self:UpdateMainTableUI()
end

function DevTool:ExpandCell(info)
	local elementList = {}
	local indentation = info.indentation + 1
	local metatable
	for k, v in pairs(info.value) do
		if type(v) ~= "userdata" then
			table.insert(elementList, self:NewElement(v, tostring(k), indentation, info))
		else
			metatable = getmetatable(v)
			if metatable then
				table.insert(elementList, self:NewElement(metatable, "$metatable for " .. tostring(k), indentation, info))
			else
				if k ~= 0 then
					table.insert(elementList, self:NewElement(v, "$metatable not found for " .. tostring(k), indentation, info))
				end
			end
		end
	end

	metatable = getmetatable(info.value)
	if metatable and type(metatable) == "table" then
		table.insert(elementList, self:NewMetatableElement(metatable, indentation, info))
	end

	--this is a somewhat hacky safety check to make sure we don't overwhelm the UI with too many elements
	--checks to see if the current list + the new elements is more than 5% larger than the total number of elements in _G
	--do this check before the sort to not waste cycles unnecessarily
	if #elementList + #self.list >= DevTool.CountElements(_G) * 1.05 then
		self:Print("ExpandCell: Too many elements in table. Aborting")
		return
	end

	table.sort(elementList, DevTool.SelectSortFunction(#elementList))

	local parentIndex = DevTool.FindIndex(self.list, info)
	for i, element in ipairs(elementList) do
		table.insert(self.list, parentIndex + i, element)
	end

	info.expanded = true

	self:UpdateMainTableUI()
end

function DevTool:CollapseCell(info)
	local parentIndex = DevTool.FindIndex(self.list, info)
	local endIndex
	for i = parentIndex + 1, #self.list do
		if self.list[i].indentation > info.indentation then
			endIndex = i
		else
			break
		end
	end

	--loop backwards as it is WAY faster to remove from the end first
	if endIndex then
		for i = endIndex, parentIndex + 1, -1 do
			table.remove(self.list, i)
		end
	end

	info.expanded = nil
	self:UpdateMainTableUI()
end

function DevTool:NewMetatableElement(metatable, indentation, info)
	if #metatable == 1 and metatable.__index then
		return self:NewElement(metatable.__index, "$metatable.__index", indentation, info)
	else
		return self:NewElement(metatable, "$metatable", indentation, info)
	end
end

function DevTool:ExecuteCMD(message, bAddToHistory)
	if message == "" then
		message = "_G"
	end
	local resultTable

	local messages = DevTool.split(message, " ")
	local command = self.CMD[string.upper(messages[1])]

	if command then
		local title
		resultTable, title = command(messages[2], messages[3])

		if title then
			message = title
		end
	else
		resultTable = DevTool.FromStrToObject(message)
		if not resultTable then
			self:Print("Cannot find " .. "_G." .. message)
		end
	end

	if resultTable then
		if bAddToHistory then
			DevTool:AddToHistory(message)
		end

		self:AddData(resultTable, message)
	end
end

-----------------------------------------------------------------------------------------------
--- UI
-----------------------------------------------------------------------------------------------
function DevTool:ToggleUI()
	if not self.MainWindow:IsVisible() then
		self.MainWindow:Show()
		self.db.profile.isWndOpen = true
	else
		self.MainWindow:Hide()
		self.db.profile.isWndOpen = false
	end

	if self.db.profile.isWndOpen then
		self:UpdateMainTableUI()
		self:UpdateSideBarUI()
	else
		--just in case a timer slipped through
		self:CancelAllTimers()
	end
end

function DevTool:ResizeUpdateTick()
	self:ResizeMainFrame()
	self:ResizeColumn()
	self:UpdateMainTableUI()
	self:UpdateSideBarUI()
end

function DevTool:ColumnResizeUpdateTick()
	self:ResizeColumn()
	self:UpdateMainTableUI()
	self:UpdateSideBarUI()
end

-- I do manual resizing and not the default
-- self:GetParent():StartSizing("BOTTOMRIGHT");
-- self:GetParent():StopMovingOrSizing();
-- Because I don't like default behaviour. --Varren
function DevTool:ResizeMainFrame()
	local left = self.MainWindow:GetLeft()
	local top = self.MainWindow:GetTop()

	-- Pin the top left corner of the main window in place so we only resize from the bottom right corner
	self.MainWindow:ClearAllPoints()
	self.MainWindow:SetPoint("TOPLEFT", nil, "TOPLEFT", left, (-1 * (UIParent:GetHeight() - top)))

	local x, y = GetCursorPosition()
	local s = self.MainWindow:GetEffectiveScale()
	x = x / s
	y = y / s

	local minX, minY, maxX, maxY

	if self.MainWindow.SetResizeBounds then
		-- WoW 10.0
		minX, minY, maxX, maxY = self.MainWindow:GetResizeBounds()
	else
		maxX, maxY = self.MainWindow:GetMaxResize()
		minX, minY = self.MainWindow:GetMinResize()

	end

	self.MainWindow:SetSize(DevTool.CalculatePosition(x - left, minX, maxX), DevTool.CalculatePosition(top - y, minY, maxY))
end

function DevTool:ResizeColumn(firstRun)
	if not firstRun then
		-- 150 and 50 are just const values. safe to change
		local minWidth = 100
		local maxWidth = self.MainWindow:GetWidth() - 150

		local width = self.MainWindow:GetRight() - self.MainWindow.columnResizer:GetRight()
		width = DevTool.CalculatePosition(width, minWidth, maxWidth)

		-- save pos so we can restore it on reload ui or logout
		self.db.profile.collResizeWidth = width
	end

	self.MainWindow.columnResizer:ClearAllPoints()
	-- -30 is vertical offset from above (top buttons)
	self.MainWindow.columnResizer:SetPoint("TOPRIGHT", self.MainWindow, "TOPRIGHT", self.db.profile.collResizeWidth * -1, -30)
end

-----------------------------------------------------------------------------------------------
--- Main table UI
-----------------------------------------------------------------------------------------------
function DevTool:UpdateMainTableUI()
	if not self.MainWindow or not self.MainWindow:IsVisible() then
		return
	end

	self:AddScrollFrameButtons(self.MainWindow.scrollFrame, "DevToolEntryTemplate")
	self:UpdateScrollFrameRowSize(self.MainWindow.scrollFrame)

	local offset = HybridScrollFrame_GetOffset(self.MainWindow.scrollFrame)
	local totalRowsCount = #self.list

	local counter = 1
	for k, button in pairs(self.MainWindow.scrollFrame.buttons) do
		local linePlusOffset = k + offset;
		if linePlusOffset <= totalRowsCount and (k - 1) * self.MainWindow.scrollFrame.buttons[1]:GetHeight() <
				self.MainWindow.scrollFrame:GetHeight() then
			self:UIUpdateMainTableButton(button, self.list[offset + counter], linePlusOffset)
			counter = counter + 1
			button:Show();
		else
			button:Hide();
		end
	end

	HybridScrollFrame_Update(self.MainWindow.scrollFrame, totalRowsCount *
			self.MainWindow.scrollFrame.buttons[1]:GetHeight() + 10, self.MainWindow.scrollFrame:GetHeight());

	self.MainWindow.scrollFrame.scrollChild:SetWidth(self.MainWindow.scrollFrame:GetWidth())
end

function DevTool:UpdateScrollFrameRowSize(scrollFrame)
	local currFontSize = self.db.profile.fontSize or 10

	local cellHeight = currFontSize + currFontSize * 0.2
	cellHeight = cellHeight % 2 == 0 and cellHeight or cellHeight + 1
	for _, button in pairs(scrollFrame.buttons) do
		button:SetHeight(cellHeight)
		local font = button.nameButton:GetFontString():GetFont()
		button.nameButton:GetFontString():SetFont(font, currFontSize)
		button.rowNumberButton:GetFontString():SetFont(font, currFontSize)
		button.valueButton:GetFontString():SetFont(font, currFontSize)
	end

	scrollFrame.buttonHeight = cellHeight
end

function DevTool:AddScrollFrameButtons(scrollFrame, strTemplate)
	if not scrollFrame.ScrollBarHeight or scrollFrame:GetHeight() > scrollFrame.ScrollBarHeight then
		scrollFrame.ScrollBarHeight = scrollFrame:GetHeight()
		HybridScrollFrame_CreateButtons(scrollFrame, strTemplate, 0, -2)
		scrollFrame.scrollBar:SetValue(scrollFrame.scrollBar:GetValue());
	end
end

function DevTool:UIUpdateMainTableButton(element, info, id)
	local color = self.colors[type(info.value)]
	if not color then
		color = self.colors.default
	end
	if type(info.value) == "table" and DevTool.IsMetaTableNode(info) then
		color = self.colors.default
	end

	element.nameButton:SetPoint("LEFT", element.rowNumberButton, "RIGHT", 10 * info.indentation - 10, 0)

	element.valueButton:SetText(DevTool.ToUIString(info.value, info.name, true))
	element.nameButton:SetText(tostring(info.name))
	element.rowNumberButton:SetText(tostring(id))

	element.nameButton:GetFontString():SetTextColor(color:GetRGBA())
	element.valueButton:GetFontString():SetTextColor(color:GetRGBA())
	element.rowNumberButton:GetFontString():SetTextColor(color:GetRGBA())

	self:SetMainTableButtonScript(element.nameButton, info)
	self:SetMainTableButtonScript(element.valueButton, info)
end

-----------------------------------------------------------------------------------------------
--- Sidebar UI
-----------------------------------------------------------------------------------------------
function DevTool:ToggleSidebar()
	if not self.MainWindow.sideFrame:IsVisible() then
		self.MainWindow.sideFrame:Show()
		self.db.profile.isSideBarOpen = true
	else
		self.MainWindow.sideFrame:Hide()
		self.db.profile.isSideBarOpen = false
	end
	self:UpdateSideBarUI()
end

function DevTool:SubmitEditBoxSidebar()
	local selectedTab = self.db.profile.sideBarTabSelected
	local command = self.MainWindow.sideFrame.editbox:GetText()

	if selectedTab == "logs" then
		command = "logfn " .. command
	elseif selectedTab == "events" then
		command = "eventadd " .. command
	end

	self:ExecuteCMD(command, true)
	self:UpdateSideBarUI()
end

function DevTool:EnableSideBarTab(tabStrName)
	--Update ui
	local sidebar = self.MainWindow.sideFrame
	sidebar.history:SetChecked(false)
	sidebar.events:SetChecked(false)
	sidebar.logs:SetChecked(false)
	sidebar[tabStrName]:SetChecked(true)

	-- update selected tab  and function to update cell items
	self.db.profile.sideBarTabSelected = tabStrName

	-- refresh ui
	self:UpdateSideBarUI()
end

function DevTool:UpdateSideBarUI()
	self:AddScrollFrameButtons(self.MainWindow.sideFrame.sideScrollFrame, "DevToolSideBarRowTemplate")

	local offset = HybridScrollFrame_GetOffset(self.MainWindow.sideFrame.sideScrollFrame)
	local data = self.db.profile[self.db.profile.sideBarTabSelected]
	local totalRowsCount = #data

	for k, button in pairs(self.MainWindow.sideFrame.sideScrollFrame.buttons) do
		local linePlusOffset = k + offset;

		if linePlusOffset <= totalRowsCount and k * self.MainWindow.sideFrame.sideScrollFrame.buttons[1]:GetHeight() <
				self.MainWindow.sideFrame.sideScrollFrame:GetHeight() then
			self:UpdateSideBarRow(button.mainButton, data, linePlusOffset)

			--setup remove button for every row
			button.actionButton:SetScript("OnMouseUp", function()
				table.remove(data, linePlusOffset)
				self:UpdateSideBarUI()
			end)
			button:Show();
		else
			button:Hide();
		end
	end

	HybridScrollFrame_Update(self.MainWindow.sideFrame.sideScrollFrame,
			totalRowsCount * self.MainWindow.sideFrame.sideScrollFrame.buttons[1]:GetHeight(),
			self.MainWindow.sideFrame.sideScrollFrame:GetHeight());
end

function DevTool:UpdateSideBarRow(view, data, linePlusOffset)
	local selectedTab = self.db.profile.sideBarTabSelected

	local currItem = data[linePlusOffset]

	if selectedTab == "history" then
		-- history update
		local name = tostring(currItem)
		view:SetText(name)
		view:SetScript("OnMouseUp", function()
			DevTool:ExecuteCMD(name)
			--move this item to the top of the list
			table.remove(data, linePlusOffset)
			table.insert(data, 1, currItem)
			DevTool:UpdateSideBarUI()
		end)

	elseif selectedTab == "logs" then
		local text = self:LogFunctionCallText(currItem)
		if currItem.active then
			view:SetText(text)
		else
			view:SetText(text .. " (stopped)")
		end

		-- logs update
		view:SetScript("OnMouseUp", function()
			DevTool:ToggleFnLogger(currItem)
			DevTool:UpdateSideBarUI()
		end)

	elseif selectedTab == "events" then
		local name = currItem.event
		local unit = currItem.unit

		--set label to be the name
		local label = name

		--append a unit to the label if one exists
		if unit then
			label = label .. self.colors.lightblue:WrapTextInColorCode(" (" .. unit .. ")")
		end

		--append a 'stopped' tag to the label if the event is not active
		if not currItem.active then
			label = label .. self.colors.red:WrapTextInColorCode(" (stopped)")
		end

		view:SetText(label)

		-- events  update
		view:SetScript("OnMouseUp", function()
			DevTool:ToggleMonitorEvent(currItem)
			DevTool:UpdateSideBarUI()
		end)
	end
end

-----------------------------------------------------------------------------------------------
-- Main table row button clicks setup
-----------------------------------------------------------------------------------------------
function DevTool:SetMainTableButtonScript(button, info)
	local valueType = type(info.value)
	local leftClickFn = function()
	end

	if valueType == "table" then
		leftClickFn = function()
			if info.expanded then
				self:CollapseCell(info)
			else
				self:ExpandCell(info)
			end
		end
	elseif valueType == "function" then
		leftClickFn = function()
			self:TryCallFunction(info)
		end
	end

	button:SetScript("OnMouseUp", function(this, mouseButton, down)
		if mouseButton == "RightButton" then
			local nameButton = this:GetParent().nameButton
			local valueButton = this:GetParent().valueButton
			DevTool:Print(nameButton:GetText() .. " - " .. valueButton:GetText())
		else
			leftClickFn(this, mouseButton, down)
		end
	end)
end

function DevTool:TryCallFunction(info)
	-- info.value is just our function to call
	local parent = DevTool.GetParentTable(info)
	local fn = info.value
	local args = { unpack(self.db.profile.tArgs) }
	for k, v in pairs(args) do
		if type(v) == "string" and v == "t=self" then
			if not parent then
				local ok, results = false, { "t=self set as argument, but no parent table exists" }
				return self:ProcessCallFunctionData(ok, info, parent, args, results)
			end
			args[k] = parent and parent.value
		elseif type(v) == "string" and DevTool.starts(v, "t=") then
			local obj = DevTool.FromStrToObject(string.sub(v, 3))
			if obj then
				args[k] = obj
			end
		end
	end

	-- lets try safe call first
	local ok, results = DevTool.TryCallFunctionWithArgs(fn, args)

	if not ok and parent and args[1] ~= parent then
		-- if safe call failed we probably could try to find self and call self:fn(), but only if user didn't explicitly specify t=self already
		args = { parent.value, unpack(args) } --shallow copy and add parent table
		ok, results = DevTool.TryCallFunctionWithArgs(fn, args)
	end

	self:ProcessCallFunctionData(ok, info, parent, args, results)
end

-- this function is kinda hard to read but it just adds new items to list and prints log in chat.
-- will add 1 row for call result(ok or error) and 1 row for each return value
function DevTool:ProcessCallFunctionData(ok, info, parent, args, results)
	local elements = {}

	self:CollapseCell(info) -- if we already called this fn remove old results

	local indentation = info.indentation + 1

	local stateStr = function(state)
		if state then
			return self.colors.ok:WrapTextInColorCode("OK")
		end
		return self.colors.error:WrapTextInColorCode("ERROR")
	end

	--construct colored full function call name
	local fnNameWithArgs = info.name .. self.colors.lightblue:WrapTextInColorCode("(" .. DevTool.ArgsToString(args) .. ")")

	fnNameWithArgs = parent and self.colors.gray:WrapTextInColorCode(parent.name .. ":" .. fnNameWithArgs) or fnNameWithArgs

	local returnFormattedStr = ""

	-- iterate backwards because we want to include every meaningful nil result
	-- and with default iteration like pairs() we will just skip them so
	-- for example 1, 2, nil, 4 should return only this 4 values nothing more, nothing less.
	local found = false
	for i = 10, 1, -1 do
		if results[i] ~= nil then
			found = true
		end

		if found or i == 1 then
			-- if found some return or if return is nil
			table.insert(elements, self:NewElement(results[i], string.format("  return: %d", i), indentation))

			returnFormattedStr = string.format(" %s (%s)%s", tostring(results[i]),
					self.colors.lightblue:WrapTextInColorCode(type(results[i])), returnFormattedStr)
		end
	end

	-- create first element of result info no need for now. will use debug
	table.insert(elements, 1, self:NewElement(string.format("%s - %s", stateStr(ok), fnNameWithArgs), -- element value
			date("%X") .. " function call results:", indentation))

	-- adds call result to our UI list
	local parentIndex = DevTool.FindIndex(self.list, info)
	for i, element in ipairs(elements) do
		table.insert(self.list, parentIndex + i, element)
	end

	self:UpdateMainTableUI()

	--print info to chat
	self:Print(stateStr(ok) .. " " .. fnNameWithArgs .. self.colors.gray:WrapTextInColorCode(" returns:") .. returnFormattedStr)
end

-----------------------------------------------------------------------------------------------
--- BOTTOM PANEL Function Arguments button  and arguments input edit box
-----------------------------------------------------------------------------------------------
function DevTool:SetArgForFunctionCallFromString(argStr)
	local args = DevTool.split(argStr, ",") or {}

	local trim = function(s)
		return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
	end

	for k, arg in pairs(args) do

		arg = trim(arg)
		if tonumber(arg) then
			args[k] = tonumber(arg)
		elseif arg == "nil" then
			args[k] = nil
		elseif arg == "true" then
			args[k] = true
		elseif arg == "false" then
			args[k] = false
		end
	end

	self.db.profile.tArgs = args
	self:AddData(args, "New Args for function calls")
end
