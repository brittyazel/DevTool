local ViragDevTool = ViragDevTool


-----------------------------------------------------------------------------------------------
-- FUNCTION LOGGIN
-----------------------------------------------------------------------------------------------
function ViragDevTool:StartLogFunctionCalls(strParentPath, strFnToLog)
    --for now you have to tell exact table name can be _G can be something like ViragDevTool.table.table
    if strParentPath == nil then return end

    local savedInfo = self:GetLogFunctionCalls(strParentPath, strFnToLog)

    if savedInfo == nil then


        local tParent = self:FromStrToObject(strParentPath)
        if tParent == nil then
            self:Print(self.colors.red:WrapTextInColorCode("Error: ") ..
                    "Cannot add function monitoring: " ..
                    self.colors.lightblue:WrapTextInColorCode("_G." .. tostring(strParentPath) .. " == nil"))
            return
        end

        savedInfo = {
            parentTableName = strParentPath,
            fnName = strFnToLog,
            active = false
        }

        table.insert(self.db.profile.logs, savedInfo)
    end

    self:ActivateLogFunctionCalls(savedInfo)
end


function ViragDevTool:ActivateLogFunctionCalls(info)
    if info.active then return end

    local tParent = self:FromStrToObject(info.parentTableName) or {}

    local shrinkFn = function(table)
        if #table == 1 then
            return table[1]
        elseif #table == 0 then
            return nil
        end
        return table
    end

    for fnName, oldFn in pairs(tParent) do
        if type(oldFn) == "function" and
                (info.fnName == nil or fnName == info.fnName) then
            local savedOldFn = self:GetOldFn(tParent, fnName, oldFn)

            if savedOldFn == nil then
                self:SaveOldFn(tParent, fnName, oldFn)
                savedOldFn = self:GetOldFn(tParent, fnName, oldFn)
            end

            tParent[fnName] = function(...)
                local result = { savedOldFn(...) }
                local args = { ... }

                local fnNameWitArgs = self.colors.lightgreen:WrapTextInColorCode(fnName) ..
                        "(" .. self:argstostring(args) .. ")"
                --.. ViragDevTool.colors.lightblue

                self:AddData({
                    OUT = shrinkFn(result),
                    IN = shrinkFn(args)
                }, fnNameWitArgs)

                return unpack(result)
            end
        end
    end

    self:Print(self.colors.green:WrapTextInColorCode("Start") ..
            " function monitoring: " ..
            self.colors.lightblue:WrapTextInColorCode(self:LogFunctionCallText(info)))
    info.active = true
end

function ViragDevTool:DeactivateLogFunctionCalls(info)
    if not info.active then return end

    local tParent = self:FromStrToObject(info.parentTableName) or {}
    for fnName, oldFn in pairs(tParent) do
        if type(oldFn) == "function" and
                (info.fnName == nil or fnName == info.fnName) then
            tParent[fnName] = self:GetOldFn(tParent, fnName, oldFn)
        end
    end

    self:Print(self.colors.red:WrapTextInColorCode("Stop") ..
            " function monitoring: " ..
            self.colors.lightblue:WrapTextInColorCode(self:LogFunctionCallText(info)))
    info.active = false
end

function ViragDevTool:ToggleFnLogger(info)
    if info.active then
        self:DeactivateLogFunctionCalls(info)
    else
        self:ActivateLogFunctionCalls(info)
    end
end

function ViragDevTool:GetOldFn(tParent, fnName)
    if self.tempOldFns and
            self.tempOldFns[tParent] and
            self.tempOldFns[tParent][fnName] then
        return self.tempOldFns[tParent][fnName]
    end
end

function ViragDevTool:SaveOldFn(tParent, fnName, oldFn)
    if self.tempOldFns == nil then
        self.tempOldFns = {}
    end

    -- tParent is actual parent an not string name
    if self.tempOldFns[tParent] == nil then
        self.tempOldFns[tParent] = {}
    end

    -- clear
    if oldFn == nil then
        self.tempOldFns[tParent][fnName] = nil
    end

    --else save only if it doesn't exists
    if self.tempOldFns[tParent][fnName] == nil then
        self.tempOldFns[tParent][fnName] = oldFn
    end
end

function ViragDevTool:GetLogFunctionCalls(strParentTableName, strFnName)
    for _, v in pairs(self.db.profile.logs) do
        if v.parentTableName == strParentTableName
                and strFnName == v.fnName then
            return v
        end
    end
end

function ViragDevTool:LogFunctionCallText(info)
    if info == nil then return "" end

    local tableName = info.parentTableName == "_G" and "_G" or "_G." .. tostring(info.parentTableName)

    if info.fnName then
        return info.fnName .. " fn in " .. tableName

    else
        return "ALL fn in " .. tableName
    end
end