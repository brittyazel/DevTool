local ViragDevTool = ViragDevTool

function ViragDevTool:ToggleOptions()
    --   InterfaceOptionsFrame_OpenToCategory(ViragDevTool.ADDON_NAME);
    self:LoadInterfaceOptions()
    self:Toggle(ViragDevToolFrame.optionsFrame)
end


function ViragDevTool:LoadInterfaceOptions()
    if not ViragDevToolFrame.optionsFrame then
        local frame = CreateFrame("Frame", "ViragDevToolOptionsMainFrame", ViragDevToolFrame, "ViragDevToolOptionsFrameRowTemplate")
        frame:SetPoint("BOTTOM", ViragDevToolFrame, "TOP")
        frame:SetHeight(35)
        frame:SetPoint("LEFT")
        frame:SetPoint("RIGHT")
        frame:Hide()

        self:CreateColorPickerFrame(frame)
        ViragDevToolFrame.optionsFrame = frame
        --ViragDevToolFrame.optionsFrame.name = self.ADDON_NAME;
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
            if mouseButton == "RightButton" then
                self.db.profile.colorVals[color] = ViragDevTool_defaults.profile.colorVals[color]
                self.colors[color]:SetRGBA(unpack(ViragDevTool_defaults.profile.colorVals[color]))
                update(this, color)
            elseif mouseButton == "LeftButton" then
                self:ShowColorPicker(color, function()
                    local r, g, b, a = ColorPickerFrame:GetColorRGB()
                    self.db.profile.colorVals[color] = {r,g,b,a}
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

    updateFontSize(button, self.db.profile.fontSize)
    button:SetScript("OnMouseUp", function(this, mouseButton)
        if mouseButton == "RightButton" then
            self.db.profile.fontSize = self.db.profile.fontSize - 1

        elseif mouseButton == "LeftButton" then
            self.db.profile.fontSize = self.db.profile.fontSize + 1
        end

        updateFontSize(this, self.db.profile.fontSize )

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