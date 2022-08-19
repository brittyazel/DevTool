local ViragDevTool = ViragDevTool


-----------------------------------------------------------------------------------------------
-- HISTORY
-----------------------------------------------------------------------------------------------
function ViragDevTool:AddToHistory(strValue)
    if self.db.profile.history then
        local hist = self.db.profile.history

        -- if already contains value then just move it to top
        for k, v in pairs(hist or {}) do
            if v == strValue then
                table.remove(hist, k)
                table.insert(hist, 1, strValue)
                self:UpdateSideBarUI()
                return
            end
        end

        table.insert(hist, 1, strValue)

        local maxSize = ViragDevTool_defaults.profile.MAX_HISTORY_SIZE
        if self.db.profile.MAX_HISTORY_SIZE then
            maxSize = self.db.profile.MAX_HISTORY_SIZE
        end

        while #hist > maxSize do -- can have only 10 values in history
            table.remove(hist, maxSize)
        end

        self:UpdateSideBarUI()
    end
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