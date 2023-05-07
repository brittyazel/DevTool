-- DevTool is a World of Warcraft® addon development tool.
-- Copyright (c) 2021-2023 Britt W. Yazel
-- Copyright (c) 2016-2021 Peter Varren
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace

---@class ViragDevTool : AceAddon-3.0 @define The main addon object for the ViragDevTool addon
addonTable.ViragDevTool = LibStub("AceAddon-3.0"):NewAddon("ViragDevTool", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local ViragDevTool = addonTable.ViragDevTool

--add global reference to the addon object
_G["ViragDevTool"] = addonTable.ViragDevTool

--store the colors outside the database in a class level table
ViragDevTool.colors = {}
ViragDevTool.colors["gray"] = CreateColorFromHexString("FFBEB9B5")
ViragDevTool.colors["lightblue"] = CreateColorFromHexString("FF96C0CE")
ViragDevTool.colors["lightgreen"] = CreateColorFromHexString("FF98FB98")
ViragDevTool.colors["red"] = CreateColorFromHexString("FFFF0000")
ViragDevTool.colors["green"] = CreateColorFromHexString("FF00FF00")
ViragDevTool.colors["darkred"] = CreateColorFromHexString("FFC25B56")
ViragDevTool.colors["parent"] = CreateColorFromHexString("FFBEB9B5")
ViragDevTool.colors["error"] = CreateColorFromHexString("FFFF0000")
ViragDevTool.colors["ok"] = CreateColorFromHexString("FF00FF00")


-------------------------------------------------------------------------
--------------------Start of Functions-----------------------------------
-------------------------------------------------------------------------

--- **OnInitialize**, which is called directly after the addon is fully loaded.
--- do init tasks here, like loading the Saved Variables
--- or setting up slash commands.
function ViragDevTool:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ViragDevToolDatabase", self.DatabaseDefaults)
end

--- **OnEnable** which gets called during the PLAYER_LOGIN event, when most of the data provided by the game is already present.
--- Do more initialization here, that really enables the use of your addon.
--- Register Events, Hook functions, Create Frames, Get information from
--- the game that wasn't available in OnInitialize
function ViragDevTool:OnEnable()
	self.list = {}

	self:CreateChatCommands()

	self.MainWindow = CreateFrame("Frame", "ViragDevToolFrame", UIParent, "ViragDevToolMainFrame")

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

	self:RegisterChatCommand("vdt", function(message)
		if not message or message == "" then
			self:ToggleUI()
		else
			self:ExecuteCMD(message, true)
		end
	end)

end

--- **OnDisable**, which is only called when your addon is manually being disabled.
--- Unhook, Unregister Events, Hide frames that you created.
--- You would probably only use an OnDisable if you want to
--- build a "standby" mode, or be able to toggle modules on/off.
function ViragDevTool:OnDisable()

end

-------------------------------------------------

function ViragDevTool:CreateChatCommands()
	-- you can use "/vdt find <some string> <parent name>" (can be in format _G.Frame.Button)
	-- for example "/vdt find Virag" will find every variable in _G that has *Virag* pattern
	-- "/vdt find Data ViragDevTool" will find every variable that has *Data* in their name in _G.ViragDevTool object if it exists
	-- same for "startswith"
	self.CMD = {
		--"/vdt help"
		HELP = function()

			local a = function(txt)
				return WrapTextInColorCode(txt, "FF96C0CE")
			end
			local a2 = function(txt)
				return WrapTextInColorCode(txt, "FFBEB9B5")
			end
			local a3 = function(txt)
				return WrapTextInColorCode(txt, "FF3cb371")
			end

			local cFix = function(str)
				local result = WrapTextInColorCode(str, "FFFFFFFF")
				result = string.gsub(result, "name", a("name"))
				result = string.gsub(result, "eventName", a("eventName"))
				result = string.gsub(result, "tableName", a("tableName"))

				result = string.gsub(result, "parent", a2("parent"))
				result = string.gsub(result, "unit", a2("unit"))
				result = string.gsub(result, "functionName", a2("functionName"))

				result = string.gsub(result, "help", a3("help"))
				result = string.gsub(result, "find", a3("find"))
				result = string.gsub(result, "startswith", a3("startswith"))
				result = string.gsub(result, "eventadd", a3("eventadd"))
				result = string.gsub(result, "eventstop", a3("eventstop"))
				result = string.gsub(result, "logfn", a3("logfn"))
				result = string.gsub(result, "mouseover", a3("mouseover"))
				result = string.gsub(result, "reposition", a3("reposition"))
				return result
			end

			print(cFix("/vdt") .. " - " .. cFix("Toggle UI"))
			print(cFix("/vdt help") .. " - " .. cFix("Print help"))
			print(cFix("/vdt name parent (optional)") .. " - " .. cFix("Add _G.name or _G.parent.name to the list (ex: /vdt name A.B => _G.A.B.name"))
			print(cFix("/vdt find name parent (optional)") .. " - " .. cFix("Add name _G.*name* to the list. Adds any field name that has name part in its name"))
			print(cFix("/vdt mouseover") .. " - " .. cFix("Add hoovered frame to the list with  GetMouseFocus()"))
			print(cFix("/vdt startswith name parent (optional)") .. " - " .. cFix("Same as find but will look only for name*"))
			print(cFix("/vdt eventadd eventName unit (optional)") .. " - " .. cFix("ex: /vdt eventadd UNIT_AURA player"))
			print(cFix("/vdt eventstop eventName") .. " - " .. cFix("Stops event monitoring if active"))
			print(cFix("/vdt logfn tableName functionName (optional)") .. " - " .. cFix("Log every function call. _G.tableName.functionName"))
			print(cFix("/vdt reposition") .. " - " .. cFix("Reset main frame position if you lost it for some reason"))

			return ""

		end,
		-- "/vdt find Data ViragDevTool" or "/vdt find Data"
		FIND = function(message2, message3)
			local parent = message3 and ViragDevTool.FromStrToObject(message3) or _G
			return ViragDevTool.FindIn(parent, message2, string.match)
		end,
		--"/vdt startswith Data ViragDevTool" or "/vdt startswith Data"
		STARTSWITH = function(message2, message3)
			local parent = message3 and ViragDevTool.FromStrToObject(message3) or _G
			return ViragDevTool.FindIn(parent, message2, ViragDevTool.starts)
		end,
		--"/vdt mouseover" --m stands for mouse focus
		MOUSEOVER = function()
			local resultTable = GetMouseFocus()
			return resultTable, resultTable:GetName()
		end,
		--"/vdt eventadd ADDON_LOADED"
		EVENTADD = function(message2, message3)
			ViragDevTool:StartMonitorEvent(message2, message3)
		end,
		--"/vdt eventremove ADDON_LOADED"
		EVENTSTOP = function(message2, message3)
			ViragDevTool:StopMonitorEvent(message2, message3)
		end,
		--"/vdt log tableName fnName" tableName in global namespace and fnName in table
		LOGFN = function(message2, message3)
			ViragDevTool:StartLogFunctionCalls(message2, message3)
		end,
		--"/vdt reposition"
		REPOSITION = function()
			self.MainWindow:ClearAllPoints()
			self.MainWindow:SetPoint("CENTER", UIParent)
			self.MainWindow:SetSize(635, 400)
		end
	}
end

-----------------------------------------------------------------------------------------------
--- LIFECYCLE
-----------------------------------------------------------------------------------------------

function ViragDevTool:LoadSettings()
	-- setup open or closed main window
	self:SetVisible(self.MainWindow, self.db.profile.isWndOpen)

	-- setup open or closed sidebar
	self:SetVisible(self.MainWindow.sideFrame, self.db.profile.isSideBarOpen)

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

	self.MainWindow.columnResizer:SetPoint("TOPRIGHT", self.MainWindow, "TOPRIGHT",
			self.db.profile.collResizerPosition * -1, -30) -- 30 is offset from above (top buttons)
end

-----------------------------------------------------------------------------------------------
--- ViragDevTool main
-----------------------------------------------------------------------------------------------

--- The main (and the only) function you can use in ViragDevTool API
--- Adds data to the list so you can explore its values in UI list
--- @param data <any type> - is object you would like to track.
--- Default behavior is shallow copy
--- @param dataName <string or nil> - name tag to show in UI for you variable.
function ViragDevTool:AddData(data, dataName)
	if not dataName then
		dataName = tostring(data)
	end

	table.insert(self.list, self:NewElement(data, tostring(dataName)))

	self:UpdateMainTableUI()
end

function ViragDevTool:NewElement(data, dataName, indentation, parent)
	return {
		name = dataName,
		value = data,
		indentation = indentation == nil and 0 or indentation,
		parent = parent or self.list
	}
end

function ViragDevTool:ExecuteCMD(message, bAddToHistory)
	if message == "" then
		message = "_G"
	end
	local resultTable

	local messages = ViragDevTool.split(message, " ")
	local command = self.CMD[string.upper(messages[1])]

	if command then
		local title
		resultTable, title = command(messages[2], messages[3])

		if title then
			message = title
		end
	else
		resultTable = ViragDevTool.FromStrToObject(message)
		if not resultTable then
			self:Print("Cannot find " .. "_G." .. message)
		end
	end

	if resultTable then
		if bAddToHistory then
			ViragDevTool:AddToHistory(message)
		end

		self:AddData(resultTable, message)
	end
end

function ViragDevTool:ClearData()
	table.wipe(self.list)
	collectgarbage("collect")
	self:UpdateMainTableUI()
end

function ViragDevTool:ExpandCell(info)
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
	if metatable then
		table.insert(elementList, self:NewMetatableElement(metatable, indentation, info))
	end

	--this is a somewhat hacky safety check to make sure we don't overwhelm the UI with too many elements
	--checks to see if the current list + the new elements is more than 5% larger than the total number of elements in _G
	--do this check before the sort to not waste cycles unnecessarily
	if #elementList + #self.list >= ViragDevTool.CountElements(_G) * 1.05 then
		self:Print("ExpandCell: Too many elements in table. Aborting")
		return
	end

	table.sort(elementList, ViragDevTool.SelectSortFunction(#elementList))

	local parentIndex = ViragDevTool.FindIndex(self.list, info)
	for i, element in ipairs(elementList) do
		table.insert(self.list, parentIndex + i, element)
	end

	info.expanded = true

	self:UpdateMainTableUI()
end

function ViragDevTool:NewMetatableElement(metatable, indentation, info)
	if type(metatable) == "table" then
		if #metatable == 1 and metatable.__index then
			return self:NewElement(metatable.__index, "$metatable.__index", indentation, info)
		else
			return self:NewElement(metatable, "$metatable", indentation, info)
		end
	end
end

function ViragDevTool:CollapseCell(info)
	local parentIndex = ViragDevTool.FindIndex(self.list, info)
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

-----------------------------------------------------------------------------------------------
-- UI
-----------------------------------------------------------------------------------------------
function ViragDevTool:ToggleUI()
	self:Toggle(self.MainWindow)
	self.db.profile.isWndOpen = self.MainWindow:IsVisible()
	if self.db.profile.isWndOpen then
		self:UpdateMainTableUI()
		self:UpdateSideBarUI()
	else
		--just in case a timer slipped through
		self:CancelAllTimers()
	end
end

function ViragDevTool:Toggle(view)
	self:SetVisible(view, not view:IsVisible())
end

function ViragDevTool:SetVisible(view, isVisible)
	if not view then
		return
	end

	if isVisible then
		view:Show()
	else
		view:Hide()
	end
end

function ViragDevTool:ResizeUpdateTick()
	self:ResizeMainFrame()
	self:DragResizeColumn()
	self:UpdateMainTableUI()
	self:UpdateSideBarUI()
end

function ViragDevTool:ColumnResizeUpdateTick()
	self:DragResizeColumn()
	self:UpdateMainTableUI()
	self:UpdateSideBarUI()
end

-- I do manual resizing and not the default
-- self:GetParent():StartSizing("BOTTOMRIGHT");
-- self:GetParent():StopMovingOrSizing();
-- Because I don't like default behaviour. --Varren
function ViragDevTool:ResizeMainFrame()
	local left = self.MainWindow:GetLeft()
	local top = self.MainWindow:GetTop()

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

	self.MainWindow:SetSize(ViragDevTool.CalculatePosition(x - left, minX, maxX),
			ViragDevTool.CalculatePosition(top - y, minY, maxY))
end

function ViragDevTool:DragResizeColumn()
	-- 150 and 50 are just const values. safe to change
	local minFromRight = 100
	local maxFromRight = self.MainWindow:GetWidth() - 150

	local posFromRight = self.MainWindow:GetRight() - self.MainWindow.columnResizer:GetRight()
	posFromRight = ViragDevTool.CalculatePosition(posFromRight, minFromRight, maxFromRight)

	self.MainWindow.columnResizer:ClearAllPoints()
	self.MainWindow.columnResizer:SetPoint("TOPRIGHT", self.MainWindow, "TOPRIGHT", posFromRight * -1, -30) -- 30 is offset from above (top buttons)

	-- save pos so we can restore it on reload ui or logout
	self.db.profile.collResizerPosition = posFromRight
end

-----------------------------------------------------------------------------------------------
-- Main table UI
-----------------------------------------------------------------------------------------------
function ViragDevTool:UpdateMainTableUI()
	if not self.MainWindow or not self.MainWindow.scrollFrame:IsVisible() then
		return
	end

	self:ScrollBar_AddChildren(self.MainWindow.scrollFrame, "ViragDevToolEntryTemplate")
	self:UpdateScrollFrameRowSize(self.MainWindow.scrollFrame)


	local offset = HybridScrollFrame_GetOffset(self.MainWindow.scrollFrame)
	local totalRowsCount = #self.list

	local counter = 1
	for k, button in pairs(self.MainWindow.scrollFrame.buttons) do
		local linePlusOffset = k + offset;
		if linePlusOffset <= totalRowsCount and (k - 1) * self.MainWindow.scrollFrame.buttons[1]:GetHeight() <
				self.MainWindow.scrollFrame:GetHeight() then
			self:UIUpdateMainTableButton(button, self.list[offset+counter], linePlusOffset)
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

function ViragDevTool:UpdateScrollFrameRowSize(scrollFrame)
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

function ViragDevTool:ScrollBar_AddChildren(scrollFrame, strTemplate)
	if not scrollFrame.ScrollBarHeight or scrollFrame:GetHeight() > scrollFrame.ScrollBarHeight then
		scrollFrame.ScrollBarHeight = scrollFrame:GetHeight()
		HybridScrollFrame_CreateButtons(scrollFrame, strTemplate, 0, -2)
		scrollFrame.scrollBar:SetValue(scrollFrame.scrollBar:GetValue());
	end
end

function ViragDevTool:UIUpdateMainTableButton(element, info, id)
	local color = self.colors[type(info.value)]
	if not color then
		color = self.colors.default
	end
	if type(info.value) == "table" and ViragDevTool.IsMetaTableNode(info) then
		color = self.colors.default
	end

	element.nameButton:SetPoint("LEFT", element.rowNumberButton, "RIGHT", 10 * info.indentation - 10, 0)

	element.valueButton:SetText(ViragDevTool.ToUIString(info.value, info.name, true))
	element.nameButton:SetText(tostring(info.name))
	element.rowNumberButton:SetText(tostring(id))

	element.nameButton:GetFontString():SetTextColor(color:GetRGBA())
	element.valueButton:GetFontString():SetTextColor(color:GetRGBA())
	element.rowNumberButton:GetFontString():SetTextColor(color:GetRGBA())

	self:SetMainTableButtonScript(element.nameButton, info)
	self:SetMainTableButtonScript(element.valueButton, info)
end

-----------------------------------------------------------------------------------------------
-- Sidebar UI
-----------------------------------------------------------------------------------------------
function ViragDevTool:ToggleSidebar()
	self:Toggle(self.MainWindow.sideFrame)
	self.db.profile.isSideBarOpen = self.MainWindow.sideFrame:IsVisible()
	self:UpdateSideBarUI()
end

function ViragDevTool:SubmitEditBoxSidebar()
	local edditBox = self.MainWindow.sideFrame.editbox
	local message = edditBox:GetText()
	local selectedTab = self.db.profile.sideBarTabSelected
	local command = message

	if selectedTab == "logs" then
		command = "logfn " .. message
	elseif selectedTab == "events" then
		command = "eventadd " .. message
	end

	self:ExecuteCMD(command, true)
	self:UpdateSideBarUI()
end

function ViragDevTool:EnableSideBarTab(tabStrName)
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

function ViragDevTool:UpdateSideBarUI()

	self:ScrollBar_AddChildren(self.MainWindow.sideFrame.sideScrollFrame, "ViragDevToolSideBarRowTemplate")

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

function ViragDevTool:UpdateSideBarRow(view, data, linePlusOffset)
	local selectedTab = self.db.profile.sideBarTabSelected

	local currItem = data[linePlusOffset]

	if selectedTab == "history" then
		-- history update
		local name = tostring(currItem)
		view:SetText(name)
		view:SetScript("OnMouseUp", function()
			ViragDevTool:ExecuteCMD(name)
			--move to top
			table.remove(data, linePlusOffset)
			table.insert(data, 1, currItem)
			ViragDevTool:UpdateSideBarUI()
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
			ViragDevTool:ToggleFnLogger(currItem)
			ViragDevTool:UpdateSideBarUI()
		end)

	elseif selectedTab == "events" then
		local name = tostring(currItem.event)
		view:SetText(name)
		if currItem.active then
			view:SetText(name)
		else
			view:SetText(name .. " (disabled)")
		end
		-- events  update
		view:SetScript("OnMouseUp", function()
			ViragDevTool:ToggleMonitorEvent(currItem)
			ViragDevTool:UpdateSideBarUI()
		end)
	end
end

-----------------------------------------------------------------------------------------------
-- Main table row button clicks setup
-----------------------------------------------------------------------------------------------
function ViragDevTool:SetMainTableButtonScript(button, info)
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
			ViragDevTool:Print(nameButton:GetText() .. " - " .. valueButton:GetText())
		else
			leftClickFn(this, mouseButton, down)
		end
	end)
end

function ViragDevTool:TryCallFunction(info)
	-- info.value is just our function to call
	local parent
	local fn = info.value
	local args = { unpack(self.db.profile.tArgs) }
	for k, v in pairs(args) do
		if type(v) == "string" and ViragDevTool.starts(v, "t=") then

			local obj = ViragDevTool.FromStrToObject(string.sub(v, 3))
			if obj then
				args[k] = obj
			end
		end
	end

	-- lets try safe call first
	local ok, results = ViragDevTool.TryCallFunctionWithArgs(fn, args)

	if not ok then
		-- if safe call failed we probably could try to find self and call self:fn()
		parent = ViragDevTool.GetParentTable(info)

		if parent then
			args = { parent.value, unpack(args) } --shallow copy and add parent table
			ok, results = ViragDevTool.TryCallFunctionWithArgs(fn, args)
		end
	end

	self:ProcessCallFunctionData(ok, info, parent, args, results)
end

-- this function is kinda hard to read but it just adds new items to list and prints log in chat.
-- will add 1 row for call result(ok or error) and 1 row for each return value
function ViragDevTool:ProcessCallFunctionData(ok, info, parent, args, results)
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
	local fnNameWithArgs = info.name .. self.colors.lightblue:WrapTextInColorCode("(" .. ViragDevTool.ArgsToString(args) .. ")")

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
	local parentIndex = ViragDevTool.FindIndex(self.list, info)
	for i, element in ipairs(elements) do
		table.insert(self.list, parentIndex + i, element)
	end

	self:UpdateMainTableUI()

	--print info to chat
	self:Print(stateStr(ok) .. " " .. fnNameWithArgs .. self.colors.gray:WrapTextInColorCode(" returns:") .. returnFormattedStr)
end

-----------------------------------------------------------------------------------------------
-- BOTTOM PANEL Fn Arguments button  and arguments input edit box
-----------------------------------------------------------------------------------------------
function ViragDevTool:SetArgForFunctionCallFromString(argStr)
	local args = ViragDevTool.split(argStr, ",") or {}

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
