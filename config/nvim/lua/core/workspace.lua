local M = {}

local settings = require("core.settings")
local started = false

local special_filetypes = {
	NvimTree = true,
	netrw = true,
	alpha = true,
	codecompanion = true,
	help = true,
	qf = true,
	trouble = true,
	toggleterm = true,
	TelescopePrompt = true,
}

local function valid_window(win)
	return win and vim.api.nvim_win_is_valid(win)
end

local function leave_terminal_mode()
	if vim.api.nvim_get_mode().mode == "t" then
		vim.cmd("stopinsert")
	end
end

local function find_window(predicate)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if valid_window(win) and predicate(win) then
			return win
		end
	end
	return nil
end

local function git_root()
	local cwd = vim.uv.cwd()
	local git = vim.fs.find(".git", { path = cwd, upward = true, limit = 1 })
	return git[1] and vim.fs.dirname(git[1]) or nil
end

local function editor_window()
	return find_window(function(win)
		local buf = vim.api.nvim_win_get_buf(win)
		local filetype = vim.bo[buf].filetype
		local buftype = vim.bo[buf].buftype
		return buftype == ""
			and not special_filetypes[filetype]
			and not vim.wo[win].previewwindow
	end)
end

local function focus_window(filetype)
	local win = find_window(function(candidate)
		return vim.bo[vim.api.nvim_win_get_buf(candidate)].filetype == filetype
	end)
	if valid_window(win) then
		vim.api.nvim_set_current_win(win)
		return true
	end
	return false
end

function M.focus_tree()
	leave_terminal_mode()
	if focus_window("NvimTree") then
		return
	end
	if not valid_window(editor_window()) then
		vim.cmd("enew")
	end
	local ok, api = pcall(require, "nvim-tree.api")
	if ok then
		local opened = pcall(api.tree.open, { focus = true, find_file = false, update_root = false })
		if opened then
			return
		end
	end
	pcall(vim.cmd, "NvimTreeOpen")
	if vim.fn.exists(":NvimTreeFocus") == 2 then
		pcall(vim.cmd, "NvimTreeFocus")
	end
end

function M.focus_editor()
	leave_terminal_mode()
	local win = editor_window()
	if not valid_window(win) then
		vim.cmd("enew")
		win = vim.api.nvim_get_current_win()
	end
	vim.api.nvim_set_current_win(win)
end

function M.focus_terminal()
	leave_terminal_mode()
	if focus_window("toggleterm") then
		return
	end

	local ok, terminal_module = pcall(require, "toggleterm.terminal")
	if not ok then
		pcall(vim.cmd, "ToggleTerm direction=horizontal")
		ok, terminal_module = pcall(require, "toggleterm.terminal")
	end
	if not ok then
		vim.notify("ToggleTerm could not be loaded", vim.log.levels.ERROR, { title = "workspace" })
		return
	end

	local terminal = terminal_module.get(1, true)
	if not terminal then
		pcall(vim.cmd, "ToggleTerm direction=horizontal")
		terminal = terminal_module.get(1, true)
	end
	if not terminal then
		return
	end

	if not terminal:is_open() then
		terminal:open(nil, "horizontal")
	end
	if valid_window(terminal.window) then
		vim.api.nvim_set_current_win(terminal.window)
	end
end

function M.launch_codex_cli()
	M.focus_terminal()
	vim.defer_fn(function()
		local ok, terminal_module = pcall(require, "toggleterm.terminal")
		local terminal = ok and terminal_module.get(1, true) or nil
		if terminal and terminal.job_id then
			vim.api.nvim_chan_send(terminal.job_id, settings.codex_cli_command .. "\n")
		else
			vim.notify("Workspace terminal is not ready", vim.log.levels.WARN, { title = "Codex CLI" })
		end
	end, 120)
end

function M.focus_codex()
	leave_terminal_mode()
	if focus_window("codecompanion") then
		return
	end
	if vim.fn.exists(":CodeCompanionChat") ~= 2 then
		vim.notify("CodeCompanionChat is unavailable", vim.log.levels.ERROR, { title = "workspace" })
		return
	end

	local ok, err = pcall(vim.cmd, "CodeCompanionChat")
	if not ok then
		vim.notify(tostring(err), vim.log.levels.ERROR, { title = "CodeCompanion ACP" })
		return
	end
	focus_window("codecompanion")
end

function M.focus_lazygit()
	leave_terminal_mode()
	local terminal = _G._get_lazygit_terminal and _G._get_lazygit_terminal() or nil
	if not terminal then
		return
	end
	if not terminal:is_open() then
		terminal:open(nil, "float")
	end
	if valid_window(terminal.window) then
		vim.api.nvim_set_current_win(terminal.window)
	end
end

function M.focus(slot)
	if slot == 1 then
		M.focus_tree()
	elseif slot == 2 then
		M.focus_editor()
	elseif slot == 3 then
		M.focus_codex()
	elseif slot == 4 then
		M.focus_terminal()
	elseif slot == 5 then
		M.focus_lazygit()
	end
end

local function map_focus_keys()
	local slots = {
		[1] = "NvimTree navigator",
		[2] = "Editor",
		[3] = "Codex ACP",
		[4] = "Terminal",
		[5] = "Lazygit",
	}

	for slot, label in pairs(slots) do
		for _, key in ipairs({ "<leader>" .. slot, "<A-" .. slot .. ">" }) do
			vim.keymap.set({ "n", "t" }, key, function()
				M.focus(slot)
			end, { silent = true, desc = "workspace: Focus " .. label })
		end
	end

	for _, key in ipairs({ "<leader>0", "<A-0>" }) do
		vim.keymap.set({ "n", "t" }, key, M.focus_editor, { silent = true, desc = "workspace: Focus editor" })
	end
	vim.keymap.set({ "n", "t" }, "<leader>cx", M.launch_codex_cli, {
		silent = true,
		desc = "workspace: Launch Codex CLI in terminal",
	})
end

function M.open_startup()
	if started or not settings.workspace_auto_open or #vim.api.nvim_list_uis() == 0 then
		return
	end

	local args = vim.fn.argv()
	if #args > 0 then
		local cwd = vim.fs.normalize(vim.uv.cwd())
		local only_project_directory = #args == 1
			and vim.fn.isdirectory(args[1]) == 1
			and vim.fs.normalize(vim.fn.fnamemodify(args[1], ":p")) == cwd
		if not only_project_directory then
			return
		end
	end

	local root = git_root()
	if not root then
		return
	end

	started = true
	vim.g.nvim_workspace_mode = true
	vim.g.nvim_workspace_root = root

	-- Replace the dashboard with a real editor buffer only for project startup.
	if vim.bo.filetype == "alpha" then
		vim.cmd("enew")
	end

	M.focus_editor()
	if settings.workspace_auto_open_tree then
		M.focus_tree()
	end

	if settings.workspace_auto_open_terminal then
		M.focus_terminal()
	end
	M.focus_editor()

	if settings.workspace_auto_open_codex then
		vim.defer_fn(function()
			M.focus_codex()
			M.focus_editor()
		end, 160)
	end
	vim.cmd("stopinsert")
end

function M.setup()
	map_focus_keys()
	vim.api.nvim_create_user_command("WorkspaceOpen", function()
		started = false
		M.open_startup()
	end, {})
	vim.api.nvim_create_autocmd("VimEnter", {
		group = vim.api.nvim_create_augroup("NvimWorkspaceStartup", { clear = true }),
		once = true,
		callback = function()
			vim.defer_fn(M.open_startup, 120)
		end,
	})
end

return M
