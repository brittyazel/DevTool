-- DevTool is a World of Warcraft® addon development tool.
-- Copyright (c) 2021-2025 Britt W. Yazel
-- Copyright (c) 2016-2021 Peter aka "Varren"
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace
local DevTool = addonTable.DevTool

local AceGUI = LibStub("AceGUI-3.0")

function DevTool:LoadInterfaceOptions()
	if not self.MainWindow.optionsFrame then
		local frame = CreateFrame("Frame", "DevToolOptionsMainFrame", self.MainWindow, "DevToolOptionsFrameRowTemplate")
		frame:SetPoint("BOTTOM", self.MainWindow, "TOP")
		frame:SetPoint("LEFT")
		frame:SetPoint("RIGHT")
		frame:Hide()

		self:CreateColorPickerFrame(frame)
		self.MainWindow.optionsFrame = frame
	end

end

function DevTool:CreateColorPickerFrame(parent)
	local point = "TOPLEFT"
	local relativeTo = parent
	local relativePoint = "TOPLEFT"
	local xOffset = 5
	local yOffset = -5

	-- Color Pickers
	for _, menuItem in pairs({ "table", "function", "string", "number", "default" }) do

		local ColorPicker = AceGUI:Create("ColorPicker")
		ColorPicker:SetLabel(menuItem)
		ColorPicker:SetHasAlpha(true)

		ColorPicker:SetColor(unpack(self.db.profile.colorVals[menuItem]))

		ColorPicker.frame:SetParent(parent)
		ColorPicker.frame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)

		ColorPicker.frame:SetWidth(100)
		ColorPicker.frame:SetHeight(25)

		ColorPicker:SetCallback("OnValueChanged", function(widget, event, r, g, b, a)
			self.db.profile.colorVals[menuItem] = { r, g, b, a }
			self.colors[menuItem]:SetRGBA(r, g, b, a)
			self:UpdateMainTableUI()
		end)

		ColorPicker.frame:Show()

		point = "LEFT"
		relativeTo = ColorPicker.frame
		relativePoint = "RIGHT"
		yOffset = 0
		xOffset = 5
	end

	-- Text Size Slider
	local TextSizeSlider = AceGUI:Create("Slider")
	TextSizeSlider:SetSliderValues(8, 24, 1)
	TextSizeSlider:SetValue(self.db.profile.fontSize)

	TextSizeSlider.frame:SetParent(parent)
	TextSizeSlider.frame:SetPoint(point, relativeTo, relativePoint, 0, 5)

	TextSizeSlider.frame:SetWidth(200)

	TextSizeSlider:SetCallback("OnValueChanged", function(widget, event, size)
		print(size)
		self.db.profile.fontSize = size
		DevTool:UpdateMainTableUI()
	end)

	TextSizeSlider.frame:Show()
end