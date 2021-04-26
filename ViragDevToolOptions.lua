local ViragDevTool = ViragDevTool

function ViragDevTool:ToggleOptions()
    --   InterfaceOptionsFrame_OpenToCategory(ViragDevTool.ADDON_NAME);
    self:LoadInterfaceOptions()
    self:Toggle(self.wndRef.optionsFrame)
end


function ViragDevTool:LoadInterfaceOptions()
   if not self.wndRef.optionsFrame then
        local frame = CreateFrame("Frame", "ViragDevToolOptionsMainFrame", self.wndRef, "ViragDevToolOptionsFrameRowTemplate")
        frame:SetPoint("BOTTOM", self.wndRef, "TOP")
        frame:SetHeight(35)
        frame:SetPoint("LEFT")
        frame:SetPoint("RIGHT")
        frame:Hide()

        self:CreateColorPickerFrame(frame)
        self.wndRef.optionsFrame = frame
        --self.wndRef.optionsFrame.name = self.ADDON_NAME;
        --InterfaceOptions_AddCategory(frame);
        --InterfaceAddOnsList_Update();
        --InterfaceOptionsFrame_OpenToCategory(ViragDevTool.ADDON_NAME);
    end

end


function ViragDevTool:CreateColorPickerFrame(parent)
    local point = "TOPLEFT"
    local relativeTo = parent
    local relativePoint = "TOPLEFT"
    local xOffset = 5
    local yOffset = -5

    local update = function(button, color)
        button.colorTexture:SetColorTexture(self.colors[color]:GetRGBA())
        button:GetHighlightTexture():SetVertexColor(self.colors[color]:GetRGBA())
        button:GetFontString():SetTextColor(self.colors[color]:GetRGBA())
        ViragDevTool:UpdateMainTableUI()
    end

    local buttons = {}
    for i, color in pairs({ "table", "function", "string", "number", "default" }) do
        local f = CreateFrame("Button", "VDTColorPickerFrameItem" .. i, parent, "VDTColorPickerFrameItemTemplate")
        f:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
        local button = f.picker
        buttons[i] = button
        button:SetText(color)

        button:SetScript("OnMouseUp", function(this, mouseButton)
            if mouseButton == "LeftButton" then
                self:ShowColorPicker(color, function()
                    local r, g, b, a = ColorPickerFrame:GetColorRGB()
                    self.default_settings.colors = {r,g,b,a}
                    self.colors[color]:SetRGBA(r,g,b,a)
                    update(this, color)
                end)
            end

        end)

        update(button, color)

        point = "LEFT"
        relativeTo = f
        relativePoint = "RIGHT"
        yOffset = 0
        xOffset = 5
    end

    local updateFontSize = function(button, fontSize)
        button:SetText("Font: " .. tostring(fontSize))
        ViragDevTool:UpdateMainTableUI()
    end

    local button = CreateFrame("Button", "VDTFrameColorReset", parent, "ViragDevToolButtonTemplate")
    button:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    button:SetPoint("TOP", parent, "TOP", -5, -5)
    button:SetPoint("BOTTOM", parent, "BOTTOM", -5, 5)

    updateFontSize(button, self.settings.fontSize)
    button:SetScript("OnMouseUp", function(this, mouseButton)
        if mouseButton == "RightButton" then
            self.settings.fontSize = self.settings.fontSize - 1

        elseif mouseButton == "LeftButton" then
            self.settings.fontSize = self.settings.fontSize + 1
        end

        updateFontSize(this, self.settings.fontSize )

    end)
end

function ViragDevTool:ShowColorPicker(color, changedCallback)
    local r, g, b, _ = ViragDevTool.colors[color]:GetRGBA()

    ColorPickerFrame.func = function() end
    ColorPickerFrame:SetColorRGB(r, g, b);
    ColorPickerFrame.func = changedCallback

    ColorPickerFrame.cancelFunc = function()
        ColorPickerFrame:SetColorRGB(r, g, b);
        changedCallback()
    end

    ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
    ColorPickerFrame:Show();
end