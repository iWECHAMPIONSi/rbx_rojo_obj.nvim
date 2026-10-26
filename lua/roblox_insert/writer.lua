local data = require("roblox_insert.data")
local helpers = require("roblox_insert.helpers")
local dir_select = require("roblox_insert.dir_select")

local vim = vim

local t = {}

local function find_closest_class(class)
	local closest_match = nil
	local closest_score = 5
	for i in pairs(data.raw.Classes) do
		local distance = helpers.levenshtein(class, i)
		if distance <= closest_score then
			closest_score = distance
			closest_match = i
		end
	end

	return closest_match
end

---@param class string
---@param params {string: any}
---@return table?, string?
local function create_file_data(class, params, meta, init)
	local class_table = data.raw.Classes[class]
	if not class_table then
		local estimate = find_closest_class(class)
		if estimate then
			vim.notify(
				"No class with the name '" .. class .. "' found, did you mean '" .. estimate .. "'?",
				vim.log.levels.ERROR
			)
		else
			vim.notify("No class with the name '" .. class .. "' found.", vim.log.levels.ERROR)
		end
		return nil
	end
	local file = {}
	if not meta and not init then
		file.ClassName = class
		file.Properties = next(params) and params or vim.empty_dict()
	else
		file.properties = next(params) and params or vim.empty_dict()
		if init and not string.find(class, "Script", 1, true) then
			file.className = class
		end
	end
	return file
end

t.create_file_data = create_file_data

---@param file_name string
---@param class string
---@param params {string: any}
---@param dir string?
---@param meta boolean?
---@param init boolean?
---@return nil
local function create_file(file_name, class, params, dir, meta, init)
	dir = dir or vim.fn.expand("%:p:h")
	local contents = create_file_data(class, params, meta, init)
	if not contents then
		return nil
	end
	local json = vim.json.encode(contents, {
		indent = "    ",
	})
	local function on_success()
		local path
		if not meta then
			path = vim.fs.joinpath(dir, file_name .. ".model.json")
		else
			local result
			local meta_name
			if init then
				vim.fn.mkdir(vim.fs.joinpath(dir, file_name), "p")
				dir = vim.fs.joinpath(dir, file_name)
				path = vim.fs.joinpath(dir, "init.meta.json")
				if string.find(class, "Script", 1, true) then
					if class == "LocalScript" then
						meta_name = vim.fs.joinpath(dir, "init.client.luau")
						result =
							vim.fn.writefile(vim.split('print("Hello World!")\n', "\n", { plain = true }), meta_name)
					elseif class == "ModuleScript" then
						meta_name = vim.fs.joinpath(dir, "init.luau")
						result = vim.fn.writefile(
							vim.split("local module = {}\n\nreturn module\n", "\n", { plain = true }),
							meta_name
						)
					elseif class == "Script" then
						meta_name = vim.fs.joinpath(dir, "init.server.luau")
						result =
							vim.fn.writefile(vim.split('print("Hello World!")\n', "\n", { plain = true }), meta_name)
					end
					if result ~= 0 then
						vim.notify("Failed to write file: " .. (meta_name or file_name), vim.log.levels.ERROR)
						return
					end
				end
			else
				if string.find(class, "Script", 1, true) then
					path = vim.fs.joinpath(dir, file_name .. ".meta.json")
					if class == "LocalScript" then
						meta_name = vim.fs.joinpath(dir, file_name .. ".client.luau")
						result =
							vim.fn.writefile(vim.split('print("Hello World!")\n', "\n", { plain = true }), meta_name)
					elseif class == "ModuleScript" then
						meta_name = vim.fs.joinpath(dir, file_name .. ".luau")
						result = vim.fn.writefile(
							vim.split("local module = {}\n\nreturn module\n", "\n", { plain = true }),
							meta_name
						)
					elseif class == "Script" then
						meta_name = vim.fs.joinpath(dir, file_name .. ".server.luau")
						result =
							vim.fn.writefile(vim.split('print("Hello World!")\n', "\n", { plain = true }), meta_name)
					end
				end
				if result ~= 0 then
					vim.notify("Failed to write file: " .. (meta_name or file_name), vim.log.levels.ERROR)
					return
				end
			end
			if ((not next(params)) and not init) or ((not next(params)) and string.find(class, "Script", 1, true)) then
				return
			end
		end

		local result = vim.fn.writefile(vim.split(json, "\n", { plain = true }), path)

		if result ~= 0 then
			vim.notify("Failed to write file: " .. path, vim.log.levels.ERROR)
		end
	end
	dir_select.check_name_collision(dir, file_name, on_success)
end

t.create_file = create_file

---@param class string
---@param path string
---@param params table
---@param init boolean?
---@param script boolean?
local function edit_file(class, path, params, init, script)
	if vim.uv.fs_stat(path) or script then
		local contents = create_file_data(class, params, script, init)
		if not contents then
			return nil
		end
		local json = vim.json.encode(contents, {
			indent = "    ",
		})
		local result = vim.fn.writefile(vim.split(json, "\n", { plain = true }), path)
		if result ~= 0 then
			vim.notify("Failed to write file: " .. path, vim.log.levels.ERROR)
		end
	else
		vim.notify("File does not exist: " .. path, vim.log.levels.ERROR)
	end
end

t.edit_file = edit_file

return t
