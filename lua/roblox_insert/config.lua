local vim = vim

local t = {}

t.actions = {
	"open_browser",
	"select_dir",
	"enter_parent_dir",
	"add_dir",
	"delete_dir",
	"name_file",
	"close_dir_window",
	"toggle_file_visibility",
	"enable_file_visibility",
	"disable_file_visibility",
	"rename_file",
	"rename_dir",

	"close_input",
	"save_input",

	"start_search",
	"close_browser_window",
	"rename_file",
	"choose_new_dir",
	"select_class",
	"toggle_favorite_class",
	"favorite_class",
	"unfavorite_class",
	"toggle_category",
	"show_category",
	"hide_category",

	"close_browser_window",
	"rename_file",
	"choose_new_dir",
	"select_property",
	"export_class",
	"clear_property",
	"save_class_config",
	"prev_class_config",
	"next_class_config",
	"enter_list",
	"delete_config",
	"duplicate_config",

	"close_property",
	"export_property",
	"select_property_field",
	"next_keypoint",
	"prev_keypoint",

	"search_close_browser_window",
	"search_enter_list",
}

t.command_names = {
	"OpenBrowser",
	"SelectDir",
	"EnterParentDir",
	"AddDir",
	"DeleteDir",
	"NameFile",
	"CloseDirWindow",
	"ToggleFileVisibility",
	"EnableFileVisibility",
	"DisableFileVisibility",

	"CloseInput",

	"StartSearch",
	"CloseBrowser",
	"RenameFile",
	"ChooseNewDir",
	"SelectClass",
	"ToggleFavorite",
	"FavoriteClass",
	"UnfavoriteClass",
	"ToggleCategory",
	"ShowCategory",
	"HideCategory",

	"CloseBrowser",
	"RenameFile",
	"ChooseNewDir",
	"SelectParam",
	"ExportClass",
	"ClearParam",
	"SaveConfig",
	"PrevConfig",
	"NextConfig",
	"EnterList",
	"DeleteConfig",

	"CloseEditParam",
	"SaveParam",
	"SelectParamField",
	"NextKeypoint",
	"PrevKeypoint",

	"CloseBrowser",
	"EnterList",
}

local desc = {
	RbxBrowser = "Opens the browser",
	SelectDir = "Enters/selects the highlighted directory",
	EnterParentDir = "Enters the parent directory",
	CreateDir = "Creates a new directory inside the current directory",
	DeleteDir = "Recursively deletes the highlighted directory",
	NameFile = "Asks for the name of the file before switching to Class browser",
	EditClass = "Opens a window to edit the contents of the highlighted class",
	CloseDirWindow = "Closes the directory browser",
	ToggleFileVisibility = "Toggles the visibility of non-directory files",
	EnableFileVisibility = "Enables the visibility of non-directory files",
	DisableFileVisibility = "Disables the visibility of non-directory files",
	CloseInput = "Closes the input without saving",
	StartSearch = "Enters the Search Bar",
	CloseBrowser = "Closes Class browser",
	RenameFile = "Changes the output filename",
	ChooseNewDir = "Changes the output directory",
	SelectClass = "Selects the highlighted class or toggles the highlighted category",
	ToggleFavorite = "Toggles favoriting/unfavoriting a class",
	FavoriteClass = "Adds the highlighted class to favorites",
	UnfavoriteClass = "Removes the highlighted class from favorites",
	SelectProperty = "Selects highlighted property",
	ExportClass = "Exports the current class as a file",
	ClearProperty = "Clears the saved data from the highlighted property",
	NameConfig = "Saves/renames the current class config",
	RenameDir = "Renames the highlighted file or directory",
	DuplicateConfig = "Duplicates the current named config",
	DeleteConfig = "Deletes current class config",
	PrevConfig = "Displays/selects the previous class config",
	NextConfig = "Displays/selects the next class config",
	EnterList = "Enters into the Class list",
	CloseProperty = "Exits the property editor without saving changes",
	ExportProperty = "Validates and saves the edited property",
	SelectField = "Selects the highlighted field",
	SelectPropertyField = "Selects the highlighted property field",
	NextKeypoint = "Displays the next keypoint",
	PrevKeypoint = "Displays the previous keypoint",
}

---@param buf number
---@param command_name string
---@param keybinds {[string]: boolean}?
---@param func fun(): nil
local function assign_command(buf, command_name, keybinds, func)
	local description = desc[command_name]

	if not description then
		vim.notify(command_name .. ": missing command desc", vim.log.levels.ERROR)
		description = command_name
	end

	vim.api.nvim_buf_create_user_command(buf, command_name, func, {
		desc = description,
	})

	if keybinds then
		for keybind, _ in pairs(keybinds) do
			vim.keymap.set("n", keybind, func, {
				buffer = buf,
				desc = description,
			})
		end
	end
