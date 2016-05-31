local ADDON_NAME, ViragDevTool = ...


local pairs, tostring, type, print, string, getmetatable, table, pcall = pairs, tostring, type, print, string, getmetatable, table, pcall
local HybridScrollFrame_CreateButtons, HybridScrollFrame_GetOffset, HybridScrollFrame_Update = HybridScrollFrame_CreateButtons, HybridScrollFrame_GetOffset, HybridScrollFrame_Update

local ViragDevToolLinkedList = { size = 0; first = nil, last = nil }
ViragDevTool.METATABLE_NAME = "$metatable"
ViragDevTool.tArgs = {  }
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
    elseif type(dataName) ~= "string" then
        dataName = tostring(dataName)
    end

    ViragDevToolLinkedList:AddNode(data, dataName)
    ViragDevTool_ScrollBar_Update()
end

function ViragDevTool_AddGlobal(strGlobalName)
    ViragDevTool_AddData(_G[strGlobalName], strGlobalName)
end

function ViragDevTool_ClearData()
    ViragDevToolLinkedList:Clear()
    ViragDevTool_ScrollBar_Update()
end

function ViragDevTool_ExpandCell(info)

    local nodeList = {}
    local padding = info.padding + 1
    local couner = 1
    for k, v in pairs(info.value) do
        if type(v) ~= "userdata" then
            nodeList[couner] = ViragDevToolLinkedList:NewNode(v, tostring(k), padding, info)
        else
            local mt = getmetatable(info.value)
            if mt then
                nodeList[couner] = ViragDevToolLinkedList:NewNode(mt.__index, ViragDevTool.METATABLE_NAME, padding, info)
            end
        end
        couner = couner + 1
    end


    table.sort(nodeList, function(a, b)
        if a.name == "__index" then return true
        elseif b.name == "__index" then return false
        else return a.name < b.name
        end
    end)

    ViragDevToolLinkedList:AddNodesAfter(nodeList, info)
    info.expanded = true
    ViragDevTool_ScrollBar_Update()
end

function ViragDevTool_ColapseCell(info)
    ViragDevToolLinkedList:RemoveChildNodes(info)
    info.expanded = nil
    ViragDevTool_ScrollBar_Update()
end

function ViragDevTool_ScrollBar_Update()

    local scrollFrame = ViragDevToolScrollFrame --todo fix this change to self instead of global name
    ViragDevTool_ScrollBar_AddChildren(scrollFrame)

    local buttons = scrollFrame.buttons;
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local totalRowsCount = ViragDevToolLinkedList.size
    local lineplusoffset;

    local nodeInfo = ViragDevToolLinkedList:GetInfoAtPosition(offset)
    for k, view in pairs(buttons) do
        lineplusoffset = k + offset;
        if lineplusoffset <= totalRowsCount then
            ViragDevTool_UpdateListItem(view, nodeInfo, lineplusoffset)
            nodeInfo = nodeInfo.next
            view:Show();
        else
            view:Hide();
        end
    end

    HybridScrollFrame_Update(scrollFrame, totalRowsCount * buttons[1]:GetHeight(), scrollFrame:GetHeight());
end

function ViragDevTool_ScrollBar_AddChildren(self)
    if ViragDevTool.ScrollBarHeight == nil or self:GetHeight() > ViragDevTool.ScrollBarHeight then
        ViragDevTool.ScrollBarHeight = self:GetHeight()

        local scrollBarValue = self.scrollBar:GetValue()
        HybridScrollFrame_CreateButtons(self, "ViragDevToolEntryTemplate", 0, -2)
        self.scrollBar:SetValue(scrollBarValue);
    end
end


function ViragDevTool_UpdateListItem(node, info, id)
    local nameButton = node.nameButton;
    local typeButton = node.typeButton
    local valueButton = node.valueButton
    local rowNumberButton = node.rowNumberButton

    local value = info.value
    local name = info.name
    local padding = info.padding

    nameButton:SetPoint("LEFT", node.typeButton, "RIGHT", 20 * padding, 0)

    local valueType = type(value)

    valueButton:SetText(tostring(value))
    nameButton:SetText(tostring(name))
    typeButton:SetText(valueType)
    rowNumberButton:SetText(tostring(id))

    local color = "ViragDevToolBaseFont"
    if valueType == "table" then
        if name ~= ViragDevTool.METATABLE_NAME then
            if value.GetObjectType and value.IsForbidden then
                local ok, forbidden = pcall(value.IsForbidden, value)
                if ok and not forbidden then
                    local ok, result = pcall(value.GetObjectType, value)
                    if ok then
                        valueButton:SetText(result .. "  " .. tostring(value))
                    end
                end
            end
            color = "ViragDevToolTableFont";
        else
            color = "ViragDevToolMetatableFont";
        end
        local resultStringName = tostring(name)
        local MAX_STRING_SIZE = 60
        if #resultStringName >= MAX_STRING_SIZE then
            resultStringName = string.sub(resultStringName, 0, MAX_STRING_SIZE) .. "..."
        end

        local function tablelength(T)
            local count = 0
            for _ in pairs(T) do count = count + 1 end
            return count
        end

        nameButton:SetText(resultStringName .. "   (" .. tablelength(value) .. ") ");

    elseif valueType == "userdata" then
        color = "ViragDevToolTableFont";
    elseif valueType == "string" then
        valueButton:SetText(string.gsub(string.gsub(tostring(value), "|n", ""), "\n", ""))
        color = "ViragDevToolStringFont";
    elseif valueType == "number" then
        color = "ViragDevToolNumberFont";
    elseif valueType == "function" then
        color = "ViragDevToolFunctionFont";
        --todo add function args info and description from error msges or from some mapping file
    end



    node.nameButton:SetNormalFontObject(color);
    node.typeButton:SetNormalFontObject(color)
    node.valueButton:SetNormalFontObject(color)
    node.rowNumberButton:SetNormalFontObject(color)

    if valueType == "table" then
        nameButton:SetScript("OnMouseUp", function(self, button, down)
            if info.expanded then
                ViragDevTool_ColapseCell(info)
            else
                ViragDevTool_ExpandCell(info)
            end
        end)
    elseif valueType == "function" then
        nameButton:SetScript("OnMouseUp", function(self, button, down)
            ViragDevTool_TryCallFunction(info)
        end)
    else
        nameButton:SetScript("OnMouseUp", nil)
    end
