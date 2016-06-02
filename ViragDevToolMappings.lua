local ViragDevTool = ViragDevTool

--- this is just example demo how you can use this file to explore api.
-- lets suppose we want to look into default api
-- then we can add all variables manualy to some table and add tis table with ViragDevTool_AddData
-- but we could create this table dinamicaly if we know prefix name
function ViragDevTool:AddToMapping(strName, containsSearch)
    local fn = containsSearch and string.match or self.starts
    self.mapping[strName] = self:FindIn(_G, strName, fn)
end

function ViragDevTool:FindIn(parent, strName, fn)
    local resultTable = {}

    for k, v in pairs(parent or {}) do
        if fn(k, strName) then
            resultTable[k] = v
        end
    end

    return resultTable
end

function ViragDevTool.starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

function ViragDevTool.ends(String, End)
    return End == '' or string.sub(String, -string.len(End)) == End
end


--here or in any other place you can change mappings
--ViragDevTool:AddToMapping("LFD")
--ViragDevTool:AddToMapping("LFR")
--ViragDevTool:AddToMapping("LFG")
--ViragDevTool:AddToMapping("Virag")

