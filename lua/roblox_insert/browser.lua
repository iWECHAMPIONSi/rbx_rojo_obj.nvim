local m = {}
local data = require("roblox_insert.data")
local writer = require("roblox_insert.writer")
local dir_select = require("roblox_insert.dir_select")
local helpers = require("roblox_insert.helpers")
local create_input = dir_select.create_input
local config = require("roblox_insert.config")
local assign_command = config.assign_command

local roblox_types = require("roblox_insert.roblox_types")

local current_class = nil
local search = false

---@param t string
---@return string?
local function handle_nil(t)
	if t == "nil" then
		return nil
	end
	return t
end

local vim = vim

local class_list_ref = {}
local properties_list_ref = {}
local expanded_categories = {
	["Favorites"] = true,
	["3D Interfaces"] = true,
	["Adornments"] = true,
	["Ads"] = true,
	["Animations"] = true,
	["Avatar"] = true,
	["Constraints"] = true,
	["Effects"] = true,
	["Environment"] = true,
	["GUI"] = true,
	["Input"] = true,
	["Interaction"] = true,
	["Lights"] = true,
	["Localization"] = true,
	["Parts"] = true,
	["Post Processing Effects"] = true,
	["Scripting"] = true,
	["Sensors"] = true,
	["Sounds"] = true,
	["Styling"] = true,
	["Text Chat"] = true,
	["Uncategorized"] = true,
	["Values"] = true,
	["World"] = true,
	["AnimationInfo"] = true,
	["Backpack"] = true,
	["Controllers"] = true,
	["Data Store"] = true,
	["Dragger"] = true,
	["Other"] = true,
	["Posing"] = true,
	["Text Chat Properties"] = true,
}

---@param args {contents: string[]?, buffer_type: string?, width: number, height: number, col: number, row: number, border: string[][]?, title: string?, title_pos: string?, footer: string?, footer_pos: string?, [any]: any}
---@return number, number
local function create_window(args)
	local buf = vim.api.nvim_create_buf(false, true)
	args.buf = buf

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, args.contents or {})

	vim.api.nvim_set_option_value("buftype", args.buffer_type or "nofile", { buf = buf })
	vim.api.nvim_set_option_value("modifiable", args.buffer_type == "prompt", { buf = buf })
	if args.buffer_type then
		vim.fn.prompt_setprompt(buf, "")
	end

	local win = vim.api.nvim_open_win(buf, args.focus == true, {
		relative = "editor",
		width = args.width,
		height = args.height,
		col = args.col,
		row = args.row,
		style = "minimal",
		border = args.border or "rounded",
		title = args.title,
		title_pos = args.title_pos,
		footer = args.footer,
		footer_pos = args.footer_pos,
	})
	vim.wo[win].winhighlight = "NormalFloat:RbxBrowser"
	if not (args.buffer_type == "prompt") and not args.contents then
		vim.wo[win].cursorline = true
		vim.wo[win].cursorlineopt = "line"
		vim.wo[win].winhighlight = vim.wo[win].winhighlight .. ",CursorLine:RbxSelected"
	end

	args.win = win

	return buf, win
end

m.create_window = create_window

