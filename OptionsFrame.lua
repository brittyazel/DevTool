-- DevTool is a World of Warcraft® addon development tool.
-- Copyright (c) 2021-2023 Britt W. Yazel
-- Copyright (c) 2016-2021 Peter aka "Varren"
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace
local DevTool = addonTable.DevTool

function DevTool:LoadInterfaceOptions()
	if not self.MainWindow.optionsFrame then
		local frame = CreateFrame("Frame", "DevToolOptionsMainFrame", self.MainWindow, "DevToolOptionsFrameRowTemplate")
		frame:SetPoint("BOTTOM", self.MainWindow, "TOP")
		frame:SetHeight(35)
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

	local update = function(button, color)
		button.colorTexture:SetColorTexture(self.colors[color]:GetRGBA())
		button:GetHighlightTexture():SetVertexColor(self.colors[color]:GetRGBA())
		button:GetFontString():SetTextColor(self.colors[color]:GetRGBA())
		DevTool:UpdateMainTableUI()
	end

	local buttons = {}
	for i, color in pairs({ "table", "function", "string", "number", "default" }) do
		local frame = CreateFrame("Button", "DTColorPickerFrameItem" .. i, parent, "DTColorPickerFrameItemTemplate")
		frame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
		local button = frame.picker
		buttons[i] = button
		button:SetText(color)

		button:SetScript("OnMouseUp", function(this, mouseButton)
			if mouseButton == "RightButton" then
				self.db.profile.colorVals[color] = self.DatabaseDefaults.profile.colorVals[color]
				self.colors[color]:SetRGBA(unpack(self.DatabaseDefaults.profile.colorVals[color]))
				update(this, color)
			elseif mouseButton == "LeftButton" then
				self:ShowColorPicker(color, function()
					local r, g, b, a = ColorPickerFrame:GetColorRGB()
					self.db.profile.colorVals[color] = { r, g, b, a }
					self.colors[color]:SetRGBA(r, g, b, a)
					update(this, color)
				end)
			end

		end)

		update(button, color)

		point = "LEFT"
		relativeTo = frame
		relativePoint = "RIGHT"
		yOffset = 0
		xOffset = 5
	end

	local updateFontSize = function(button, fontSize)
		button:SetText("Font: " .. tostring(fontSize))
		DevTool:UpdateMainTableUI()
	end

	local button = CreateFrame("Button", "DTFrameColorReset", parent, "DevToolButtonTemplate")
	button:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	button:SetPoint("TOP", parent, "TOP", -5, -5)
	button:SetPoint("BOTTOM", parent, "BOTTOM", -5, 5)

	updateFontSize(button, self.db.profile.fontSize)
	button:SetScript("OnMouseUp", function(this, mouseButton)
		if mouseButton == "RightButton" then
			self.db.profile.fontSize = self.db.profile.fontSize - 1

		elseif mouseButton == "LeftButton" then
			self.db.profile.fontSize = self.db.profile.fontSize + 1
		end

		updateFontSize(this, self.db.profile.fontSize)

	end)
end

function DevTool:ShowColorPicker(color, changedCallback)
	local r, g, b, _ = DevTool.colors[color]:GetRGBA()

	ColorPickerFrame.func = function()
	end
	ColorPickerFrame:SetColorRGB(r, g, b);
	ColorPickerFrame.func = changedCallback

	ColorPickerFrame.cancelFunc = function()
		ColorPickerFrame:SetColorRGB(r, g, b);
		changedCallback()
	end

	ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
	ColorPickerFrame:Show();
end