end

function ViragDevTool_TryCallFunction(info)
    -- info.value is just our function to call
    local parent, ok
    local fn = info.value
    local args = ViragDevTool_shallowcopyargs(ViragDevTool.tArgs)
    local results = {}

    -- lets try safe call first
    ok, results[1], results[2], results[3], results[4], results[5] = pcall(fn, unpack(args, 1, 10))

    if not ok then
        -- if safe call failed we probably could try to find self and call self:fn()
        parent = info.parent


        if parent and parent.value == _G then
            -- this fn is in global namespace so no parent
            parent = nil
        end

        if parent then

            if parent.name == ViragDevTool.METATABLE_NAME then
                -- metatable has real object 1 level higher
                parent = parent.parent
            end
            fn = parent.value[info.name]
            table.insert(args, 1, parent.value)
            ok, results[1], results[2], results[3], results[4], results[5] = pcall(fn, unpack(args, 1, 10))

        end
    end

    ViragDevTool_ProcessCallFunctionData(ok, info, parent, args, results)
end

-- this function is kinda hard to read but it just adds new items to list and prints log in chat.
-- will add 1 row for call result(ok or error) and 1 row for each return value
function ViragDevTool_ProcessCallFunctionData(ok, info, parent, args, results)
    local nodes = {}

    --constract full function call name
    local fnNameWitArgs = ViragDevTool_FNNameToString(info.name, args)

    -- add parrent info so it will be MyFrame:function() instead of just function()
    if parent then
        fnNameWitArgs = " |cFFBEB9B5" .. parent.name .. ":" .. "|cFFFFFFFF" .. fnNameWitArgs
    else
        fnNameWitArgs = " |cFFFFFFFF" .. fnNameWitArgs
    end
    local statusTextColor = (ok and "|cFF00FF00" or "|cFFC25B56")
    local statusStr = (ok and ("|cFF00FF00OK") or "|cFFFF0000ERROR") -- ok is green error is red

    local returnFormatedStr = ""

    if not ok then
        -- if function call was unsuccessful
        nodes[1] = ViragDevToolLinkedList:NewNode(tostring(results[1]), statusStr .. statusTextColor.."function call failed",
            info.padding + 1)
        returnFormatedStr = " |cFFFFFFFF" ..tostring(results[1])
    else
        -- itterate backwords because we want to include every meaningfull nil result
        -- for example 1, 2, nil, 4 should return only this 4 values nothing more nothing less.
        local found = false
        for i = 10, 1, -1 do
            if results[i] ~= nil then found = true end

            if found or i == 1 then
                nodes[i] = ViragDevToolLinkedList:NewNode(results[i], "   ret: " .. i, info.padding + 1)

                returnFormatedStr = " |cFFFFFFFF" .. tostring(results[i]) ..
                        " |cFF96C0CE(" .. type(results[i]) .. ")"  .. returnFormatedStr
            end
        end
    end

    -- create fist node of result info no need for now. will use debug
    local titleNode = ViragDevToolLinkedList:NewNode(statusStr .. " - " .. fnNameWitArgs, -- node value
        statusTextColor .. date("%X") .. " function call results:", -- node name
        info.padding + 1) -- node padding

    table.insert(nodes, 1, titleNode)

    -- adds call result to our UI list

    ViragDevToolLinkedList:AddNodesAfter(nodes, info)
    ViragDevTool_ScrollBar_Update()

    --print info to chat
    local resultInfoStr = statusStr .. fnNameWitArgs .. " |cFFBEB9B5returns:" .. returnFormatedStr

    print("|cFFC25B56[Virag's DT]:|cFFFFFFFF " .. resultInfoStr)
    --PROCESS RESULTS END

    -- if everything faild, just show default Blizzard error
    -- if not ok then
    --     fn(args)
    -- end
end

function ViragDevTool_FNNameToString(name, args)
    -- Create function call string like myFunction(arg1, arg2, arg3)
    local fnNameWitArgs = ""
    local delimiter = ""
    local found = false
    for i = 10, 1, -1 do
        if args[i] ~= nil then found = true end

        if found then
            fnNameWitArgs = tostring(args[i]) .. delimiter .. fnNameWitArgs
            delimiter = ", "
        end
    end

    return name .. "(" .. fnNameWitArgs .. ")"
end

function ViragDevTool_TestFNwithMultipleArgs(a, b, c, d, e, f, g, h)
    return { a, b, c, d, e, f, g }, 2, 3, nil, 5
end


-- Util function
function ViragDevTool_PrintTable(table)
    print(tostring(table))
    for k, v in pairs(table or {}) do
        print(k .. ": " .. v.name)
    end
end

function ViragDevTool_shallowcopyargs(orig)
    local copy = {}
    for i=1,10 do
        copy[i] = orig[i]
    end
    return copy
end


-- register slash cmd
SLASH_VIRAGDEVTOOLS1 = '/vdt';
function SlashCmdList.VIRAGDEVTOOLS(msg, editbox) -- 4.
ViragDevTool_AddGlobal(msg)
end
