-- DevTool is a World of Warcraft® addon development tool.
-- Copyright (c) 2021-2025 Britt W. Yazel
-- Copyright (c) 2016-2021 Peter aka "Varren"
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace
local DevTool = addonTable.DevTool

-----------------------------------------------------------------------------------------------
--- UTILS
-----------------------------------------------------------------------------------------------

--- Math

function DevTool.round(num, idp)
	if not num then
		return nil
	end
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function DevTool.CalculatePosition(pos, min, max)
	if pos < min then
		pos = min
	end
	if pos > max then
		pos = max
	end
	return pos
end


--- String

function DevTool.split(str, sep)
	local separator, fields
	separator, fields = sep or ".", {}
	local pattern = string.format("([^%s]+)", separator)
	string.gsub(str, pattern, function(c)
		fields[#fields + 1] = c
	end)
	return fields
end

function DevTool.starts(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

function DevTool.ends(String, End)
	return End == '' or string.sub(String, -string.len(End)) == End
end

function DevTool.ArgsToString(args)
	local strArgs = ""
	local found = false
	local delimiter = ""
	for i = 10, 1, -1 do
		if args[i] ~= nil then
			found = true
		end

		if found then
			strArgs = tostring(args[i]) .. delimiter .. strArgs
			delimiter = ", "
		end
	end
	return strArgs
end

function DevTool.FindIn(parent, strName, fn)
	local resultTable = {}

	for k, v in pairs(parent or {}) do
		if fn(k, strName) then
			resultTable[k] = v
		end
	end

	return resultTable
end


--- Table

function DevTool.FindIndex(table, item)
	for k, v in pairs(table) do
		if v == item then
			return k
		end
	end
	return nil;
end

function DevTool.CountElements(t)
	local count = 0
	for _, _ in pairs(t) do
		count = count + 1
	end
	return count
end

function DevTool.FromStrToObject(str)
	if str == "_G" then
		return _G
	end

	local vars = DevTool.split(str, ".") or {}

	local var = _G
	for _, name in pairs(vars) do
		if var then
			var = var[name]
		end
	end

	return var
end


--- Miscellaneous

function DevTool.SelectSortFunction(tableLength)
	local compareFn

	--fast filter
	if tableLength > 20000 then
		--optimizing for _G
		compareFn = function(a, b)
			return a.name < b.name
		end
	elseif tableLength < 300 then

		--thorough filter
		--lets try some better sorting if we have small number of records
		--numbers will be sorted not like 1,10,2 but like 1,2,10
		compareFn = function(a, b)
			if a.name == "__index" then
				return true
			elseif b.name == "__index" then
				return false
			else
				if tonumber(a.name) ~= nil and tonumber(b.name) ~= nil then
					return tonumber(a.name) < tonumber(b.name)
				else
					return a.name < b.name
				end
			end
		end
	else
		--default filter
		compareFn = function(a, b)
			if a.name == "__index" then
				return true
			elseif b.name == "__index" then
				return false
			else
				return a.name < b.name
			end
		end
	end

	return compareFn
end

function DevTool.ToUIString(value, name, withoutLineBrakes)
	local result
	local valueType = type(value)

	if valueType == "table" then
		result = DevTool.GetObjectInfoFromWoWAPI(name, value) or tostring(value)
		result = "(" .. DevTool.CountElements(value) .. ") " .. result
	else
		result = tostring(value)
	end

	if withoutLineBrakes then
		result = string.gsub(string.gsub(tostring(result), "|n", ""), "\n", "")
	end

	return result
end

function DevTool.GetObjectInfoFromWoWAPI(helperText, value)
	local resultStr
	local ok, objectType = DevTool.TryCallAPIFn("GetObjectType", value)

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

		local _, name = DevTool.TryCallAPIFn("GetName", value)
		local _, texture = DevTool.TryCallAPIFn("GetTexture", value)
		local _, text = DevTool.TryCallAPIFn("GetText", value)

		local hasSize, left, bottom, width, height = DevTool.TryCallAPIFn("GetBoundsRect", value)

		resultStr = objectType or ""
		if hasSize then
			resultStr = concat("[" ..
					tostring(DevTool.round(left)) .. ", " ..
					tostring(DevTool.round(bottom)) .. ", " ..
					tostring(DevTool.round(width)) .. ", " ..
					tostring(DevTool.round(height)) .. "]")
		end

		if helperText ~= name then
			resultStr = concat(name, DevTool.colors.gray:WrapTextInColorCode("<"), DevTool.colors.gray:WrapTextInColorCode(">"))
		end

		resultStr = concat(texture)
		resultStr = concat(text, "'", "'")
		resultStr = concat(tostring(value))
	end

	return resultStr
end

function DevTool.TryCallAPIFn(fnName, value)
	-- this function is helper fn to get table type from wow api.
	-- if there is GetObjectType then we will return it.
	-- returns Button, Frame or something like this

	-- VALIDATION
	if type(value) ~= "table" then
		return
	end

	-- VALIDATION FIX if __index is function we don't want to execute it
	-- Example in ACP.L
	local metatable = getmetatable(value)
	if metatable and type(metatable) == "table" and type(metatable.__index) == "function" then
		return
	end

	-- VALIDATION is forbidden from wow api
	if value.IsForbidden then
		local ok, forbidden = pcall(value.IsForbidden, value)
		if not ok or (ok and forbidden) then
			return
		end
	end

	local fn = value[fnName]
	-- VALIDATION has WoW API
	if not fn or type(fn) ~= "function" then
		return
	end

	-- MAIN PART:
	return pcall(fn, value)
end

function DevTool.TryCallFunctionWithArgs(fn, args)
	local results = { pcall(fn, unpack(args, 1, 10)) }
	local ok = results[1]
	table.remove(results, 1)
	return ok, results
end

function DevTool.IsMetaTableNode(info)
	return info.name == "$metatable" or info.name == "$metatable.__index" or (info.name == "__index" and info.parent and info.parent.name == "$metatable")
end

function DevTool.GetParentTable(info)
	local parent = info.parent
	if parent and (parent.value == _G or parent == DevTool.list) then
		-- this fn is in global namespace, or has no parent
		parent = nil
	end

	if parent then
		while DevTool.IsMetaTableNode(parent) do
			-- metatable has real object 1 level higher
			parent = parent.parent
		end
	end

	return parent
end