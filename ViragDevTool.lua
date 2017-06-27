-- just remove global reference so it is easy to read with my ide
local pairs, tostring, type, print, string, getmetatable, table, pcall, unpack, tonumber =
pairs, tostring, type, print, string, getmetatable, table, pcall, unpack, tonumber
local HybridScrollFrame_CreateButtons, HybridScrollFrame_GetOffset, HybridScrollFrame_Update =
HybridScrollFrame_CreateButtons, HybridScrollFrame_GetOffset, HybridScrollFrame_Update

-- create global instance
ViragDevTool = {
    --static constant useed for metatable name
    METATABLE_NAME = "$metatable",
    METATABLE_NAME2 = "$metatable.__index",
    ADDON_NAME = "ViragDevTool",

    -- you can use /vdt find somestr parentname(can be in format _G.Frame.Button)
    -- for examle "/vdt find Virag" will find every variable in _G that has *Virag* pattern
    -- "/vdt find Data ViragDevTool" will find every variable that has *Data* in their name in _G.ViragDevTool object if it exists
    -- same for "startswith"
    CMD = {
        --"/vdt help"
        HELP = function()
            local a = function(txt) return "|cFF96C0CE" .. txt .. "|cFFFFFFFF" end
            local a2 = function(txt) return "|cFFBEB9B5" .. txt .. "|cFFFFFFFF" end
            local a3 = function(txt) return "|cFF3cb371" .. txt .. "|cFFFFFFFF" end


            local cFix = function(str)
                local result = "|cFFFFFFFF" .. str
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

            local help = {}
            help[cFix("01 /vdt")] = cFix("Toggle UI")
            help[cFix("02 /vdt help")] = cFix("Print help")
            help[cFix("03 /vdt name parent (optional)")] = cFix("Add _G.name or _G.parent.name to the list (ex: /vdt name A.B => _G.A.B.name")
            help[cFix("04 /vdt find name parent (optional)")] = cFix("Add name _G.*name* to the list. Adds any field name that has name part in its name")
            help[cFix("05 /vdt mouseover")] = cFix("Add hoovered frame to the list with  GetMouseFocus()")
            help[cFix("06 /vdt startswith name parent (optional)")] = cFix("Same as find but will look only for name*")
            help[cFix("07 /vdt eventadd eventName unit (optional)")] = cFix("ex: /vdt eventadd UNIT_AURA player")
            help[cFix("08 /vdt eventstop eventName")] = cFix("Stops event monitoring if active")
            help[cFix("09 /vdt logfn tableName functionName (optional)")] = cFix("Log every function call. _G.tableName.functionName")
            help[cFix("10 /vdt vdt_reset_wnd")] = cFix("Reset main frame position if you lost it for some reason")
            local sortedTable = {}
            for k, v in pairs(help) do
                table.insert(sortedTable, k)
            end

            table.sort(sortedTable)

            for _, k in pairs(sortedTable) do
                ViragDevTool:print(k .. " - " .. help[k])
            end

            return help
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
        MOUSEOVER = function(msg2, msg3)
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
        VDT_RESET_WND = function(msg2, msg3)
            ViragDevToolFrame:ClearAllPoints()
            ViragDevToolFrame:SetPoint("CENTER", UIParent)
            ViragDevToolFrame:SetSize(635, 200)
        end
    },

    -- Default settings
    -- this variable will be used only on first load so it is just default init with empty values.
    -- will be replaced with ViragDevTool_Settings at 2-nd start
    default_settings = {
        -- selected list in gui. one of 3 list from settings: history or function call logs or events
        sideBarTabSelected = "history",

        -- UI saved state
        isWndOpen = true,
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

        -- stores arguments for fcunction calls --todo implement
        tArgs = {},
        fontSize = 10, -- font size for default table
        colors = {
            white = "|cFFFFFFFF",
            gray = "|cFFBEB9B5",
            lightblue = "|cFF96C0CE",
            lightgreen = "|cFF98FB98",
            red = "|cFFFF0000",
            green = "|cFF00FF00",
            darkred = "|cFFC25B56",
            parent = "|cFFBEB9B5",
            error = "|cFFFF0000",
            ok = "|cFF00FF00",
            table = { 0.41, 0.80, 0.94, 1 },
            string = { 0.67, 0.83, 0.45, 1 },
            number = { 1, 0.96, 0.41, 1 },
            default = { 1, 1, 1, 1 },
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
-- just remove global reference so it is easy to read with my ide
local ViragDevTool = ViragDevTool

-----------------------------------------------------------------------------------------------
-- ViragDevTool.colors additional setup
-----------------------------------------------------------------------------------------------
ViragDevTool.default_settings.colors["function"] = { 1, 0.49, 0.04, 1 }
ViragDevTool.colors = ViragDevTool.default_settings.colors --shortcut

-----------------------------------------------------------------------------------------------
-- ViragDevToolLinkedList == ViragDevTool.list
-----------------------------------------------------------------------------------------------

--- Linked List
-- @field size
-- @field first
-- @field last
--
-- Each node has:
-- @field name - string name
-- @field value - any object
-- @field next - nil/next node
-- @field padding - int expanded level( when you click on table it expands  so padding = padding + 1)
-- @field parent - parent node after it expanded
-- @field expanded - true/false/nil

local ViragDevToolLinkedList = {}

function ViragDevToolLinkedList:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.size = 0
    return o
end

function ViragDevToolLinkedList:GetInfoAtPosition(position)
    if self.size < position or self.first == nil then
        return nil
    end

    local node = self.first
    while position > 0 do
        node = node.next
        position = position - 1
    end

    return node
end

function ViragDevToolLinkedList:AddNodesAfter(nodeList, parentNode)
    local tempNext = parentNode.next
    local currNode = parentNode;

    for _, node in pairs(nodeList) do
        currNode.next = node
        currNode = node
        self.size = self.size + 1;
    end

    currNode.next = tempNext

    if tempNext == nil then
        self.last = currNode
    end
end

function ViragDevToolLinkedList:AddNode(data, dataName)
    local node = self:NewNode(data, dataName)

    if self.first == nil then
        self.first = node
        self.last = node
    else
        if self.last ~= nil then
            self.last.next = node
        end
        self.last = node
    end

    self.size = self.size + 1;
end

function ViragDevToolLinkedList:NewNode(data, dataName, padding, parent)
    return {
        name = dataName,
        value = data,
        next = nil,
        padding = padding == nil and 0 or padding,
        parent = parent
    }
end

function ViragDevToolLinkedList:RemoveChildNodes(node)
    local currNode = node

    while true do

        currNode = currNode.next

        if currNode == nil then
            node.next = nil
            self.last = node
            break
        end

        if currNode.padding <= node.padding then
            node.next = currNode
            break
        end

        self.size = self.size - 1
    end
end

function ViragDevToolLinkedList:Clear()
    self.size = 0
    self.first = nil
    self.last = nil
end

-----------------------------------------------------------------------------------------------
-- ViragDevTool main
-----------------------------------------------------------------------------------------------
ViragDevTool.list = ViragDevToolLinkedList:new()

---
-- Main (and the only) function you can use in ViragDevTool API
-- Will add data to the list so you can explore its values in UI list
-- @usage
-- Lets suppose you have MyModFN function in yours addon
-- function MyModFN()
-- local var = {}
-- ViragDevTool_AddData(var, "My local var in MyModFN")
-- end
-- This will add var as new var in our list
-- @param data (any type)- is object you would like to track.
-- Default behavior is shallow copy
-- @param dataName (string or nil) - name tag to show in UI for you variable.
-- Main purpose is to give readable names to objects you want to track.
function ViragDevTool_AddData(data, dataName)
    if dataName == nil then
        dataName = tostring(data)
    end

    ViragDevTool.list:AddNode(data, tostring(dataName))
    ViragDevTool:UpdateMainTableUI()
end

function ViragDevTool:Add(data, dataName)
    ViragDevTool_AddData(data, dataName)
end

function ViragDevTool:ExecuteCMD(msg, bAddToHistory)
    if msg == "" then msg = "_G" end
    local resultTable

    local msgs = self.split(msg, " ")
    local cmd = self.CMD[string.upper(msgs[1])]

    if cmd then
        local title
        resultTable, title = cmd(msgs[2], msgs[3])

        if title then msg = title end
    else
        resultTable = self:FromStrToObject(msg)
        if not resultTable then
            self:print("_G." .. msg .. " == nil, so can't add")
        end
    end

    if resultTable then
        if bAddToHistory then
            ViragDevTool:AddToHistory(msg)
        end

        self:Add(resultTable, msg)
    end
end

function ViragDevTool:FromStrToObject(str)

    if str == "_G" then return _G end
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
    self.list:Clear()
    self:UpdateMainTableUI()
end

function ViragDevTool:ExpandCell(info)

    local nodeList = {}
    local padding = info.padding + 1
    local counter = 1
    local mt
    for k, v in pairs(info.value) do
        if type(v) ~= "userdata" then
            nodeList[counter] = self.list:NewNode(v, tostring(k), padding, info)
        else
            local mt = getmetatable(v)
            if mt then
                nodeList[counter] = self.list:NewNode(mt, self.METATABLE_NAME .. " for " .. tostring(k), padding, info)
            else
                if k == 0 then counter = counter - 1 else
                    nodeList[counter] = self.list:NewNode(v, self.METATABLE_NAME .. " not found for " .. tostring(k), padding, info)
                end
            end
        end

        counter = counter + 1
    end

    local mt = getmetatable(info.value)
    if mt then
        nodeList[counter] = self:NewMetatableNode(mt, padding, info)
    else
    end

    table.sort(nodeList, self:SortFnForCells(nodeList))

    self.list:AddNodesAfter(nodeList, info)

    info.expanded = true

    ViragDevTool:UpdateMainTableUI()
end

function ViragDevTool:NewMetatableNode(mt, padding, info)
    if mt then
        if self:tablelength(mt) == 1 and mt.__index then
            return self.list:NewNode(mt.__index, self.METATABLE_NAME2, padding, info)
        else
            return self.list:NewNode(mt, self.METATABLE_NAME, padding, info)
        end
    end
end

function ViragDevTool:IsMetaTableNode(info)
    return info.name == self.METATABLE_NAME or info.name == self.METATABLE_NAME2
end

function ViragDevTool:SortFnForCells(nodeList)

    local cmpFn = function(a, b)
        if a.name == "__index" then return true
        elseif b.name == "__index" then return false
        else
            return a.name < b.name
        end
    end

    if #nodeList > 20000 then --  just optimisation for _G
    cmpFn = function(a, b) return a.name < b.name end
    end
    --lets try some better sorting if we have small number of records
    --numbers will be sorted not like 1,10,2 but like 1,2,10
    if #nodeList < 300 then
        cmpFn = function(a, b)
            if a.name == "__index" then return true
            elseif b.name == "__index" then return false
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

function ViragDevTool:ColapseCell(info)
    self.list:RemoveChildNodes(info)
    info.expanded = nil
    self:UpdateMainTableUI()
end

-----------------------------------------------------------------------------------------------
-- UI
-----------------------------------------------------------------------------------------------
function ViragDevTool:UpdateUI()
    self:UpdateMainTableUI()
    self:UpdateSideBarUI()
end

function ViragDevTool:ToggleUI()
    self:Toggle(self.wndRef)
    self.settings.isWndOpen = self.wndRef:IsVisible()
end

function ViragDevTool:Toggle(view)
    self:SetVisible(view, not view:IsVisible())
end

function ViragDevTool:SetVisible(view, isVisible)
    if not view then return end

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

    local maxX, maxY = parentFrame:GetMaxResize()
    local minX, minY = parentFrame:GetMinResize()


    parentFrame:SetSize(self:CalculatePosition(x - left, minX, maxX),
        self:CalculatePosition(top - y, minY, maxY))
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
        if x <= (minX + parentFrame:GetLeft()) then pos = minX end
        if x >= (maxX + parentFrame:GetLeft()) then pos = maxX end
    end

    dragFrame:ClearAllPoints()
    dragFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", pos, -30) -- 30 is offset from above (top buttons)

    -- save pos so we can restore it on reloda ui or logout
    self.settings.collResizerPosition = pos
end

function ViragDevTool:CalculatePosition(pos, min, max)
    if pos < min then pos = min end
    if pos > max then pos = max end
    return pos
end

-----------------------------------------------------------------------------------------------
-- Main table UI
-----------------------------------------------------------------------------------------------
function ViragDevTool:ForceUpdateMainTableUI()
    self:UpdateMainTableUI(true)
end


function ViragDevTool:UpdateMainTableUI(force)

    if not force then
        self:UpdateMainTableUIOptimized()
        return
    end

    local scrollFrame = self.wndRef.scrollFrame


    self:ScrollBar_AddChildren(scrollFrame, "ViragDevToolEntryTemplate")
    self:UpdateScrollFrameRowSize(scrollFrame)

    local buttons = scrollFrame.buttons;

    local offset = HybridScrollFrame_GetOffset(scrollFrame)

    local totalRowsCount = self.list.size
    local lineplusoffset;

    local nodeInfo = self.list:GetInfoAtPosition(offset)
    --print("Buttons:" .. )
    for k, view in pairs(buttons) do
        lineplusoffset = k + offset;
        if lineplusoffset <= totalRowsCount and (k-1)*buttons[1]:GetHeight() < scrollFrame:GetHeight() then
            self:UIUpdateMainTableButton(view, nodeInfo, lineplusoffset)
            nodeInfo = nodeInfo.next
            view:Show();
        else
            view:Hide();
        end
    end

    HybridScrollFrame_Update(scrollFrame, totalRowsCount * buttons[1]:GetHeight(), scrollFrame:GetHeight());

    scrollFrame.scrollChild:SetWidth(scrollFrame:GetWidth())
end

function ViragDevTool:UpdateScrollFrameRowSize(scrollFrame)
    local currentFont =  self.settings and self.settings.fontSize or 10

    local buttons = scrollFrame.buttons;
    local cellHeight = currentFont + currentFont * 0.2
    cellHeight = cellHeight %2 == 0 and cellHeight or cellHeight + 1
    for _, button in pairs(buttons) do
        button:SetHeight(cellHeight)
        local font = button.nameButton:GetFontString():GetFont()
        button.nameButton:GetFontString():SetFont(font, currentFont)
        button.rowNumberButton:GetFontString():SetFont(font, currentFont)
        button.valueButton:GetFontString():SetFont(font, currentFont)
    end

    scrollFrame.buttonHeight = cellHeight


end

function ViragDevTool:UpdateMainTableUIOptimized()

    if (self.waitFrame == nil) then
        self.waitFrame = CreateFrame("Frame", "ViragDevToolWaitFrame", UIParent);
        self.waitFrame.lastUpdateTime = 0
        self.waitFrame:SetScript("onUpdate", function(self, elapse)

            if self.updateNeeded then
                self.lastUpdateTime = self.lastUpdateTime + elapse
                if self.lastUpdateTime > 0.1 then
                    --preform update
                    ViragDevTool:ForceUpdateMainTableUI()
                    self.updateNeeded = false
                    self.lastUpdateTime = 0
                end
            end
        end);
    end

    self.waitFrame.updateNeeded = true
end

function ViragDevTool:ScrollBar_AddChildren(scrollFrame, strTemplate)
    if scrollFrame.ScrollBarHeight == nil or scrollFrame:GetHeight() > scrollFrame.ScrollBarHeight then
        scrollFrame.ScrollBarHeight = scrollFrame:GetHeight()
        local scrollBarValue = scrollFrame.scrollBar:GetValue()
        HybridScrollFrame_CreateButtons(scrollFrame, strTemplate, 0, -2)
        scrollFrame.scrollBar:SetValue(scrollBarValue);

    end
end

function ViragDevTool:UIUpdateMainTableButton(node, info, id)
    local color = self.colors[type(info.value)]
    if not color then color = self.colors.default end
    if type(info.value) == "table" and self:IsMetaTableNode(info) then
        color = self.colors.default
    end

    node.nameButton:SetPoint("LEFT", node.rowNumberButton, "RIGHT", 10 * info.padding - 10, 0)

    node.valueButton:SetText(self:ToUIString(info.value, info.name, true))
    node.nameButton:SetText(tostring(info.name))
    node.rowNumberButton:SetText(tostring(id))

    node.nameButton:GetFontString():SetTextColor(unpack(color))
    node.valueButton:GetFontString():SetTextColor(unpack(color))
    node.rowNumberButton:GetFontString():SetTextColor(unpack(color))

    self:SetMainTableButtonScript(node.nameButton, info)
    self:SetMainTableButtonScript(node.valueButton, info)
end

function ViragDevTool:ToUIString(value, name, withoutLineBrakes)
    local result
    local valueType = type(value)

    if valueType == "table" then
        result = self:GetObjectInfoFromWoWAPI(name, value) or tostring(value)
        result = "(" .. self:tablelength(value) .. ") " .. result
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
    local ok, objectType = self:TryCallAPIFn(value.GetObjectType, value)

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

        local _, name = self:TryCallAPIFn(value.GetName, value)
        local _, texture = self:TryCallAPIFn(value.GetTexture, value)
        local _, text = self:TryCallAPIFn(value.GetText, value)

        local hasSize, left, bottom, width, height = self:TryCallAPIFn(value.GetBoundsRect, value)


        resultStr = objectType or ""
        if hasSize then
            resultStr = concat(self.colors.white .. "[" ..
                    tostring(self:round(left)) .. ", " ..
                    tostring(self:round(bottom)) .. ", " ..
                    tostring(self:round(width)) .. ", " ..
                    tostring(self:round(height)) .. "]",
                self.colors.lightblue)
        end


        if helperText ~= name then
            resultStr = concat(name, self.colors.gray .. "<", ">" .. self.colors.white)
        end

        resultStr = concat(texture, self.colors.white, self.colors.white)
        resultStr = concat(text, self.colors.white .. "'", "'")
        resultStr = concat(tostring(value), self.colors.lightblue)
    end

    return resultStr
end

function ViragDevTool:TryCallAPIFn(fn, value)
    -- this function is helper fn to get table type from wow api.
    -- if there is GetObjectType then we will return it.
    -- returns Button, Frame or something like this

    -- VALIDATION
    if type(value) ~= "table" then return
    end

    -- VALIDATION FIX if __index is function we dont want to execute it
    -- Example in ACP.L
    local mt = getmetatable(value)
    if mt and type(mt.__index) == "function" then return
    end

    -- VALIDATION is forbidden from wow api
    if value.IsForbidden then
        local ok, forbidden = pcall(value.IsForbidden, value)
        if not ok or (ok and forbidden) then return
        end
    end
    -- VALIDATION has WoW API
    if not fn or type(fn) ~= "function" then return
    end

    -- MAIN PART:
    return pcall(fn, value)
end

-----------------------------------------------------------------------------------------------
-- Sidebar UI
-----------------------------------------------------------------------------------------------
function ViragDevTool:ToggleSidebar()
    self:Toggle(self.wndRef.sideFrame)
    self.settings.isSideBarOpen = self.wndRef.sideFrame:IsVisible()
    self:UpdateSideBarUI()
end

function ViragDevTool:SubmitEditBoxSidebar()
    local edditBox = self.wndRef.sideFrame.editbox
    local msg = edditBox:GetText()
    local selectedTab = self.settings.sideBarTabSelected
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
    local sidebar = self.wndRef.sideFrame
    sidebar.history:SetChecked(false)
    sidebar.events:SetChecked(false)
    sidebar.logs:SetChecked(false)
    sidebar[tabStrName]:SetChecked(true)

    -- update selected tab  and function to update cell items
    self.settings.sideBarTabSelected = tabStrName

    -- refresh ui
    self:UpdateSideBarUI()
end

function ViragDevTool:UpdateSideBarUI()
    local scrollFrame = self.wndRef.sideFrame.sideScrollFrame

    self:ScrollBar_AddChildren(scrollFrame, "ViragDevToolSideBarRowTemplate")

    local buttons = scrollFrame.buttons;

    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local data = self.settings and self.settings[self.settings.sideBarTabSelected] or {}
    local totalRowsCount = self:tablelength(data)

    for k, frame in pairs(buttons) do
        local lineplusoffset = k + offset;

        if lineplusoffset <= totalRowsCount and  k*buttons[1]:GetHeight() < scrollFrame:GetHeight() then
            self:UpdateSideBarRow(frame.mainButton, data, lineplusoffset)

            --setup remove button for every row
            frame.actionButton:SetScript("OnMouseUp", function()
                table.remove(data, lineplusoffset)
                self:UpdateSideBarUI()
            end)
            frame:Show();
        else
            frame:Hide();
        end
    end

    HybridScrollFrame_Update(scrollFrame, totalRowsCount * buttons[1]:GetHeight(), scrollFrame:GetHeight());
end

function ViragDevTool:UpdateSideBarRow(view, data, lineplusoffset)
    local selectedTab = self.settings.sideBarTabSelected

    local currItem = data[lineplusoffset]

    local colorForState = function(isActive)
        return isActive and ViragDevTool.colors.white or ViragDevTool.colors.gray
    end

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

        -- logs update
        view:SetText(colorForState(currItem.active) .. text)
        view:SetScript("OnMouseUp", function()
            ViragDevTool:ToggleFnLogger(currItem)
            view:SetText(colorForState(currItem.active) .. text)
        end)

    elseif selectedTab == "events" then
        -- events  update
        view:SetText(colorForState(currItem.active) .. currItem.event)
        view:SetScript("OnMouseUp", function()
            ViragDevTool:ToggleMonitorEvent(currItem)
            view:SetText(colorForState(currItem.active) .. currItem.event)
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
        leftClickFn = function(this, button, down)
            if info.expanded then
                self:ColapseCell(info)
            else
                self:ExpandCell(info)
            end
        end
    elseif valueType == "function" then
        leftClickFn = function(this, button, down)
            self:TryCallFunction(info)
        end
    end

    button:SetScript("OnMouseUp", function(this, mouseButton, down)
        if mouseButton == "RightButton" then
            local nameButton = this:GetParent().nameButton
            local valueButton = this:GetParent().valueButton
            ViragDevTool:print(nameButton:GetText() .. " - " .. valueButton:GetText())
        else
            leftClickFn(this, mouseButton, down)
        end
    end)
end

function ViragDevTool:TryCallFunction(info)
    -- info.value is just our function to call
    local parent, ok
    local fn = info.value
    local args = { unpack(self.settings.tArgs) }
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

    self:ColapseCell(info) -- if we already called this fn remove old results

    local C = self.colors
    local list = self.list
    local padding = info.padding + 1

    local stateStr = function(state)
        if state then return C.ok .. "OK"
        end
        return C.error .. "ERROR"
    end

    --constract collored full function call name
    local fnNameWithArgs = C.white .. info.name .. C.lightblue .. "(" .. self:argstostring(args) .. ")" .. C.white
    fnNameWithArgs = parent and C.gray .. parent.name .. ":" .. fnNameWithArgs or fnNameWithArgs

    local returnFormatedStr = ""

    -- itterate backwords because we want to include every meaningfull nil result
    -- and with default itteration like pairs() we will just skip them so
    -- for example 1, 2, nil, 4 should return only this 4 values nothing more, nothing less.
    local found = false
    for i = 10, 1, -1 do
        if results[i] ~= nil then found = true
        end

        if found or i == 1 then -- if found some return or if return is nil
        nodes[i] = list:NewNode(results[i], string.format("  return: %d", i), padding)

        returnFormatedStr = string.format(" %s%s %s(%s)%s", C.white, tostring(results[i]),
            C.lightblue, type(results[i]), returnFormatedStr)
        end
    end

    -- create fist node of result info no need for now. will use debug
    table.insert(nodes, 1, list:NewNode(string.format("%s - %s", stateStr(ok), fnNameWithArgs), -- node value
        C.white .. date("%X") .. " function call results:", padding))


    -- adds call result to our UI list
    list:AddNodesAfter(nodes, info)
    self:UpdateMainTableUI()

    --print info to chat
    self:print(stateStr(ok) .. " " .. fnNameWithArgs .. C.gray .. " returns:" .. returnFormatedStr)
end

-----------------------------------------------------------------------------------------------
-- BOTTOM PANEL Fn Arguments button  and arguments input eddit box
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

    self.settings.tArgs = args
    self:Add(args, "New Args for function calls")
end

-----------------------------------------------------------------------------------------------
-- LIFECICLE
-----------------------------------------------------------------------------------------------
function ViragDevTool:OnLoad(mainFrame)
    self.wndRef = mainFrame

    self.wndRef:RegisterEvent("ADDON_LOADED")
    self.wndRef:SetScript("OnEvent", function(this, event, addonName, ...)
        if event == "ADDON_LOADED" and addonName == self.ADDON_NAME then
            self:OnAddonSettingsLoaded()
        end
    end);

    --register update scrollFrame
    self.wndRef.scrollFrame.update = function()
        self:ForceUpdateMainTableUI()
    end

    self.wndRef.sideFrame.sideScrollFrame.update = function()
        self:UpdateSideBarUI()
    end

    -- register slash cmd
    SLASH_VIRAGDEVTOOLS1 = '/vdt';
    function SlashCmdList.VIRAGDEVTOOLS(msg, editbox)
        if msg == "" or msg == nil then
            self:ToggleUI()
        else
            self:ExecuteCMD(msg, true)
        end
    end

    self:UpdateUI()
end

function ViragDevTool:OnAddonSettingsLoaded()
    local s = ViragDevTool_Settings

    if s == nil then
        s = self.default_settings
        ViragDevTool_Settings = s
    else
        -- validating current settings and updating if version changed

        for k, defaultValue in pairs(self.default_settings) do
            local savedValue = s[k] -- saved value from "newSettings"

            -- if setting is a table of size 0 or if value is nil set it to default
            -- for now we have only arrays in settings so its fine to use #table
            if (type(savedValue) == "table" and self:tablelength(savedValue) == 0)
                    or savedValue == nil then

                s[k] = defaultValue
            end
        end
    end

    --save to local var, so it is easy to use
    self.settings = s

    -- refresh gui

    -- setup open o closed main wnd
    self:SetVisible(self.wndRef, s.isWndOpen)

    -- setup open or closed sidebar
    self:SetVisible(self.wndRef.sideFrame, s.isSideBarOpen)

    -- setup selected sidebar tab history/events/logs
    self:EnableSideBarTab(s.sideBarTabSelected)

    -- setup logs. Just disable all of them for now on startup
    for _, tLog in pairs(self.settings.logs) do
        tLog.active = false
    end

    -- setup events part 1 register listeners
    for _, tEvent in pairs(self.settings.events) do
        if tEvent.active then
            self:StartMonitorEvent(tEvent.event, tEvent.unit)
        end
    end

    -- show in UI fn saved args if you have them
    local args = ""
    local delim = ""
    for _, arg in pairs(s.tArgs) do
        args = tostring(arg) .. delim .. args
        delim = ", "
    end

    self.wndRef.editbox:SetText(args)

    -- setup events part 2 set scripts on frame to listen registered events
    self:SetMonitorEventScript()


    --we store colors not in saved settings for now
    if s.colors then self.colors = s.colors
    end
    s.colors = self.colors

    self:LoadInterfaceOptions()

    self.wndRef.columnResizer:SetPoint("TOPLEFT", self.wndRef, "TOPLEFT", s.collResizerPosition, -30)

    self:UpdateUI()
end

-----------------------------------------------------------------------------------------------
-- UTILS
-----------------------------------------------------------------------------------------------
function ViragDevTool:print(strText)
    print(self.colors.darkred .. "[Virag's DT]: " .. self.colors.white .. strText)
end

function ViragDevTool:split(sep)
    local sep, fields = sep or ".", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields + 1] = c
    end)
    return fields
end

function ViragDevTool.starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

function ViragDevTool.ends(String, End)
    return End == '' or string.sub(String, -string.len(End)) == End
end

function ViragDevTool:tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1
    end
    return count
end

function ViragDevTool:argstostring(args)
    local strArgs = ""
    local found = false
    local delimiter = ""
    for i = 10, 1, -1 do
        if args[i] ~= nil then found = true
        end

        if found then
            strArgs = tostring(args[i]) .. delimiter .. strArgs
            delimiter = ", "
        end
    end
    return strArgs
end

function ViragDevTool:round(num, idp)
    if num == nil then return nil end
    local mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function ViragDevTool:RGBPercToHex(r, g, b, a)
    r = r <= 1 and r >= 0 and r or 0
    g = g <= 1 and g >= 0 and g or 0
    b = b <= 1 and b >= 0 and b or 0
    a = a <= 1 and a >= 0 and a or 0
    return string.format("%02x%02x%02x%02x", a * 255, r * 255, g * 255, b * 255)
end

local function HexToRGBPerc(hex)
    local rhex, ghex, bhex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)
    return tonumber(rhex, 16) / 255, tonumber(ghex, 16) / 255, tonumber(bhex, 16) / 255
end
