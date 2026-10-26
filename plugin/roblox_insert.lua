local vim = vim
if vim.g.loaded_roblox_insert == 1 then
	return
end

vim.g.loaded_roblox_insert = 1

vim.api.nvim_create_user_command("RbxCreate", function(opts)
	if #opts.fargs ~= 2 and #opts.fargs ~= 3 then
		vim.notify("Usage: RbxCreate <name> <class> <dir?>", vim.log.levels.ERROR)
		return
	end
	if opts.fargs[3] then
		opts.fargs[3] = vim.fn.fnamemodify(opts.fargs[3], ":p")
	end

	require("roblox_insert.commands").create_file(opts.fargs[1], opts.fargs[2], opts.fargs[3])
end, {
	nargs = "+",
	desc = "Create a Roblox Object in the current buffer's directory or a directory specified starting from neovim's working directory",
})

vim.api.nvim_create_user_command("RbxBrowser", function(opts)
	require("roblox_insert.commands").open_browser(opts.args)
end, {
	desc = "Open the Roblox browser at a directory within src, starting from src/",
	nargs = "?",
	complete = "dir",
})

vim.api.nvim_create_user_command("RbxBrowserCwd", function()
	local dir
	local bufnr = vim.api.nvim_get_current_buf()

	local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
	if filetype == "netrw" then
		dir = vim.b.netrw_curdir
	end

	local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
	if buftype == "" then
		dir = vim.api.nvim_buf_get_name(0)
	end
	require("roblox_insert.commands").open_browser(dir)
end, {
	desc = "Open a browser similar to Roblox's with the directory opened in the cwd",
})
