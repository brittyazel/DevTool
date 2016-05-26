local ADDON_NAME, VARREN_DEV_TOOLS = ...

--message('Hello World!')
function VARREN_DEV_TOOLS:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.data = {}
    return o
end

function VARREN_DEV_TOOLS:Init()
    self:initGUI()
end

function VARREN_DEV_TOOLS:initGUI()
    self.frame = self:CreateFrame()
    -- message('Hello World!')

    local test = "<html><body><p>Demo Start</p><p>"

    local testtbl = { a = {h=7,g=45},b=10,c=15 }
    for key, value in pairs(C_LFGList) do
        test = test .. key .. "<br />"
    end

    self:AddNode(testtbl, "testtbl")
    test = test .. "</p><p>Demo End</p></body></html>"
    --frame:SetText(test)
    --frame:SetFont('Fonts\\FRIZQT__.TTF', 11)
end

function VARREN_DEV_TOOLS:CreateFrame()
 --   local frame = CreateFrame("Frame", "MUI_BuffFrame", UIParent, "BasicFrameTemplateWithInset")
    local frame = CreateFrame("Frame", "MUI_BuffFrame", UIParent)
    --local frame = CreateFrame("SimpleHTML", "MUI_BuffFrame", UIParent)

    --local scrollFrame = CreateFrame("ScrollFrame")
    -- scrollFrame:SetScrollChild(frame)
    -- scrollFrame:SetSize(800, 800)
    frame:SetSize(800, 800)

    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:Show()
    -- scrollFrame:Show()
    return frame
end

function VARREN_DEV_TOOLS:AddNodeAtPosition(var, helperText, order, position)
    local mybutton = CreateFrame("Button", "mybutton".. position, self.frame, "UIPanelButtonTemplate")
    mybutton:SetPoint("TOP", 2 + 22 * order, -22  * (position + 1))
    mybutton:SetWidth(790 - (22 * order))
    mybutton:SetHeight(22)
    local text = self:TextFromVar(var, helperText)
    mybutton:SetText(text)

    self.data[position] = {
        var = var,
        order = order,
        expanded = false,
       -- text = text
    }

    mybutton:SetID(position)

    if type(var) == "table" or type(var) == "userdata" then
        mybutton:SetScript("OnMouseUp", function(self, button, down)
            print("click")
            local isExpanded = VARREN_DEV_TOOLS.data[position].expanded

            if not isExpanded then
                VARREN_DEV_TOOLS:Expand(mybutton)
            end
        end)
    end
end

function VARREN_DEV_TOOLS:AddNode(var, helperText)
    self:AddNodeAtPosition(var, helperText, 0, 1)
end

function VARREN_DEV_TOOLS:TextFromVar(var, helperName)
    if type(var) ~= "table" and type(var) ~= "userdata" then
        return helperName .. ": " .. tostring(var)
    end

    return "table: " .. helperName .. " - " .. tostring(var)
end

function VARREN_DEV_TOOLS:Expand(node)

    local id = node:GetID()
    print(id)
    self:PrintTable(self.data)

    local info = self.data[id]

    info.expanded = true

    local nodeInfo = info.var
    local order = info.order + 1
    local i = id + 1


    for key, value in pairs(nodeInfo) do
        self:AddNodeAtPosition(value, key, order, i)
        i = i + 1
    end
end

function VARREN_DEV_TOOLS:PrintTable(table, padding)
    if  not padding then padding = "" end

    for key, value in pairs(table) do
        if type(value) ~= "table" and type(value) ~= "userdata" then
            print(padding .. key .. ": " .. tostring(value))
        else
            print(padding .. key)
            self:PrintTable(value, padding.. "---")
        end
    end
end


local VARREN_DEV_TOOLS_INST = VARREN_DEV_TOOLS:new()
VARREN_DEV_TOOLS_INST:Init()
