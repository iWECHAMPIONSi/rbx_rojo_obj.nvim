local writer = require("roblox_insert.writer")
local browser = require("roblox_insert.browser")
local dir = require("roblox_insert.dir_select")

local vim = vim

local m = {}

---@param file_name string
---@param class string
---@return nil
local function create_file(file_name, class, directory)
	if type(file_name) ~= "string" then
		vim.notify("name of the file must be a valid string", vim.log.levels.ERROR)
		return
	end

	if type(class) ~= "string" then
		vim.notify("name of the class must be a string", vim.log.levels.ERROR)
	end

	writer.create_file(file_name, class, {}, directory)
end

m.create_file = create_file

local function open_browser(cwd)
	local args = dir.generate_dimensions()
	if not args then
		return
	end
	local function foo(name, path, visual_path)
		local ui_args = browser.generate_dimensions(name, path, visual_path)
		if not ui_args then
			return
		end

		vim.cmd.stopinsert()

		browser.create_window(ui_args.search_bar)
		browser.create_window(ui_args.path_bar)
		browser.create_window(ui_args.class_list)
		browser.create_window(ui_args.class_display)

		vim.api.nvim_win_close(args.path_bar.win, true)
		vim.api.nvim_win_close(args.directory.win, true)

		browser.disp_class_list(ui_args.class_list.buf, true)
		ui_args.class_list.keybinds(
			ui_args.class_list.buf,
			ui_args.class_list.win,
			ui_args.class_display.buf,
			ui_args.class_display.win,
			ui_args.path_bar.buf,
			ui_args.path_bar.win,
			ui_args.search_bar.win
		)
		ui_args.class_display.keybinds(
			ui_args.class_display.buf,
			ui_args.class_display.win,
			ui_args.class_edit_box,
			ui_args.class_list.win,
			ui_args.search_bar.win,
			ui_args.path_bar.buf,
			ui_args.path_bar.win
		)
		ui_args.search_bar.keybinds(
			ui_args.search_bar.buf,
			ui_args.search_bar.win,
			ui_args.class_list.buf,
			ui_args.class_list.win,
			ui_args.path_bar.win,
			ui_args.class_display.win
		)
	end
	dir.resolve_source_directory(function()
		dir.make_dir_windows(args.path_bar)
		dir.make_dir_windows(args.directory)

		args.directory.keybinds(
			args.directory.buf,
			args.directory.win,
			args.path_bar.buf,
			args.path_bar.win,
			foo,
			nil,
			nil,
			browser.generate_dimensions,
			browser.create_window,
			browser.disp_property,
			browser.disp_class,
			cwd
		)
	end)
end

m.open_browser = open_browser

return m