---@param t string
---@param properties_table table
---@param name string
---@param dimensions table
---@param when_done function
---@param enumeration string?
---@param disp boolean
---@param focus_win number
local function disp_property(t, properties_table, name, dimensions, when_done, enumeration, disp, focus_win)
	if not dimensions.win then
		dimensions.title = "Property Editor"
		dimensions.focus = true
		local buf, win = create_window(dimensions)
		local function close_property()
			vim.api.nvim_set_current_win(focus_win)
			if when_done then
				when_done()
			end
		end

		assign_command(buf, "CloseProperty", config.config.keybinds.close_property, close_property)

		dimensions.buf, dimensions.win = buf, win
		return
	else
		vim.api.nvim_win_set_config(dimensions.win, {
			title = t,
		})
	end
	local value_type = roblox_types[t]
	local highlights = {}
	local err_msg = nil
	local valid = false
	local global_ref = nil

	local function disp_table(props, value_ref, field_ref, buf, win, override_table, str)
		str = str or {}
		highlights = {}
		table.insert(str, 1, "Can Export: " .. tostring(valid))
		table.insert(highlights, 1, {
			row = 0,
			start_col = #"Can Export: ",
			end_col = #"Can Export: " + (valid and #"true" or #"false"),
			hl_group = config.hl_group.RbxBoolean,
		})
		if not valid and err_msg then
			str[1] = str[1] .. " (" .. err_msg .. ")"
			table.insert(highlights, 2, {
				row = 0,
				start_col = #"Can Export: false (",
				end_col = #str[1] - 1,
				hl_group = config.hl_group.RbxError,
			})
		end
		local add_index = #str

		if override_table or props and props.value then
			for i, field in ipairs(value_type.fields) do
				table.insert(highlights, {
					row = i - 1 + add_index,
					start_col = 0,
					end_col = #field,
					hl_group = config.hl_group.RbxProperty,
				})
				table.insert(str, field .. ": " .. (value_ref[field] or ""))
				if value_ref[field] then
					table.insert(highlights, {
						row = i - 1 + add_index,
						start_col = #field + 2,
						end_col = #str[i + add_index],
						hl_group = (tonumber(value_ref[field]) and config.hl_group.RbxNumber)
							or (value_ref[field] == "false" and config.hl_group.RbxBoolean)
							or (value_ref[field] == "true" and config.hl_group.RbxBoolean)
							or config.hl_group.RbxValue,
					})
				end
				table.insert(field_ref, function()
					create_input(field, t, value_ref[field], function(value)
						value_ref[field] = value or value_ref[field]
						value_ref[field] = handle_nil(value_ref[field])
						str[i + add_index] = field .. ": " .. (value_ref[field] or "")
						local _
						valid, _, _, err_msg = value_type.verification(global_ref or value_ref)
						str[1] = "Can Export: " .. tostring(valid)
						vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
						vim.api.nvim_buf_clear_namespace(buf, config.ns, 0, 1)
						vim.api.nvim_buf_clear_namespace(buf, config.ns, i - 1 + add_index, i + add_index)
						if not valid and err_msg then
							str[1] = str[1] .. " (" .. err_msg .. ")"
							vim.api.nvim_buf_set_lines(buf, 0, 1, false, { str[1] })
							vim.api.nvim_buf_set_extmark(buf, config.ns, 0, #"Can Export: false (", {
								end_col = #str[1] - 1,
								hl_group = config.hl_group.RbxError,
							})
						else
							vim.api.nvim_buf_set_lines(buf, 0, 1, false, { str[1] })
						end
						vim.api.nvim_buf_set_extmark(buf, config.ns, 0, #"Can Export: ", {
							end_col = #"Can Export: " + (valid and #"true" or #"false"),
							hl_group = config.hl_group.RbxBoolean,
						})
						vim.api.nvim_buf_set_lines(buf, i - 1 + add_index, i + add_index, false, { str[i + add_index] })
						vim.api.nvim_buf_set_extmark(buf, config.ns, i - 1 + add_index, 0, {
							end_col = #field,
							hl_group = config.hl_group.RbxProperty,
						})
						vim.api.nvim_buf_set_extmark(buf, config.ns, i - 1 + add_index, #field + 2, {
							end_col = #str[i + add_index],
							hl_group = (tonumber(value_ref[field]) and config.hl_group.RbxNumber)
								or ((value_ref[field] == "true" or value_ref[field] == "false") and config.hl_group.RbxBoolean)
								or config.hl_group.RbxValue,
						})
						vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
					end)
				end)
			end
		else
			for i, field in ipairs(value_type.fields) do
				table.insert(highlights, {
					row = i - 1 + add_index,
					start_col = 0,
					end_col = #field,
					hl_group = config.hl_group.RbxProperty,
				})
				table.insert(str, field .. ":")
				table.insert(field_ref, function()
					create_input(field, t, value_ref[field], function(value)
						value_ref[field] = value or value_ref[field]
						value_ref[field] = handle_nil(value_ref[field])
						str[i + add_index] = field .. ": " .. (value_ref[field] or "")
						local _
						valid, _, _, err_msg = value_type.verification(global_ref or value_ref)
						str[1] = "Can Export: " .. tostring(valid)
						vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
						vim.api.nvim_buf_clear_namespace(buf, config.ns, 0, 1)
						vim.api.nvim_buf_clear_namespace(buf, config.ns, i - 1 + add_index, i + add_index)
						if not valid and err_msg then
							str[1] = str[1] .. " (" .. err_msg .. ")"
							vim.api.nvim_buf_set_lines(buf, 0, 1, false, { str[1] })
							vim.api.nvim_buf_set_extmark(buf, config.ns, 0, #"Can Export: false (", {
								end_col = #str[1] - 1,
								hl_group = config.hl_group.RbxError,
							})
						else
							vim.api.nvim_buf_set_lines(buf, 0, 1, false, { str[1] })
						end
						vim.api.nvim_buf_set_extmark(buf, config.ns, 0, #"Can Export: ", {
							end_col = #"Can Export: " + (valid and #"true" or #"false"),
							hl_group = config.hl_group.RbxBoolean,
						})
						vim.api.nvim_buf_set_lines(buf, i - 1 + add_index, i + add_index, false, { str[i + add_index] })
						vim.api.nvim_buf_set_extmark(buf, config.ns, i - 1 + add_index, 0, {
							end_col = #field,
							hl_group = config.hl_group.RbxProperty,
						})
						vim.api.nvim_buf_set_extmark(buf, config.ns, i - 1 + add_index, #field + 2, {
							end_col = #str[i + add_index],
							hl_group = (tonumber(value_ref[field]) and config.hl_group.RbxNumber)
								or ((value_ref[field] == "true" or value_ref[field] == "false") and config.hl_group.RbxBoolean)
								or config.hl_group.RbxValue,
						})
						vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
					end)
				end)
			end
		end
		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, str)
		vim.api.nvim_buf_clear_namespace(buf, config.ns, 0, -1)
		vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
		for _, hl in ipairs(highlights) do
			vim.api.nvim_buf_set_extmark(buf, config.ns, hl.row, hl.start_col, {
				end_col = hl.end_col,
				hl_group = hl.hl_group,
			})
		end

		local function select_property_field()
			local line = vim.api.nvim_win_get_cursor(win)[1]
			field_ref[line]()
		end

		assign_command(buf, "SelectPropertyField", config.config.keybinds.select_property_field, select_property_field)
	end

	local function disp_single_field()
		local str_valid = "Can Export: " .. tostring(valid)
		vim.api.nvim_set_option_value("modifiable", true, { buf = dimensions.buf })
		vim.api.nvim_buf_clear_namespace(dimensions.buf, config.ns, 0, -1)
		if not valid and err_msg then
			str_valid = str_valid .. " (" .. err_msg .. ")"
			vim.api.nvim_buf_set_lines(dimensions.buf, 0, -1, false, { str_valid })
			vim.api.nvim_buf_set_extmark(dimensions.buf, config.ns, 0, #"Can Export: false (", {
				end_col = #str_valid - 1,
				hl_group = config.hl_group.RbxError,
			})
		else
			vim.api.nvim_buf_set_lines(dimensions.buf, 0, -1, false, { str_valid })
		end
		vim.api.nvim_buf_set_extmark(dimensions.buf, config.ns, 0, #"Can Export: ", {
			end_col = #"Can Export: " + (valid and #"true" or #"false"),
			hl_group = config.hl_group.RbxBoolean,
		})
		vim.api.nvim_buf_set_lines(
			dimensions.buf,
			1,
			2,
			false,
			{ "Value: " .. (properties_table[name] and properties_table[name].value or "") }
		)
		vim.api.nvim_buf_set_extmark(dimensions.buf, config.ns, 1, 0, {
			end_col = #"Value: ",
			hl_group = config.hl_group.RbxProperty,
		})
		vim.api.nvim_buf_set_extmark(dimensions.buf, config.ns, 1, #"Value" + 2, {
			end_col = #("Value: " .. (properties_table[name] and properties_table[name].value or "")),
			hl_group = (
				tonumber(properties_table[name] and properties_table[name].value or nil) and config.hl_group.RbxNumber
			)
				or (properties_table[name] and (properties_table[name].value == "true" or properties_table[name].value == "false") and config.hl_group.RbxBoolean)
				or config.hl_group.RbxValue,
		})
		vim.api.nvim_set_option_value("modifiable", false, { buf = dimensions.buf })
	end

	if value_type.lua_type == "enum" then
		local _
		if properties_table[name] and properties_table[name].value then
			valid, _, err_msg = value_type.verification(enumeration, properties_table[name].value)
		else
			valid, err_msg = false, nil
		end
		disp_single_field()

		if not disp then
			create_input(name, t, properties_table[name] and properties_table[name].value or nil, function(value)
				local val
				valid, val, err_msg = value_type.verification(enumeration, value)
				if valid then
					if val == nil then
						properties_table[name] = nil
					else
						properties_table[name] = {
							json = {
								Enum = val,
							},
							value = value,
						}
					end
				end
				if properties_table[name] and properties_table[name].value then
					valid, _, err_msg = value_type.verification(enumeration, properties_table[name].value)
				else
					valid, err_msg = false, nil
				end
				disp_single_field()
				when_done()
			end)
		end
		return
	end

	if value_type.lua_type ~= "table" and value_type.lua_type ~= "nested table" then
		local _
		if properties_table[name] and properties_table[name].value then
			valid, _, err_msg = value_type.verification(properties_table[name] and properties_table[name].value or nil)
		else
			valid, err_msg = false, nil
		end
		disp_single_field()
		if not disp then
			create_input(
				value_type.fields[1],
				t,
				properties_table[name] and properties_table[name].value or nil,
				function(value)
					local val
					valid, val, err_msg = value_type.verification(value)
					if valid then
						if val == nil then
							properties_table[name] = nil
						else
							properties_table[name] = {
								json = {
									[t] = val,
								},
								value = value,
							}
						end
					end
					if properties_table[name] and properties_table[name].value then
						valid, _, err_msg =
							value_type.verification(properties_table[name] and properties_table[name].value or nil)
					else
						valid, err_msg = false, nil
					end
					disp_single_field()
					when_done()
				end
			)
		end
		return
	end

	if value_type.lua_type == "table" then
		local field_ref = { function() end }
		local value_ref = {}
		local props = properties_table[name]

		local buf, win = dimensions.buf, dimensions.win
		if not disp then
			vim.api.nvim_set_current_win(win)
		end
		if props and props.value then
			value_ref = vim.deepcopy(props.value)
		end

		local _

		valid, _, _, err_msg = value_type.verification(value_ref)

		disp_table(props, value_ref, field_ref, buf, win, nil, nil)

		local function export_property()
			local value, validated_table
			valid, value, validated_table, err_msg = value_type.verification(value_ref)
			if valid then
				properties_table[name] = {
					json = {
						[t] = value,
					},
					value = vim.deepcopy(validated_table),
				}
			elseif properties_table[name] and not properties_table[name].json or not properties_table[name] then
				properties_table[name] = {
					value = vim.deepcopy(value_ref),
				}
			end
			when_done(not config.config.return_to_class_disp)
			if not config.config.return_to_class_disp then
				props = properties_table[name]
				if props and props.value then
					value_ref = vim.deepcopy(props.value)
				end
				field_ref = { function() end }
			else
				vim.cmd.CloseProperty()
			end
			disp_table(props, value_ref, field_ref, buf, win)
		end

		assign_command(buf, "ExportProperty", config.config.keybinds.export_property, export_property)
	end

	if value_type.lua_type == "nested table" then
		local props = properties_table[name]

		local value_ref = props and vim.deepcopy(props.value) or { {} }

		local index = 1
		local buf, win = dimensions.buf, dimensions.win
		if not disp then
			vim.api.nvim_set_current_win(win)
		end
		valid, _, _, err_msg = value_type.verification(value_ref)
		global_ref = value_ref
		disp_table(
			nil,
			value_ref[index],
			{ function() end, function() end },
			buf,
			win,
			value_ref[index],
			{ index .. "/" .. #value_ref }
		)

		local function prev_keypoint()
			if index == 1 then
				return
			end
			if next(value_ref[index]) == nil then
				table.remove(value_ref, index)
			end
			valid, _, _, err_msg = value_type.verification(value_ref)
			global_ref = value_ref
			index = index - 1
			disp_table(
				nil,
				value_ref[index],
				{ function() end, function() end },
				buf,
				win,
				value_ref[index],
				{ index .. "/" .. #value_ref }
			)
		end

		assign_command(buf, "PrevKeypoint", config.config.keybinds.prev_keypoint, prev_keypoint)

		local function next_keypoint()
			if next(value_ref[index]) == nil then
				return
			end
			index = index + 1
			value_ref[index] = value_ref[index] or {}
			valid, _, _, err_msg = value_type.verification(value_ref)
			global_ref = value_ref
			disp_table(
				nil,
				value_ref[index],
				{ function() end, function() end },
				buf,
				win,
				value_ref[index],
				{ index .. "/" .. #value_ref }
			)
		end

		assign_command(buf, "NextKeypoint", config.config.keybinds.next_keypoint, next_keypoint)

		local function export_property()
			local value, validated_table
			valid, value, validated_table, err_msg = value_type.verification(value_ref)
			if valid then
				properties_table[name] = {
					json = {
						[t] = value,
					},
					value = vim.deepcopy(validated_table),
				}
			elseif properties_table[name] and not properties_table[name].json or not properties_table[name] then
				properties_table[name] = {
					value = vim.deepcopy(value_ref),
				}
			end
			when_done(not config.config.return_to_class_disp)
			if not config.config.return_to_class_disp then
				props = properties_table[name]
				value_ref = props and vim.deepcopy(props.value) or value_ref
				if not value_ref[index] then
					index = math.max(1, math.min(#value_ref, index))
				end
				global_ref = value_ref
				disp_table(
					nil,
					value_ref[index],
					{ function() end, function() end },
					buf,
					win,
					value_ref[index],
					{ index .. "/" .. #value_ref }
				)
			else
				vim.cmd.CloseProperty()
			end
		end

		assign_command(buf, "ExportProperty", config.config.keybinds.export_property, export_property)
	end
end

m.disp_property = disp_property

---@param buf number
---@param class string
---@param inside_buf boolean
---@param edit_class boolean?
local function disp_class(buf, class, inside_buf, edit_class)
	local class_def = data.raw.Classes[class]
	if not class_def then
		error("unreachble state reached! Class: " .. class)
	end

	local saved_object_properties = data.saved_object_configs[class]
	local index = saved_object_properties.index or 1
	saved_object_properties.index = index
	local saved_property_tables = saved_object_properties.property_tables
	local saved_properties = saved_property_tables[index] or { properties = {}, init_meta = false }
	saved_property_tables[index] = saved_properties
	local properties = saved_properties.properties

	if inside_buf then
		properties_list_ref = {
			{ t = "name", name = class },
			{ t = "config", name = class },
			{ t = "config", name = class },
			{ t = "init", name = saved_properties.init_meta, saved_props = saved_properties },
			{ t = "name", name = class },
		}
	end

	local str = {
		"Class: " .. class,
		"Current Config: " .. (saved_properties.name or ""),
		"Config: " .. (((not edit_class) and (index .. "/" .. #saved_property_tables)) or "Editing Class"),
		"As Directory: " .. tostring(saved_properties.init_meta or false),
		"Properties:",
	}
	local highlights = {}
	table.insert(highlights, {
		row = 0,
		start_col = #"Class: ",
		end_col = #str[1],
		hl_group = config.hl_group.RbxClass,
	})
	table.insert(highlights, {
		row = 1,
		start_col = #"Current Config: ",
		end_col = #str[2],
		hl_group = config.hl_group.RbxValue,
	})
	if not edit_class then
		table.insert(highlights, {
			row = 2,
			start_col = #"Config: ",
			end_col = #"Config: " + 1 + #tostring(index) - 1,
			hl_group = config.hl_group.RbxNumber,
		})
		table.insert(highlights, {
			row = 2,
			start_col = #"Config: " + #tostring(index) + 1,
			end_col = #str[3],
			hl_group = config.hl_group.RbxNumber,
		})
	else
		table.insert(highlights, {
			row = 2,
			start_col = #"Config: ",
			end_col = #str[3],
			hl_group = config.hl_group.RbxNumber,
		})
	end
	table.insert(highlights, {
		row = 3,
		start_col = #"As Directory: ",
		end_col = #str[4],
		hl_group = config.hl_group.RbxBoolean,
	})

	for _, p in ipairs(class_def.PropertyKeys) do
		local pre = properties[p] and properties[p].json and " *" or "  "
		local lstr = pre .. p .. ": "
		local ref_table
		local line = #str
		table.insert(highlights, {
			row = line,
			start_col = 2,
			end_col = 2 + #p,
			hl_group = config.hl_group.RbxProperty,
		})

		if class_def.Properties[p].ValueType.Category == "Enum" then
			lstr = lstr .. "Enum."
			if inside_buf then
				ref_table = { t = "Enum", enum = class_def.Properties[p].ValueType.Name, name = p }
			end
		else
			if inside_buf then
				ref_table = { t = class_def.Properties[p].ValueType.Name, name = p }
			end
		end
		lstr = lstr .. class_def.Properties[p].ValueType.Name
		local line_len = #lstr
		table.insert(highlights, {
			row = line,
			start_col = 2 + #p + 2,
			end_col = line_len,
			hl_group = config.hl_group.RbxDataType,
		})
		if #class_def.Properties[p].Tags > 0 then
			local tag_str = " [Tags: " .. table.concat(class_def.Properties[p].Tags, ", ") .. "]"
			lstr = lstr .. tag_str
		end
		table.insert(str, lstr)
		if inside_buf then
			ref_table.saved_props = saved_properties
			ref_table.props = saved_properties.properties
			ref_table.tags = class_def.Properties[p].Tags
			table.insert(properties_list_ref, ref_table)
		end
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, str)
	vim.api.nvim_buf_clear_namespace(buf, config.ns, 0, -1)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_set_extmark(buf, config.ns, hl.row, hl.start_col, {
			end_col = hl.end_col,
			hl_group = hl.hl_group,
		})
	end
end

m.disp_class = disp_class

---@param buf number
---@param init boolean
local function disp_class_list(buf, init)
	if init then
		class_list_ref = {}
	end
	local str = {}
	local keys = data.catkeys
	local categories = data.categories
	local highlights = {}

	for _, key in ipairs(keys) do
		if not data.browsable_categories[key] then
			break
		end
		if init then
			table.insert(class_list_ref, { t = "category", name = key })
		end
		if expanded_categories[key] then
			if init then
				table.insert(str, "v " .. key .. "/")
			end
			for _, class in ipairs(categories[key]) do
				if data.browsable_classes[class] then
					if init then
						table.insert(class_list_ref, { t = "class", name = class })
					end
					local pre = "  "
					if data.favorites[class] then
						pre = "* "
					end
					table.insert(str, pre .. class)
					local line = #str - 1
					table.insert(highlights, {
						row = line,
						text = class,
					})
				end
			end
		else
			table.insert(str, "> " .. key .. "/")
		end
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, str)
	vim.api.nvim_buf_clear_namespace(buf, config.ns, 0, -1)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_set_extmark(buf, config.ns, hl.row, 2, {
			end_col = #hl.text + 2,
			hl_group = config.hl_group.RbxClass,
		})
	end

	return str
end

m.disp_class_list = disp_class_list

---@param buf number
---@param category string
---@param line number
---@param favorite boolean
---@param added_class string?
local function modify_class_list(buf, category, line, favorite, added_class)
	local highlights = {}
	if not favorite then
		expanded_categories[category] = not expanded_categories[category]
	end
	if expanded_categories[category] then
		local str = { "v " .. category .. "/" }
		local i = 1
		local len = 0
		if favorite then
			local class_was_added = false
			for _, class in ipairs(data.categories[category]) do
				if class ~= added_class and data.browsable_classes[class] then
					len = len + 1
					table.remove(class_list_ref, 2)
				elseif class == added_class then
					class_was_added = true
				end
			end
			if not class_was_added then
				table.remove(class_list_ref, 2)
				len = len + 1
			end
		end
		for _, class in ipairs(data.categories[category]) do
			if data.browsable_classes[class] then
				table.insert(class_list_ref, line + i, { t = "class", name = class })
				i = i + 1
				local pre = "  "
				if data.favorites[class] then
					pre = "* "
				end
				table.insert(str, pre .. class)
				local iline = #str - 1
				table.insert(highlights, {
					row = iline + line - 1,
					text = class,
				})
			end
		end
		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
		if favorite then
			vim.api.nvim_buf_set_lines(buf, line - 1, line + len, false, str)
			vim.api.nvim_buf_clear_namespace(buf, config.ns, line - 1, line + len)
		else
			vim.api.nvim_buf_set_lines(buf, line - 1, line, false, str)
			vim.api.nvim_buf_clear_namespace(buf, config.ns, line - 1, line)
		end
		for _, hl in ipairs(highlights) do
			vim.api.nvim_buf_set_extmark(buf, config.ns, hl.row, 2, {
				end_col = #hl.text + 2,
				hl_group = config.hl_group.RbxClass,
			})
		end
		vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	elseif not favorite then
		local len = 0
		for _, class in ipairs(data.categories[category]) do
			if data.browsable_classes[class] then
				len = len + 1
				table.remove(class_list_ref, line + 1)
			end
		end
		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
		vim.api.nvim_buf_set_lines(buf, line - 1, line + len, false, { "> " .. category .. "/" })
		vim.api.nvim_buf_clear_namespace(buf, config.ns, line - 1, line + len)
		vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	end
end

---@param name string
---@param path string
---@param visual_path string
local function generate_dimensions(name, path, visual_path)
	local width = math.ceil((160 / 209) * vim.o.columns)
	local height = math.ceil((40 / 55) * vim.o.lines)

	if height - 6 <= 0 then
		vim.notify("Neovim window is too small, please make it larger", vim.log.levels.ERROR)
		return nil
	end

	local row = math.floor((vim.o.lines - height - 2) / 2)
	local col = math.floor((vim.o.columns - width - 2) / 2)
	return {
		path_bar = {
			title = 'Directory for "' .. name .. '"',
			title_pos = "left",
			width = width,
			height = 1,
			col = col,
			row = row,
			border = {
				{ "╭", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "╮", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "│", "FloatBorder" },
			},
			contents = { visual_path },
		},

		search_bar = {
			footer = "Search",
			footer_pos = "left",
			width = width,
			height = 1,
			col = col,
			row = row + height - 2,
			border = {
				{ "│", "FloatBorder" },
				{ "", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "╯", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "╰", "FloatBorder" },
				{ "│", "FloatBorder" },
			},
			buffer_type = "prompt",
			keybinds = function(buf, win, l_buf, l_win, p_win, d_win)
				local function close_browser()
					vim.api.nvim_win_close(win, true)
					vim.api.nvim_win_close(d_win, true)
					vim.api.nvim_win_close(l_win, true)
					vim.api.nvim_win_close(p_win, true)
				end

				assign_command(buf, "CloseBrowser", config.config.keybinds.close_browser_window, close_browser)

				vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
					buffer = buf,
					callback = function()
						local query = vim.fn.prompt_getinput(buf)
						if string.len(query) == 0 or query == "" then
							search = false
							disp_class_list(l_buf, true)
							return
						end
						search = true
						local str = {}
						local refs = {}
						local matches = {}

						query = string.lower(query)

						for class, _ in pairs(data.browsable_classes) do
							table.insert(matches, { name = class, lower_class = string.lower(class) })
						end

						matches = helpers.refine_search(vim.deepcopy(matches), query)

						for _, class in ipairs(matches) do
							local pre = data.favorites[class.name] and "* " or "  "

							table.insert(str, pre .. class.name)
							table.insert(refs, {
								t = "class",
								name = class.name,
							})
						end

						if #str == 0 then
							str = { "No matching classes" }
							refs = { { t = "nil", name = "" } }
						end

						class_list_ref = refs

						vim.api.nvim_set_option_value("modifiable", true, { buf = l_buf })
						vim.api.nvim_buf_set_lines(l_buf, 0, -1, false, str)
						vim.api.nvim_buf_clear_namespace(l_buf, config.ns, 0, -1)
						vim.api.nvim_set_option_value("modifiable", false, { buf = l_buf })
						for i = 1, #str do
							vim.api.nvim_buf_set_extmark(l_buf, config.ns, i - 1, 2, {
								end_col = #str[i],
								hl_group = config.hl_group.RbxClass,
							})
						end
					end,
				})

				local function enter_list()
					vim.cmd.stopinsert()
					vim.api.nvim_set_current_win(l_win)
				end

				assign_command(buf, "EnterList", config.config.keybinds.search_enter_list, enter_list)

				vim.keymap.set("i", "<CR>", function()
					vim.cmd.stopinsert()
					vim.api.nvim_set_current_win(l_win)
				end, { buffer = buf })
			end,
		},

		class_edit_box = {
			width = math.ceil(width / 2) - 1,
			height = height - 6,
			col = col,
			row = row + 2,
			focus = true,
			border = {
				{ "├", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "┬", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "┴", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "├", "FloatBorder" },
				{ "│", "FloatBorder" },
			},
		},

		class_list = {
			title = "Classes",
			title_pos = "center",
			width = math.ceil(width / 2) - 1,
			height = height - 6,
			col = col,
			row = row + 2,
			focus = true,
			border = {
				{ "├", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "┬", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "┴", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "├", "FloatBorder" },
				{ "│", "FloatBorder" },
			},
			keybinds = function(buf, win, d_buf, d_win, p_buf, p_win, s_win, class_edit_box)
				local function choose_new_dir()
					local args = dir_select.generate_dimensions()
					if not args then
						return
					end
					dir_select.resolve_source_directory(function()
						dir_select.make_dir_windows(args.path_bar)
						dir_select.make_dir_windows(args.directory)
						local function change_path(_, new_path, new_v_path)
							path = new_path
							vim.api.nvim_set_option_value("modifiable", true, { buf = p_buf })
							vim.api.nvim_buf_set_lines(p_buf, 0, -1, false, { new_v_path })
							vim.api.nvim_set_option_value("modifiable", false, { buf = p_buf })
							vim.api.nvim_win_close(args.path_bar.win, true)
							vim.api.nvim_win_close(args.directory.win, true)
							vim.api.nvim_set_current_win(win)
						end

						args.directory.keybinds(
							args.directory.buf,
							args.directory.win,
							args.path_bar.buf,
							args.path_bar.win,
							change_path,
							name,
							win
						)
					end)
				end

				assign_command(buf, "SelectDir", config.config.keybinds.choose_new_dir, choose_new_dir)

				local function rename_file()
					create_input("Name", "Leave bank to cancel, name cannot already exist", nil, function(value)
						if not value then
							return
						end
						dir_select.check_name_collision(path, value, function()
							name = value
							vim.api.nvim_win_set_config(p_win, {
								title = 'Directory for "' .. value .. '"',
							})
						end)
					end, "Change name")
				end

				assign_command(buf, "RenameFile", config.config.keybinds.rename_file, rename_file)

				local function close_browser()
					vim.api.nvim_win_close(win, true)
					vim.api.nvim_win_close(d_win, true)
					vim.api.nvim_win_close(s_win, true)
					vim.api.nvim_win_close(p_win, true)
				end

				assign_command(buf, "CloseBrowser", config.config.keybinds.close_browser_window, close_browser)

				local function start_search()
					vim.api.nvim_set_current_win(s_win)
					vim.cmd("startinsert!")
				end

				assign_command(buf, "StartSearch", config.config.keybinds.start_search, start_search)

				local function select_class()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					if not class_list_ref[line] then
						return
					end
					if class_list_ref[line].t == "class" then
						disp_property("", {}, "", class_edit_box, function() end, nil, true, d_win)
						current_class = class_list_ref[line].name
						vim.api.nvim_set_current_win(d_win)
						disp_class(d_buf, class_list_ref[line].name, true)
					elseif class_list_ref[line].t == "category" then
						modify_class_list(buf, class_list_ref[line].name, line, false)
					end
				end

				assign_command(buf, "SelectClass", config.config.keybinds.select_class, select_class)

				vim.api.nvim_create_autocmd("CursorMoved", {
					buffer = buf,
					callback = function()
						if not vim.api.nvim_win_is_valid(win) then
							return
						end

						local line = vim.api.nvim_win_get_cursor(win)[1]
						local ref = class_list_ref[line]

						if ref and ref.t == "class" then
							current_class = ref.name
							disp_class(d_buf, ref.name, false)
						end
					end,
				})

				local function toggle_favorite(line)
					local ref = class_list_ref[line[1]]

					if not ref or ref.t ~= "class" then
						return
					end

					local class = ref.name

					data.toggle_favorite(class)

					if not search then
						disp_class_list(buf, true)

						for i, entry in ipairs(class_list_ref) do
							if
								entry.t == "class"
								and entry.name == class
								and math.abs(i - vim.api.nvim_win_get_cursor(win)[1]) <= 1
							then
								vim.api.nvim_win_set_cursor(win, { i, 0 })
								break
							end
						end
					else
						local pre = data.favorites[class] and "* " or "  "

						vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
						vim.api.nvim_buf_set_lines(buf, line[1] - 1, line[1], false, {
							pre .. class,
						})
						vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
						vim.api.nvim_buf_clear_namespace(buf, config.ns, line[1] - 1, line[1])

						vim.api.nvim_buf_set_extmark(buf, config.ns, line[1] - 1, 2, {
							end_col = #class + 2,
							hl_group = config.hl_group.RbxClass,
						})
					end
				end

				local function favorite_class()
					local line = vim.api.nvim_win_get_cursor(win)
					if class_list_ref[line[1]].t == "class" then
						if data.favorites[class_list_ref[line[1]].name] then
							return
						end
						toggle_favorite(line)
					end
				end

				local function unfavorite_class()
					local line = vim.api.nvim_win_get_cursor(win)
					if class_list_ref[line[1]].t == "class" then
						if not data.favorites[class_list_ref[line[1]].name] then
							return
						end
						toggle_favorite(line)
					end
				end
				local function favorite()
					local line = vim.api.nvim_win_get_cursor(win)
					if class_list_ref[line[1]].t == "class" then
						toggle_favorite(line)
					end
				end

				assign_command(buf, "FavoriteClass", config.config.keybinds.favorite_class, favorite_class)
				assign_command(buf, "UnfavoriteClass", config.config.keybinds.unfavorite_class, unfavorite_class)
				assign_command(buf, "ToggleFavorite", config.config.keybinds.toggle_favorite_class, favorite)
			end,
		},

		class_display = {
			title = "Class",
			title_pos = "center",
			width = math.floor(width / 2),
			height = height - 6,
			col = col + math.ceil(width / 2) + 1,
			row = row + 2,
			border = {
				{ "─", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "┤", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "┤", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "", "FloatBorder" },
			},
			keybinds = function(
				buf,
				win,
				class_edit_box,
				l_win,
				s_win,
				p_buf,
				p_win,
				edit_mode,
				focus_win,
				edit_class,
				edit_path
			)
				local prev_index
				if not edit_mode then
					local function select_dir()
						local args = dir_select.generate_dimensions()
						if not args then
							return
						end
						dir_select.resolve_source_directory(function()
							dir_select.make_dir_windows(args.path_bar)
							dir_select.make_dir_windows(args.directory)
							local function change_path(_, new_path, new_v_path)
								path = new_path
								vim.api.nvim_set_option_value("modifiable", true, { buf = p_buf })
								vim.api.nvim_buf_set_lines(p_buf, 0, -1, false, { new_v_path })
								vim.api.nvim_set_option_value("modifiable", false, { buf = p_buf })
								vim.api.nvim_win_close(args.path_bar.win, true)
								vim.api.nvim_win_close(args.directory.win, true)
								vim.api.nvim_set_current_win(win)
							end

							args.directory.keybinds(
								args.directory.buf,
								args.directory.win,
								args.path_bar.buf,
								args.path_bar.win,
								change_path,
								name,
								win
							)
						end)
					end

					assign_command(buf, "SelectDir", config.config.keybinds.select_dir, select_dir)

					local function rename_file()
						create_input("Name", "Leave bank to cancel, name cannot already exist", nil, function(value)
							if not value then
								return
							end
							dir_select.check_name_collision(path, value, function()
								name = value
								vim.api.nvim_win_set_config(p_win, {
									title = 'Directory for "' .. value .. '"',
								})
							end)
						end, "Change name")
					end

					assign_command(buf, "RenameFile", config.config.keybinds.rename_file, rename_file)
				else
					current_class = edit_class
					prev_index = data.saved_object_configs[current_class].index
					data.saved_object_configs[current_class].index = -1
				end

				local function close_browser()
					if edit_class then
						data.saved_object_configs[current_class].index = prev_index
					end
					vim.api.nvim_win_close(win, true)
					if l_win then
						vim.api.nvim_win_close(l_win, true)
					end
					vim.api.nvim_win_close(class_edit_box.win, true)
					vim.api.nvim_win_close(s_win, true)
					vim.api.nvim_win_close(p_win, true)
					if focus_win then
						vim.api.nvim_set_current_win(focus_win)
					end
				end

				assign_command(buf, "CloseBrowser", config.config.keybinds.close_browser_window, close_browser)

				local function select_property()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					local prop = properties_list_ref[line]
					if prop.t ~= "name" and prop.t ~= "config" then
						if prop.t == "init" then
							if not edit_class then
								prop.saved_props.init_meta = not prop.saved_props.init_meta
								if (not edit_class) and prop.saved_props.name then
									data.save_object_configs()
								end
								disp_class(buf, current_class, true)
							end
						else
							local function when_done(stay)
								local highlights = {
									{
										row = line - 1,
										start_col = 2,
										end_col = 2 + #prop.name,
										hl_group = config.hl_group.RbxProperty,
									},
								}
								local pre = prop.props[prop.name] and prop.props[prop.name].json and " *" or "  "
								local lstr = pre .. prop.name .. ": "
								if prop.t == "Enum" then
									lstr = lstr .. "Enum."
								end
								lstr = lstr .. prop.t
								local line_len = #lstr
								table.insert(highlights, {
									row = line - 1,
									start_col = 2 + #prop.name + 2,
									end_col = line_len,
									hl_group = config.hl_group.RbxDataType,
								})
								if #prop.tags > 0 then
									local tag_str = " [Tags: " .. table.concat(prop.tags, ", ") .. "]"

									lstr = lstr .. tag_str
								end
								vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
								vim.api.nvim_buf_clear_namespace(buf, config.ns, line - 1, line)
								vim.api.nvim_buf_set_lines(buf, line - 1, line, false, { lstr })
								vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
								for _, hl in ipairs(highlights) do
									vim.api.nvim_buf_set_extmark(buf, config.ns, hl.row, hl.start_col, {
										end_col = hl.end_col,
										hl_group = hl.hl_group,
									})
								end
								if not stay then
									vim.api.nvim_set_current_win(win)
								end
								if (not edit_class) and prop.saved_props.name then
									data.save_object_configs()
								end
							end
							disp_property(
								prop.t,
								prop.props,
								prop.name,
								class_edit_box,
								when_done,
								prop.enum,
								false,
								win
							)
						end
					end
				end

				assign_command(buf, "SelectProperty", config.config.keybinds.select_property, select_property)

				vim.api.nvim_create_autocmd("CursorMoved", {
					buffer = buf,
					callback = function()
						if not vim.api.nvim_win_is_valid(win) then
							return
						end

						local line = vim.api.nvim_win_get_cursor(win)[1]
						local prop = properties_list_ref[line]
						local function when_done(stay)
							local highlights = {
								{
									row = line - 1,
									start_col = 2,
									end_col = 2 + #prop.name,
									hl_group = config.hl_group.RbxProperty,
								},
							}
							local pre = prop.props[prop.name] and prop.props[prop.name].json and " *" or "  "
							local lstr = pre .. prop.name .. ": "
							if prop.t == "Enum" then
								lstr = lstr .. "Enum."
							end
							lstr = lstr .. prop.t
							local line_len = #lstr
							table.insert(highlights, {
								row = line - 1,
								start_col = 2 + #prop.name + 2,
								end_col = line_len,
								hl_group = config.hl_group.RbxDataType,
							})
							if #prop.tags > 0 then
								local tag_str = " [Tags: " .. table.concat(prop.tags, ", ") .. "]"

								lstr = lstr .. tag_str
							end
							vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
							vim.api.nvim_buf_clear_namespace(buf, config.ns, line - 1, line)
							vim.api.nvim_buf_set_lines(buf, line - 1, line, false, { lstr })
							vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
							for _, hl in ipairs(highlights) do
								vim.api.nvim_buf_set_extmark(buf, config.ns, hl.row, hl.start_col, {
									end_col = hl.end_col,
									hl_group = hl.hl_group,
								})
							end
							if not stay then
								vim.api.nvim_set_current_win(win)
							end
							if (not edit_class) and prop.saved_props.name then
								data.save_object_configs()
							end
						end
						if prop.t ~= "name" and prop.t ~= "config" and prop.t ~= "init" then
							disp_property(
								prop.t,
								prop.props,
								prop.name,
								class_edit_box,
								when_done,
								prop.enum,
								true,
								win
							)
						end
					end,
				})

				local function export_class()
					local saved_object_properties = data.saved_object_configs[current_class]
					local index = saved_object_properties.index or 1
					saved_object_properties.index = index
					local properties = saved_object_properties.property_tables[index]
						or {
							properties = {},
							init_meta = false,
						}
					saved_object_properties.property_tables[index] = properties
					local json_table = {}
					for property, i in pairs(properties.properties) do
						if property ~= "EXTERNAL" then
							json_table[property] = i.json
						end
					end
					if edit_class then
						if current_class then
							local meta_json = (string.find(current_class, "Script", 1, true) ~= nil)
							writer.edit_file(
								current_class,
								edit_path,
								json_table,
								properties.init_meta,
								meta_json,
								properties.properties.EXTERNAL
							)
						end
						close_browser()
					else
						create_input(
							"Input",
							"Return 'yes' to use current config, return 'dir' to only use Directory value only",
							"yes",
							function(value)
								if value ~= "yes" then
									json_table = vim.deepcopy({})
								end
								if properties.name then
									data.save_object_configs()
								end

								if current_class then
									local init_meta = false
									if value == "dir" or value == "yes" then
										init_meta = properties.init_meta
									end
									local meta_json = init_meta
										or (string.find(current_class, "Script", 1, true) ~= nil)
									writer.create_file(name, current_class, json_table, path, meta_json, init_meta)
								end
							end,
							"Do you want to use the current config?"
						)
					end
				end

				assign_command(buf, "ExportClass", config.config.keybinds.export_class, export_class)

				local function clear_property()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					local prop = properties_list_ref[line]
					if prop.t == "name" or prop.t == "config" or prop.t == "init" then
						return
					end
					prop.props[prop.name] = nil
					local highlights = {
						{
							row = line - 1,
							start_col = 2,
							end_col = 2 + #prop.name,
							hl_group = config.hl_group.RbxProperty,
						},
					}
					local pre = "  "
					local lstr = pre .. prop.name .. ": "
					if prop.t == "Enum" then
						lstr = lstr .. "Enum."
					end
					lstr = lstr .. prop.t
					local line_len = #lstr
					table.insert(highlights, {
						row = line - 1,
						start_col = 2 + #prop.name + 2,
						end_col = line_len,
						hl_group = config.hl_group.RbxDataType,
					})
					if #prop.tags > 0 then
						local tag_str = " [Tags: " .. table.concat(prop.tags, ", ") .. "]"

						lstr = lstr .. tag_str
					end
					vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
					vim.api.nvim_buf_clear_namespace(buf, config.ns, line - 1, line)
					vim.api.nvim_buf_set_lines(buf, line - 1, line, false, { lstr })
					vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
					for _, hl in ipairs(highlights) do
						vim.api.nvim_buf_set_extmark(buf, config.ns, hl.row, hl.start_col, {
							end_col = hl.end_col,
							hl_group = hl.hl_group,
						})
					end
					if not edit_class then
						data.save_object_configs()
					end
				end

				assign_command(buf, "ClearProperty", config.config.keybinds.clear_property, clear_property)

				if not edit_class then
					local function name_config()
						local saved_object_properties = data.saved_object_configs[current_class]
						local index = saved_object_properties.index
						local properties = saved_object_properties.property_tables[index] or { properties = {} }
						saved_object_properties.property_tables[index] = properties
						create_input("Name", "duplicate names are valid, leave blank to cancel", nil, function(value)
							if not value then
								return
							end
							properties.name = value
							data.save_object_configs()
							disp_class(buf, current_class, true)
						end, "Name of config")
					end

					assign_command(buf, "NameConfig", config.config.keybinds.name_class_config, name_config)

					local function duplicate_config()
						local saved_object_properties = data.saved_object_configs[current_class]
						local index = saved_object_properties.index
						local properties = saved_object_properties.property_tables[index] or { properties = {} }
						if not properties.name then
							vim.notify("Cannot duplicate temporary configs", vim.log.levels.ERROR)
							return
						end

						local copied = false

						for i, p in ipairs(saved_object_properties.property_tables) do
							if not p.name then
								copied = true
								create_input(
									"Confirm",
									"Return 'yes' to replace temporary config",
									"no",
									function(value)
										if value == "yes" then
											saved_object_properties.property_tables[i] = vim.deepcopy(properties)
											saved_object_properties.property_tables[i].name = nil
											saved_object_properties.index = i
											disp_class(buf, current_class, true)
										end
									end,
									"A temporary config already exists (Config " .. i .. ")"
								)
							end
						end

						if not copied then
							table.insert(saved_object_properties.property_tables, vim.deepcopy(properties))
							saved_object_properties.property_tables[#saved_object_properties.property_tables].name = nil
							saved_object_properties.index = #saved_object_properties.property_tables
							disp_class(buf, current_class, true)
						end
					end

					assign_command(buf, "DuplicateConfig", config.config.keybinds.duplicate_config, duplicate_config)

					local function prev_config()
						local saved_object_properties = data.saved_object_configs[current_class]
						local index = saved_object_properties.index
						if index == 1 then
							return
						end
						index = index - 1
						saved_object_properties.index = index

						disp_class(buf, current_class, true)
					end

					assign_command(buf, "PrevConfig", config.config.keybinds.prev_config, prev_config)

					local function next_config()
						local saved_object_properties = data.saved_object_configs[current_class]
						local index = saved_object_properties.index
						if not saved_object_properties.property_tables[index].name then
							return
						end
						index = index + 1
						saved_object_properties.index = index

						disp_class(buf, current_class, true)
					end

					assign_command(buf, "NextConfig", config.config.keybinds.next_config, next_config)

					local function delete_config()
						if config.config.confirm_delete then
							create_input("Confirm", "Return 'yes' to delete current config", "no", function(value)
								if value ~= "yes" then
									return
								end
								local saved_object_properties = data.saved_object_configs[current_class]
								local index = saved_object_properties.index
								table.remove(saved_object_properties.property_tables, index)
								index = math.max(1, math.min(#saved_object_properties.property_tables, index))
								saved_object_properties.index = index
								data.save_object_configs()
								disp_class(buf, current_class, true)
							end, "Are you sure you want to delete the current config?")
						else
							local saved_object_properties = data.saved_object_configs[current_class]
							local index = saved_object_properties.index
							table.remove(saved_object_properties.property_tables, index)
							index = math.max(1, math.min(#saved_object_properties.property_tables, index))
							saved_object_properties.index = index
							data.save_object_configs()
							disp_class(buf, current_class, true)
						end
					end

					assign_command(buf, "DeleteConfig", config.config.keybinds.delete_config, delete_config)

					local function enter_list()
						vim.api.nvim_win_close(class_edit_box.win, true)
						class_edit_box.win = nil
						class_edit_box.buf = nil
						vim.api.nvim_set_current_win(l_win)
					end

					assign_command(buf, "EnterList", config.config.keybinds.class_enter_list, enter_list)
				end
			end,
		},
	}
end

m.generate_dimensions = generate_dimensions

return m