end

t.assign_command = assign_command

local default_keybinds = {
	groups = {
		export = {
			keybinds = { "<C-e>" },
			actions = {
				"export_class",
				"export_property",
			},
		},

		select = {
			keybinds = { "<CR>" },
			actions = {
				"search_enter_list",
				"select_class",
				"select_dir",
				"select_property",
				"select_property_field",
			},
		},

		close_window = {
			keybinds = { "Q" },
			actions = {
				"close_browser_window",
				"close_dir_window",
				"close_input",
				"close_property",
			},
		},

		delete = {
			keybinds = { "D" },
			actions = {
				"delete_config",
				"delete_dir",
			},
		},

		next = {
			keybinds = { ">" },
			actions = {
				"next_config",
				"next_keypoint",
			},
		},

		prev = {
			keybinds = { "<" },
			actions = {
				"prev_config",
				"prev_keypoint",
			},
		},

		rename = {
			keybinds = { "R" },
			actions = {
				"rename_file",
				"rename_dir",
			},
		},
	},

	actions = {
		choose_new_dir = { "d" },
		class_enter_list = { "<Esc>" },
		clear_property = { "S" },
		create_dir = { "d" },
		duplicate_config = { "P" },
		edit_class = { "E" },
		enter_parent_dir = { "-" },
		name_class_config = { "C" },
		name_file = { "%" },
		start_search = { "/" },
		toggle_favorite_class = { "F" },
		toggle_file_visibility = { "H" },
	},
}

local defaults = {
	custom_keybinds = {
		groups = {},
		actions = {},
	},

	keybinds = {},
	highlights = {
		RbxClass = { default = true, link = "Type" },
		RbxProperty = { default = true, link = "Identifier" },
		RbxValue = { default = true, link = "String" },
		RbxNumber = { default = true, link = "Number" },
		RbxBoolean = { default = true, link = "Boolean" },
		RbxDataType = { default = true, link = "Type" },
		RbxInactive = { default = true, link = "Comment" },
		RbxSelected = { default = true, link = "CursorLine" },
		RbxBrowser = { default = true, link = "Normal" },
		RbxError = { default = true, link = "DiagnosticError" },
		RbxDir = { default = true, link = "netrwDir" },
		RbxPlain = { default = true, link = "netrwPlain" },
		RbxClassify = { default = true, link = "netrwClassify" },
	},

	src_name = "src",

	confirm_delete = true,

	files_visible = true,

	return_to_class_disp = true,

	allow_overwrite = false,
	confirm_overwrite = true,

	enable_default_keybinds = true,
}

t.config = vim.deepcopy(defaults)

---@param opts table
---@param k table
---@param d boolean
local function convert_keybind_config(opts, k, d)
	for _, group in pairs(k.groups) do
		for _, action in ipairs(group.actions) do
			if not opts.keybinds[action] then
				opts.keybinds[action] = {}
				for _, keybind in ipairs(group.keybinds) do
					if type(keybind) == "string" then
						opts.keybinds[action][keybind] = true
					end
				end
			elseif not d then
				for _, keybind in ipairs(group.keybinds) do
					if type(keybind) == "string" then
						opts.keybinds[action][keybind] = true
					end
				end
			end
		end
	end

	for action, keybinds in pairs(k.actions) do
		if not opts.keybinds[action] then
			opts.keybinds[action] = {}
			for _, keybind in ipairs(keybinds) do
				if type(keybind) == "string" then
					opts.keybinds[action][keybind] = true
				end
			end
		elseif not d then
			for _, keybind in ipairs(keybinds) do
				if type(keybind) == "string" then
					opts.keybinds[action][keybind] = true
				end
			end
		end
	end
end

local function assign_keybinds(opts)
	convert_keybind_config(opts, opts.custom_keybinds, false)
	if opts.enable_default_keybinds then
		convert_keybind_config(opts, default_keybinds, true)
	end
end

assign_keybinds(t.config)

t.hl_group = {}
for group, target in pairs(t.config.highlights) do
	vim.api.nvim_set_hl(0, group, type(target) == "table" and target or defaults.highlights[group])
	t.hl_group[group] = group
end

t.ns = vim.api.nvim_create_namespace("RbxHighlights")

---@param opts table?
local function setup(opts)
	opts = opts or {}
	local custom_highlights = opts.highlights or {}

	t.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)

	for group, target in pairs(t.config.highlights) do
		local spec = custom_highlights[group] or target

		if type(spec) == "string" then
			spec = { link = spec }
		end

		vim.api.nvim_set_hl(0, group, spec)
		t.hl_group[group] = group
	end
end

t.setup = setup

return t
