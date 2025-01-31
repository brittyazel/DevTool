-- DevTool is a World of Warcraft® addon development tool.
-- Copyright (c) 2021-2025 Britt W. Yazel
-- Copyright (c) 2016-2021 Peter aka "Varren"
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace
local DevTool = addonTable.DevTool

-- Default settings
-- this variable will be used only on first load so it is just default init with empty values.
-- will be replaced with DevTool_Settings at 2-nd start
DevTool.DatabaseDefaults = {
	profile = {
		-- selected list in gui. one of 3 list from settings: history or function call logs or events
		sideBarTabSelected = "history",

		-- UI saved state
		isWndOpen = false,
		isSideBarOpen = true,

		-- stores history of recent calls to /dev
		MAX_HISTORY_SIZE = 50,
		collResizeWidth = 250,
		history = {
			-- examples
			"DevTool",
			"find LFR",
			"find SLASH",
			"find Data DevTool",
			"startswith DevTool",
			"DevTool.settings.history",
		},
		logs = {--{
			--    fnName = "functionNameHere",
			--    parentTableName = "DevTool.sometable",
			--    active = false
			--},
		},

		-- stores arguments for function calls --todo implement
		tArgs = {},
		fontSize = 10, -- font size for default table
		colorVals = {
			["table"] = { 0.41, 0.80, 0.94, 1 },
			["string"] = { 0.67, 0.83, 0.45, 1 },
			["number"] = { 1, 0.96, 0.41, 1 },
			["function"] = { 1, 0.49, 0.04, 1 },
			["default"] = { 1, 1, 1, 1 },
		},

		-- events to monitor
		-- format ({event = "EVENT_NAME", unit = "player", active = true}, ...)
		-- default events inactive
		events = {
			{
				event = "ALL",
				active = false
			},
			{
				event = "COMBAT_LOG_EVENT_UNFILTERED",
				active = false
			},
			{
				event = "UNIT_AURA",
				unit = "player",
				active = false
			},
			{
				event = "UPDATE_UI_WIDGET",
				active = false
			}
		},
	}
}