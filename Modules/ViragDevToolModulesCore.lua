local ViragDevTool = ViragDevTool

--TODO not implemented yet just an idea .Dont have time for this right now
--- This class handles modules that can be registered in this addon.
-- if you want to create custom module it has to implement following methods
-- module lifecicle is
-- 1) Register your module
-- local newModule = ...
-- ViragDevTool:AddModule(newModule)
-- 2) for now every module gets module:Init() on startup
-- 3) every module gets module:Load() if user clics on module tab
-- 4) module:UnLoad() if user clicks on some other tab other then your modules
-- 5) module:UpdateModuleUI(sideFrame) can be called at any time
--    and here you have to update sidebar scroll list items
-- 6) module:UpdateRow(rowFrame, numRowId) can be called at any time
--    and here you have to update given raw for mait scrollframe table
-- 7) module:ProcessMsg(msg) can be called at any time
--    and myou have to handle message from ui
--local ViragDevToolModule = {}
--function ViragDevToolModule:GetName() end
--function ViragDevToolModule:Init() end
--function ViragDevToolModule:Load() end
--function ViragDevToolModule:UnLoad() end
--function ViragDevToolModule:UpdateModuleUI(sideFrame) end
--function ViragDevToolModule:UpdateRow(rowFrame, numRowId) end
--function ViragDevToolModule:ProcessMsg(msg) end
--[[
function ViragDevTool:AddModule(module)
    if self.modules == nil then
        self.modules = {}
    end

    table.insert(self.modules, module)
end
]]--