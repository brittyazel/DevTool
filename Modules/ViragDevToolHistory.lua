local ViragDevTool = ViragDevTool


-----------------------------------------------------------------------------------------------
-- HISTORY
-----------------------------------------------------------------------------------------------
function ViragDevTool:AddToHistory(strValue)
    if self.settings and self.settings.history then
        local hist = self.settings.history

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

        local maxSize = self.default_settings.MAX_HISTORY_SIZE
        if self.settings and self.settings.MAX_HISTORY_SIZE then
            maxSize = self.settings.MAX_HISTORY_SIZE
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