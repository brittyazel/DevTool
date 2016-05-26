local MyModData = {}
local MyMODEVariablesToTrack = {} -- format{[0] = {table = someTable, }}
local MyModChildFrames = {}

local ipairs, pairs, next, tonumber, tostring, type, print, string = ipairs, pairs, next, tonumber, tostring, type, print, string

local _G = _G

local MyMod_MEATATABLE_KEY = "$mt "

function MyMod_OnLoad(self)
    print("load")
    MyMod_LoadData(_G)
    local prevButton;
    self.scrollFrame.update = MyModScrollBar_Update;
    --[[
    for i = 1, (700 / 16) do
        local frame = CreateFrame("FRAME", "MyModEntry" .. i, self, "MyModEntryTemplate");
        if i == 1 then
            frame:SetPoint("TOPLEFT", MyModScrollBar, "TOPLEFT", 8, 0)
        else
            frame:SetPoint("TOPLEFT", MyModChildFrames[i - 1], "BOTTOMLEFT")
        end

        --MyModChildFrames[i] = frame
    end--]]

    HybridScrollFrame_CreateButtons(self.scrollFrame, "MyModEntryTemplate", 0, -2);
    MyModScrollBar:Show()
end

function MyMod_LoadData(data, saveParent)
    local i = 1

    local NewMyModData = {}


    for k, v in pairs(data) do
        if k ~= 0 then -- skip userdata
        NewMyModData[i] = k
        i = i + 1
        else
            NewMyModData[i] = "$__userdata" .. tostring(v)
        end
    end

    local mt = getmetatable(data)
    if mt then
        for k, v in pairs(mt.__index) do
            NewMyModData[i] = MyMod_MEATATABLE_KEY .. k
            i = i + 1
        end
    end

    function bykey(a, b)
        return tostring(a) < tostring(b)
    end

    table.sort(NewMyModData, bykey)

    NewMyModData.count = table.getn(NewMyModData)

    if saveParent then
        NewMyModData["parent"] = MyModData
    end

    if mt then
        NewMyModData["meta"] = mt.__index
    end
    NewMyModData["src"] = data
    MyModData = NewMyModData


    print(#MyModData .. " == " .. MyModData.count)
end

function MyMod_Table_Length(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function MyModScrollBar_Update()
    print("ok: " )
    local lineplusoffset ; -- an index into our data calculated from the scroll offset

    local scrollFrame = MyModScrollBar
    local buttons = scrollFrame.buttons;
    local offset = HybridScrollFrame_GetOffset(scrollFrame)

    for k, v in pairs(buttons) do

        lineplusoffset = k + offset;
        if lineplusoffset <= MyModData.count then
            MyMod_UpdateListItem(v, MyModData[lineplusoffset])

            v:Show();
        else
            v:Hide();
        end
    end

    HybridScrollFrame_Update(scrollFrame, MyModData.count * 16, 700);

    print("UPDATED")
end

function MyMod_Back_Button_Click()
    print("und0")
    if MyModData.parent then
        print("undo")
        MyModData = MyModData.parent
        MyModScrollBar_Update()
    end
end

function MyModEntry_ValueForKey(key)
    local value = MyModData["src"][key]
    local fromMT = false
    if not value and MyModData["meta"] then -- and key~= nil and string.len(key)>  string.len(MyMod_MEATATABLE_KEY) + 1 then
    key = string.sub(key, string.len(MyMod_MEATATABLE_KEY) + 1)
    value = MyModData["meta"][key]
    fromMT = true
    end
    --print(key .." ".. string.sub(key, string.len(MyMod_MEATATABLE_KEY)))

    return value, fromMT
end

function MyMod_UpdateListItem(node, key)
    local button = node.mainButton;


    local value, fromMT = MyModEntry_ValueForKey(key)




    local valueType = type(value)
    --local valueTypeStr = valueType
    --node:SetText(valueTypeStr .. ": " .. tostring(key));
    if valueType == "table" then


        -- print("function info: " .. tostring(type(info)))

        button:SetText(MyMod_Table_Length(value) .. " table " .. ": " .. tostring(key));
        button:SetNormalFontObject("GameFontGreen");
    elseif valueType == "userdata" then
        button:SetText(valueType .. ": " .. tostring(key));
        button:SetNormalFontObject("GameFontDisable");
    elseif valueType == "number" then
        button:SetText(valueType .. ": " .. tostring(key) .. " = " .. tostring(value));
        button:SetNormalFontObject("NumberFontNormalYellow");
    elseif valueType == "string" then
        button:SetText(valueType .. ": " .. tostring(key));
        button:SetNormalFontObject("GameFontRed");
    elseif valueType == "function" then

        button:SetText(valueType .. ": " .. tostring(key) .. " = " .. tostring(value));
        button:SetNormalFontObject("GameFontWhite");
    else
        button:SetText(valueType .. ": " .. tostring(key) .. " = " .. tostring(value));
        button:SetNormalFontObject("GameFontDisable");
    end



    if valueType == "table" or valueType == "userdata" then
        button:SetScript("OnMouseUp", function(self, button, down)
            print("click")
            -- local info = getmetatable(value)
            MyMod_LoadData(value, true)
            MyModScrollBar:SetVerticalScroll(0)
            MyModScrollBar_Update()
        end)
    elseif valueType == "function" then
        button:SetScript("OnMouseUp", function(self, button, down)
            print("click")
            local result = value()
            local resultType = type(result)
            local additionalInfo = ""
            if resultType == "string" or resultType == "number" then
                additionalInfo = tostring(result)
            end

            print("returns:  " .. resultType .. " " .. additionalInfo)
        end)
    else
        button:SetScript("OnMouseUp", nil)
    end
end
