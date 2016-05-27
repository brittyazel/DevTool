local MyModData = { size = 0; first = nil, last = nil }

function MyModData:GetInfoAtPosition(position)
    if self.size < position or self.first == nil then
        return nil
    end

    local node = self.first
    while position > 1 do
        node = node.next
        position = position - 1
    end

    return node
end

function MyModData:AddNodeAfter(node, prevNode)
    local tempNext = node.next
    node.next = prevNode
    prevNode.next = tempNext
    self.size = self.size + 1;
end

function MyModData:AddNodesAfter(nodeList, parentNode)
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

function MyModData:AddNode(data, dataName)
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

function MyModData:NewNode(data, dataName, padding, parent)
    return {
        name = dataName,
        value = data,
        next = nil,
        padding = padding == nil and 0 or padding,
        parent = parent
    }
end

function MyModData:RemoveChildNodes(node)
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

function MyModData:Clear()
    self.size = 0
    self.first = nil
    self.last = nil
end

local ipairs, pairs, next, tonumber, tostring, type, print, string, getmetatable, table,pcall = ipairs, pairs, next, tonumber, tostring, type, print, string, getmetatable, table,pcall

local _G = _G

function MyMod_ExpandCell(info)

    local nodeList = {}
    local padding = info.padding + 1
    local couner = 0
    for k, v in pairs(info.value) do
        if type(v) ~= "userdata" then

            nodeList[couner] = MyModData:NewNode(v, tostring(k), padding, info)
        else
            local mt = getmetatable(info.value)
            if mt then
                nodeList[couner] = MyModData:NewNode(mt.__index, "$metatable", padding, info)
            end
        end
        couner = couner + 1
    end

    table.sort(nodeList, function(a, b)
        return a.name < b.name
    end)

    MyModData:AddNodesAfter(nodeList, info)
    info.expanded = true
    MyModScrollBar_Update()
end

function MyMod_ColapseCell(info)
    MyModData:RemoveChildNodes(info)
    info.expanded = nil
    print("size: " .. MyModData.size)
    MyModScrollBar_Update()
end

function MyMod_AddData(data, dataName)
    MyModData:AddNode(data, dataName)
    MyModScrollBar_Update()
end
function MyMod_ClearData()
    MyModData:Clear()
    MyModScrollBar_Update()
end

function MyModScrollBar_Update()
    local scrollFrame = MyModScrollFrame

    local buttons = scrollFrame.buttons;
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local totalRowsCount = MyModData.size
    local lineplusoffset; -- an index into our data calculated from the scroll offset

    local nodeInfo = MyModData:GetInfoAtPosition(offset)
    for k, view in pairs(buttons) do

        lineplusoffset = k + offset;
        -- print("ok: " .. lineplusoffset .. "  " .. offset .. "  " .. k .. " " .. (nodeInfo ~= nil and nodeInfo.name or "nil"))
        if lineplusoffset <= totalRowsCount then
            MyMod_UpdateListItem(view, nodeInfo, lineplusoffset)
            nodeInfo = nodeInfo.next
            view:Show();
        else
            view:Hide();
        end
    end

    HybridScrollFrame_Update(scrollFrame, totalRowsCount * buttons[1]:GetHeight(), scrollFrame:GetHeight());

end



function MyMod_UpdateListItem(node, info, id)
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

    local color = "MyModBaseFont"
    if valueType == "table" then
        if name ~= "$metatable" then
            if value.GetObjectType then
                if value.IsForbidden and value:IsForbidden() then
                else
                    valueButton:SetText(value:GetObjectType() .. "  " .. tostring(value))
                end
            end
            color = "MyModTableFont";
        else
            color = "MyModMetatableFont";
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
        color = "MyModTableFont";
    elseif valueType == "string" then
        valueButton:SetText(string.gsub(string.gsub(tostring(value), "|n", ""), "\n", ""))
        color = "MyModStringFont";
    elseif valueType == "number" then
        color = "MyModNumberFont";
    elseif valueType == "function" then
        color = "MyModFunctionFont";
    end



    node.nameButton:SetNormalFontObject(color);
    node.typeButton:SetNormalFontObject(color)
    node.valueButton:SetNormalFontObject(color)
    node.rowNumberButton:SetNormalFontObject(color)

    if valueType == "table" then
        nameButton:SetScript("OnMouseUp", function(self, button, down)
            print("click")
            if info.expanded then
                MyMod_ColapseCell(info)
            else
                MyMod_ExpandCell(info)
            end
        end)
    elseif valueType == "function" then
        nameButton:SetScript("OnMouseUp", function(self, button, down)
            print("click")
            MyMod_TryCallFunction(info)
        end)
    else
        nameButton:SetScript("OnMouseUp", nil)
    end
end

function MyMod_TryCallFunction(info)
    local value = info.value

    local ok, result = pcall(value)
    if ok then
        local resultType = type(result)
        local additionalInfo = ""
        if resultType == "string" or resultType == "number" then
            additionalInfo = tostring(result)
        end

        print("returns:  " .. resultType .. " " .. additionalInfo)
    else
        local parent = info.parent
        if parent then
            if parent.name == "$metatable" then
                parent = parent.parent
                print("found metatable" ..  info.name)
            end

            local ok, result = pcall(parent.value[info.name], parent.value)
            local resultType = type(result)
            local additionalInfo = tostring(result)

            print(parent.name ..":".. info.name .."() returns: " .. additionalInfo.. "  ("..resultType ..")" )
        end
    end
end