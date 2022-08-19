-- Default settings
-- this variable will be used only on first load so it is just default init with empty values.
-- will be replaced with ViragDevTool_Settings at 2-nd start
ViragDevTool_defaults = {
	profile = {
		-- selected list in gui. one of 3 list from settings: history or function call logs or events
		sideBarTabSelected = "history",

		-- UI saved state
		isWndOpen = false,
		isSideBarOpen = false,

		-- stores history of recent calls to /vdt
		MAX_HISTORY_SIZE = 50,
		collResizerPosition = 450,
		history = {
			-- examples
			"find LFR",
			"find SLASH",
			"find Data ViragDevTool",
			"startswith Virag",
			"ViragDevTool.settings.history",
		},
		logs = {--{
			--    fnName = "functionNameHere",
			--    parentTableName = "ViragDevTool.sometable",
			--    active = false
			--},
		},

		-- stores arguments for function calls --todo implement
		tArgs = {},
		fontSize = 10, -- font size for default table
		colorVals = {
			["table"] = {0.41,0.80,0.94,1},
			["string"] = {0.67,0.83,0.45,1},
			["number"] = {1,0.96,0.41,1},
			["function"] =  {1,0.49,0.04,1},
			["default"] = {1,1,1,1},
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
				event = "CURSOR_UPDATE",
				active = false
			},
			{
				event = "UNIT_AURA",
				unit = "player",
				active = false
			},
			{
				event = "CHAT_MSG_CHANNEL",
				active = false
			}
		},
	}
}