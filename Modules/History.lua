-- DevTool is a World of Warcraft® addon development tool.
-- Copyright (c) 2021-2025 Britt W. Yazel
-- Copyright (c) 2016-2021 Peter aka "Varren"
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace
local DevTool = addonTable.DevTool

-----------------------------------------------------------------------------------------------
--- HISTORY
-----------------------------------------------------------------------------------------------
function DevTool:AddToHistory(strValue)
	if self.db.profile.history then
		local hist = self.db.profile.history

		-- if already contains value then just move it to top
		for k, v in pairs(hist or {}) do
			if v == strValue then
				table.remove(hist, k)
				table.insert(hist, 1, strValue)
				self:UpdateSideBarUI()
				return
			end
		end

		table.insert(hist, 1, strValue)

		local maxSize = self.DatabaseDefaults.profile.MAX_HISTORY_SIZE
		if self.db.profile.MAX_HISTORY_SIZE then
			maxSize = self.db.profile.MAX_HISTORY_SIZE
		end

		while #hist > maxSize do
			-- can have only 10 values in history
			table.remove(hist, maxSize)
		end

		self:UpdateSideBarUI()
	end
end