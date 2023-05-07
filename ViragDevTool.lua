-- DevTool is a World of Warcraft® addon development tool.
-- Copyright (c) 2021-2023 Britt W. Yazel
-- Copyright (c) 2016-2021 Peter Varren
-- This code is licensed under the MIT license (see LICENSE for details)

local addonName, addonTable = ... --make use of the default addon namespace

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
	self.cache = {}

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

	self:RegisterChatCommand("vdt", function(msg)
		if msg == "" or msg == nil then
			self:ToggleUI()
		else
			self:ExecuteCMD(msg, true)
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
	-- you can use /vdt find somestr parentname(can be in format _G.Frame.Button)
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
				result = string.gsub(result, "vdt_reset_wnd", a3("vdt_reset_wnd"))
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
			print(cFix("/vdt vdt_reset_wnd") .. " - " .. cFix("Reset main frame position if you lost it for some reason"))

			return ""

		end,
		-- "/vdt find Data ViragDevTool" or "/vdt find Data"
		FIND = function(msg2, msg3)
			local parent = msg3 and ViragDevTool:FromStrToObject(msg3) or _G
			return ViragDevTool:FindIn(parent, msg2, string.match)
		end,
		--"/vdt startswith Data ViragDevTool" or "/vdt startswith Data"
		STARTSWITH = function(msg2, msg3)
			local parent = msg3 and ViragDevTool:FromStrToObject(msg3) or _G
			return ViragDevTool:FindIn(parent, msg2, ViragDevTool.starts)
		end,
		--"/vdt mouseover" --m stands for mouse focus
		MOUSEOVER = function()
			local resultTable = GetMouseFocus()
			return resultTable, resultTable:GetName()
		end,
		--"/vdt eventadd ADDON_LOADED"
		EVENTADD = function(msg2, msg3)
			ViragDevTool:StartMonitorEvent(msg2, msg3)
		end,
		--"/vdt eventremove ADDON_LOADED"
		EVENTSTOP = function(msg2, msg3)
			ViragDevTool:StopMonitorEvent(msg2, msg3)
		end,
		--"/vdt log tableName fnName" tableName in global namespace and fnName in table
		LOGFN = function(msg2, msg3)
			ViragDevTool:StartLogFunctionCalls(msg2, msg3)
		end,
		VDT_RESET_WND = function()
			self.MainWindow:ClearAllPoints()
			self.MainWindow:SetPoint("CENTER", UIParent)
			self.MainWindow:SetSize(635, 400)
		end
	}

end

-----------------------------------------------------------------------------------------------
-- LIFECYCLE
-----------------------------------------------------------------------------------------------

function ViragDevTool:LoadSettings()

	-- validating current settings and updating if version changed

	-- setup open o closed main wnd
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

	self.MainWindow.columnResizer:SetPoint("TOPLEFT", self.MainWindow, "TOPLEFT", self.db.profile.collResizerPosition, -30)

end


-----------------------------------------------------------------------------------------------
-- UTILS
-----------------------------------------------------------------------------------------------
function ViragDevTool:split(sep)
	local separator, fields
	separator, fields = sep or ".", {}
	local pattern = string.format("([^%s]+)", separator)
	self:gsub(pattern, function(c)
		fields[#fields + 1] = c
	end)
	return fields
end

function ViragDevTool.starts(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

function ViragDevTool.ends(String, End)
	return End == '' or string.sub(String, -string.len(End)) == End
end

function ViragDevTool:argstostring(args)
	local strArgs = ""
	local found = false
	local delimiter = ""
	for i = 10, 1, -1 do
		if args[i] ~= nil then
			found = true
		end

		if found then
			strArgs = tostring(args[i]) .. delimiter .. strArgs
			delimiter = ", "
		end
	end
	return strArgs
end

function ViragDevTool:round(num, idp)
	if num == nil then
		return nil
	end
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function ViragDevTool:tContains(table, item)
	local index = 1;
	while table[index] do
		if ( item == table[index] ) then
			return 1;
		end
		index = index + 1;
	end
	return nil;
end


-----------------------------------------------------------------------------------------------
-- ViragDevTool main
-----------------------------------------------------------------------------------------------

--- The main (and the only) function you can use in ViragDevTool API
--- Adds data to the list so you can explore its values in UI list
--- @param data (any type)- is object you would like to track.
--- Default behavior is shallow copy
--- @param dataName (string or nil) - name tag to show in UI for you variable.
function ViragDevTool:AddData(data, dataName)
	if dataName == nil then
		dataName = tostring(data)
	end

	table.insert(self.list, self:NewElement(data, tostring(dataName)))
	self:UpdateMainTableUI()
end

function ViragDevTool:NewElement(data, dataName, padding, parent)
	return {
		name = dataName,
		value = data,
		next = nil,
		padding = padding == nil and 0 or padding,
		parent = parent
	}
end

function ViragDevTool:ExecuteCMD(msg, bAddToHistory)
	if msg == "" then
		msg = "_G"
	end
	local resultTable

	local msgs = self.split(msg, " ")
	local cmd = self.CMD[string.upper(msgs[1])]

	if cmd then
		local title
		resultTable, title = cmd(msgs[2], msgs[3])

		if title then
			msg = title
		end
	else
		resultTable = self:FromStrToObject(msg)
		if not resultTable then
			self:Print("_G." .. msg .. " == nil, so can't add")
		end
	end

	if resultTable then
		if bAddToHistory then
			ViragDevTool:AddToHistory(msg)
		end

		self:AddData(resultTable, msg)
	end
end

function ViragDevTool:FromStrToObject(str)

	if str == "_G" then
		return _G
	end

	local vars = self.split(str, ".") or {}

	local var = _G
	for _, name in pairs(vars) do
		if var then
			var = var[name]
		end
	end

	return var
end

function ViragDevTool:ClearData()
	table.wipe(self.list)
	collectgarbage("collect")
	self:UpdateMainTableUI()
end

function ViragDevTool:ExpandCell(info)

	local nodeList = {}
	local padding = info.padding + 1
	local mt
	for k, v in pairs(info.value) do
		if type(v) ~= "userdata" then
			table.insert(nodeList, self:NewElement(v, tostring(k), padding, info))
		else
			mt = getmetatable(v)
			if mt then
				table.insert(nodeList, self:NewElement(mt, "$metatable for " .. tostring(k), padding, info))
			else
				if k ~= 0 then
					table.insert(nodeList, self:NewElement(v, "$metatable not found for " .. tostring(k), padding, info))
				end
			end
		end
	end

	mt = getmetatable(info.value)
	if mt then
		table.insert(nodeList, self:NewMetatableElement(mt, padding, info))
	end

	table.sort(nodeList, self:SortFnForCells(nodeList))

	local parentIndex = self:tContains(self.list, info)
	for i, element in ipairs(nodeList) do
		table.insert(self.list, parentIndex + i, element)
	end

	info.expanded = true

	self:UpdateMainTableUI()
end

function ViragDevTool:NewMetatableElement(mt, padding, info)
	if type(mt) == "table" then
		if #mt == 1 and mt.__index then
			return self:NewElement(mt.__index, "$metatable.__index", padding, info)
		else
			return self:NewElement(mt, "$metatable", padding, info)
		end
	end
end

function ViragDevTool:IsMetaTableNode(info)
	return info.name == "$metatable" or info.name == "$metatable.__index"
end

function ViragDevTool:SortFnForCells(nodeList)

	local cmpFn = function(a, b)
		if a.name == "__index" then
			return true
		elseif b.name == "__index" then
			return false
		else
			return a.name < b.name
		end
	end

	if #nodeList > 20000 then
		--  just optimisation for _G
		cmpFn = function(a, b)
			return a.name < b.name
		end
	end
	--lets try some better sorting if we have small number of records
	--numbers will be sorted not like 1,10,2 but like 1,2,10
	if #nodeList < 300 then
		cmpFn = function(a, b)
			if a.name == "__index" then
				return true
			elseif b.name == "__index" then
				return false
			else
				if tonumber(a.name) ~= nil and tonumber(b.name) ~= nil then
					return tonumber(a.name) < tonumber(b.name)
				else
					return a.name < b.name
				end
			end
		end
	end

	return cmpFn
end

function ViragDevTool:CollapseCell(info)
	self:RemoveChildElements(info)
	info.expanded = nil
	self:UpdateMainTableUI()
end

function ViragDevTool:RemoveChildElements(info)
	local parentIndex = self:tContains(self.list, info)
	while true do
		local nextElement = self.list[parentIndex + 1]
		if nextElement and nextElement.padding > info.padding then
			table.remove(self.list, parentIndex + 1)
		else
			break
		end
	end
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

-- i ddo manual resizing and not the defalt
-- self:GetParent():StartSizing("BOTTOMRIGHT");
-- self:GetParent():StopMovingOrSizing();
-- BEACUSE i don't like default behaviur.
function ViragDevTool:ResizeMainFrame(dragFrame)
	local parentFrame = dragFrame:GetParent()

	local left = dragFrame:GetParent():GetLeft()
	local top = dragFrame:GetParent():GetTop()

	local x, y = GetCursorPosition()
	local s = parentFrame:GetEffectiveScale()
	x = x / s
	y = y / s

	local minX, minY, maxX, maxY

	if parentFrame.SetResizeBounds then
		-- WoW 10.0
		minX, minY, maxX, maxY = parentFrame:GetResizeBounds()
	else
		maxX, maxY = parentFrame:GetMaxResize()
		minX, minY = parentFrame:GetMinResize()

	end

	parentFrame:SetSize(self:CalculatePosition(x - left, minX, maxX),
			self:CalculatePosition(top - y, minY, maxY))
end

function ViragDevTool:ResizeUpdateTick(frame)
	self:ResizeMainFrame(frame)
	self:DragResizeColumn(frame:GetParent().columnResizer, true)
	self:UpdateMainTableUI()
	self:UpdateSideBarUI()
end

function ViragDevTool:ColumnResizeUpdateTick(frame)
	self:DragResizeColumn(frame, true)
	self:UpdateMainTableUI()
	self:UpdateSideBarUI()
end

function ViragDevTool:DragResizeColumn(dragFrame, ignoreMousePosition)
	local parentFrame = dragFrame:GetParent()

	-- 150 and 50 are just const values. safe to change
	local minX = 150
	local maxX = parentFrame:GetWidth() - 50

	local pos = dragFrame:GetLeft() - parentFrame:GetLeft()
	pos = self:CalculatePosition(pos, minX, maxX)

	if not ignoreMousePosition then
		local x, y = GetCursorPosition()
		local s = parentFrame:GetEffectiveScale()
		x = x / s
		y = y / s
		if x <= (minX + parentFrame:GetLeft()) then
			pos = minX
		end
		if x >= (maxX + parentFrame:GetLeft()) then
			pos = maxX
		end
	end

	dragFrame:ClearAllPoints()
	dragFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", pos, -30) -- 30 is offset from above (top buttons)

	-- save pos so we can restore it on reloda ui or logout
	self.db.profile.collResizerPosition = pos
end

function ViragDevTool:CalculatePosition(pos, min, max)
	if pos < min then
		pos = min
	end
	if pos > max then
		pos = max
	end
	return pos
end

-----------------------------------------------------------------------------------------------
-- Main table UI
-----------------------------------------------------------------------------------------------
function ViragDevTool:UpdateMainTableUI()
	if not self.MainWindow or not self.MainWindow.scrollFrame:IsVisible() then
		return
	end

	-- only run this if the height actually changed or we have nothing cached
	if not self.cache.mainScrollBarHeight or self.MainWindow.scrollFrame:GetHeight() > self.cache.mainScrollBarHeight then
		self.cache.mainScrollBarHeight = self.MainWindow.scrollFrame:GetHeight()
		self:ScrollBar_AddChildren(self.MainWindow.scrollFrame, "ViragDevToolEntryTemplate")
	end

	-- only run this if the font actually changed or we have nothing cached
	if not self.cache.fontSize or self.cache.fontSize ~= self.db.profile.fontSize then
		self.cache.fontSize = self.db.profile.fontSize or 10
		self:UpdateScrollFrameRowSize(self.MainWindow.scrollFrame)
	end

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
			self.MainWindow.scrollFrame.buttons[1]:GetHeight(), self.MainWindow.scrollFrame:GetHeight());

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
	HybridScrollFrame_CreateButtons(scrollFrame, strTemplate, 0, -2)
	scrollFrame.scrollBar:SetValue(scrollFrame.scrollBar:GetValue());
end

function ViragDevTool:UIUpdateMainTableButton(node, info, id)
	local color = self.colors[type(info.value)]
	if not color then
		color = self.colors.default
	end
	if type(info.value) == "table" and self:IsMetaTableNode(info) then
		color = self.colors.default
	end

	node.nameButton:SetPoint("LEFT", node.rowNumberButton, "RIGHT", 10 * info.padding - 10, 0)

	node.valueButton:SetText(self:ToUIString(info.value, info.name, true))
	node.nameButton:SetText(tostring(info.name))
	node.rowNumberButton:SetText(tostring(id))

	node.nameButton:GetFontString():SetTextColor(color:GetRGBA())
	node.valueButton:GetFontString():SetTextColor(color:GetRGBA())
	node.rowNumberButton:GetFontString():SetTextColor(color:GetRGBA())

	self:SetMainTableButtonScript(node.nameButton, info)
	self:SetMainTableButtonScript(node.valueButton, info)
end

function ViragDevTool:ToUIString(value, name, withoutLineBrakes)
	local result
	local valueType = type(value)

	if valueType == "table" then
		result = self:GetObjectInfoFromWoWAPI(name, value) or tostring(value)
		result = "(" .. #value .. ") " .. result
	else
		result = tostring(value)
	end

	if withoutLineBrakes then
		result = string.gsub(string.gsub(tostring(result), "|n", ""), "\n", "")
	end

	return result
end

function ViragDevTool:GetObjectInfoFromWoWAPI(helperText, value)
	local resultStr
	local ok, objectType = self:TryCallAPIFn("GetObjectType", value)

	-- try to get frame name
	if ok then
		local concat = function(str, before, after)
			before = before or ""
			after = after or ""
			if str then
				return resultStr .. " " .. before .. str .. after
			end
			return resultStr
		end

		local _, name = self:TryCallAPIFn("GetName", value)
		local _, texture = self:TryCallAPIFn("GetTexture", value)
		local _, text = self:TryCallAPIFn("GetText", value)

		local hasSize, left, bottom, width, height = self:TryCallAPIFn("GetBoundsRect", value)

		resultStr = objectType or ""
		if hasSize then
			resultStr = concat("[" ..
					tostring(self:round(left)) .. ", " ..
					tostring(self:round(bottom)) .. ", " ..
					tostring(self:round(width)) .. ", " ..
					tostring(self:round(height)) .. "]")
		end

		if helperText ~= name then
			resultStr = concat(name, self.colors.gray:WrapTextInColorCode("<"), self.colors.gray:WrapTextInColorCode(">"))
		end

		resultStr = concat(texture)
		resultStr = concat(text, "'", "'")
		resultStr = concat(tostring(value))
	end

	return resultStr
end

function ViragDevTool:TryCallAPIFn(fnName, value)
	-- this function is helper fn to get table type from wow api.
	-- if there is GetObjectType then we will return it.
	-- returns Button, Frame or something like this

	-- VALIDATION
	if type(value) ~= "table" then
		return
	end

	-- VALIDATION FIX if __index is function we don't want to execute it
	-- Example in ACP.L
	local mt = getmetatable(value)
	if mt and type(mt) == "table" and type(mt.__index) == "function" then
		return
	end

	-- VALIDATION is forbidden from wow api
	if value.IsForbidden then
		local ok, forbidden = pcall(value.IsForbidden, value)
		if not ok or (ok and forbidden) then
			return
		end
	end

	local fn = value[fnName]
	-- VALIDATION has WoW API
	if not fn or type(fn) ~= "function" then
		return
	end

	-- MAIN PART:
	return pcall(fn, value)
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
	local msg = edditBox:GetText()
	local selectedTab = self.db.profile.sideBarTabSelected
	local cmd = msg

	if selectedTab == "logs" then
		cmd = "logfn " .. msg
	elseif selectedTab == "events" then
		cmd = "eventadd " .. msg
	end

	self:ExecuteCMD(cmd, true)
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
	-- only run this if the height actually changed or we have nothing cached
	if not self.cache.sideScrollBarHeight or self.MainWindow.sideFrame.sideScrollFrame:GetHeight() >
			self.cache.sideScrollBarHeight then
		self.cache.sideScrollBarHeight = self.MainWindow.sideFrame.sideScrollFrame:GetHeight()
		self:ScrollBar_AddChildren(self.MainWindow.sideFrame.sideScrollFrame, "ViragDevToolSideBarRowTemplate")
	end

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

function ViragDevTool:UpdateSideBarRow(view, data, lineplusoffset)
	local selectedTab = self.db.profile.sideBarTabSelected

	local currItem = data[lineplusoffset]

	if selectedTab == "history" then
		-- history update
		local name = tostring(currItem)
		view:SetText(name)
		view:SetScript("OnMouseUp", function()
			ViragDevTool:ExecuteCMD(name)
			--move to top
			table.remove(data, lineplusoffset)
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
	--todo add left click = copy to chat
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
		if type(v) == "string" and self.starts(v, "t=") then

			local obj = self:FromStrToObject(string.sub(v, 3))
			if obj then
				args[k] = obj
			end
		end
	end

	-- lets try safe call first
	local ok, results = self:TryCallFunctionWithArgs(fn, args)

	if not ok then
		-- if safe call failed we probably could try to find self and call self:fn()
		parent = self:GetParentTable(info)

		if parent then
			args = { parent.value, unpack(args) } --shallow copy and add parent table
			ok, results = self:TryCallFunctionWithArgs(fn, args)
		end
	end

	self:ProcessCallFunctionData(ok, info, parent, args, results)
end

function ViragDevTool:GetParentTable(info)
	local parent = info.parent
	if parent and parent.value == _G then
		-- this fn is in global namespace so no parent
		parent = nil
	end

	if parent then
		if self:IsMetaTableNode(parent) then
			-- metatable has real object 1 level higher
			parent = parent.parent
		end
	end

	return parent
end

function ViragDevTool:TryCallFunctionWithArgs(fn, args)
	local results = { pcall(fn, unpack(args, 1, 10)) }
	local ok = results[1]
	table.remove(results, 1)
	return ok, results
end

-- this function is kinda hard to read but it just adds new items to list and prints log in chat.
-- will add 1 row for call result(ok or error) and 1 row for each return value
function ViragDevTool:ProcessCallFunctionData(ok, info, parent, args, results)
	local nodes = {}

	self:CollapseCell(info) -- if we already called this fn remove old results

	local padding = info.padding + 1

	local stateStr = function(state)
		if state then
			return self.colors.ok:WrapTextInColorCode("OK")
		end
		return self.colors.error:WrapTextInColorCode("ERROR")
	end

	--constract collored full function call name
	local fnNameWithArgs = info.name .. self.colors.lightblue:WrapTextInColorCode("(" .. self:argstostring(args) .. ")")

	fnNameWithArgs = parent and self.colors.gray:WrapTextInColorCode(parent.name .. ":" .. fnNameWithArgs) or fnNameWithArgs

	local returnFormatedStr = ""

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
			table.insert(nodes, self:NewElement(results[i], string.format("  return: %d", i), padding))

			returnFormatedStr = string.format(" %s (%s)%s", tostring(results[i]),
					self.colors.lightblue:WrapTextInColorCode(type(results[i])), returnFormatedStr)
		end
	end

	-- create fist node of result info no need for now. will use debug
	table.insert(nodes, 1, self:NewElement(string.format("%s - %s", stateStr(ok), fnNameWithArgs), -- node value
			date("%X") .. " function call results:", padding))

	-- adds call result to our UI list
	local parentIndex = self:tContains(self.list, info)
	for i, element in ipairs(nodes) do
		table.insert(self.list, parentIndex + i, element)
	end

	self:UpdateMainTableUI()

	--print info to chat
	self:Print(stateStr(ok) .. " " .. fnNameWithArgs .. self.colors.gray:WrapTextInColorCode(" returns:") .. returnFormatedStr)
end

-----------------------------------------------------------------------------------------------
-- BOTTOM PANEL Fn Arguments button  and arguments input edit box
-----------------------------------------------------------------------------------------------
function ViragDevTool:SetArgForFunctionCallFromString(argStr)
	local args = self.split(argStr, ",") or {}

	local trim = function(s)
		return (s:gsub("^%s*(.-)%s*$", "%1"))
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
