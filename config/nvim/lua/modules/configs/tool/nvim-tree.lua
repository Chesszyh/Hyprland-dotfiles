return function()
	local api = require("nvim-tree.api")
	local icons = {
		diagnostics = require("modules.utils.icons").get("diagnostics"),
		documents = require("modules.utils.icons").get("documents"),
		git = require("modules.utils.icons").get("git"),
		ui = require("modules.utils.icons").get("ui"),
	}

	local function on_attach(bufnr)
		api.map.on_attach.default(bufnr)

		local opts = function(desc)
			return {
				buffer = bufnr,
				desc = "nvim-tree: " .. desc,
				noremap = true,
				silent = true,
				nowait = true,
			}
		end

		local resize = function(delta)
			api.tree.resize({ relative = delta })
		end

		-- Keep nvim-tree's native file-operation mappings and add direct navigation aliases.
		local aliases = {
			["<Left>"] = { api.node.navigate.parent_close, "Close directory" },
			["h"] = { api.node.navigate.parent_close, "Close directory" },
			["<Right>"] = { api.node.open.edit, "Open / expand" },
			["l"] = { api.node.open.edit, "Open / expand" },
			["<Up>"] = { "k", "Previous visible item" },
			["<Down>"] = { "j", "Next visible item" },
			["<CR>"] = { api.node.open.edit, "Open" },
			["<Tab>"] = { api.node.open.preview, "Preview" },
			["<C-Left>"] = { function() resize(-2) end, "Narrow tree" },
			["<C-Right>"] = { function() resize(2) end, "Widen tree" },
			["[w"] = { function() resize(-2) end, "Narrow tree" },
			["]w"] = { function() resize(2) end, "Widen tree" },
		}
		for lhs, mapping in pairs(aliases) do
			vim.keymap.set("n", lhs, mapping[1], opts(mapping[2]))
		end
	end

	require("modules.utils").load_plugin("nvim-tree", {
		auto_reload_on_write = true,
		disable_netrw = true,
		hijack_cursor = true,
		hijack_netrw = true,
		-- Keep an empty editor buffer in the center when the project workspace opens.
		hijack_unnamed_buffer_when_opening = false,
		respect_buf_cwd = true,
		prefer_startup_root = false,
		sync_root_with_cwd = true,
		view = {
			side = "left",
			width = {
				min = 24,
				max = 32,
				padding = 1,
				lines_excluded = { "root" },
			},
			preserve_window_proportions = false,
		},
		on_attach = on_attach,
		renderer = {
			full_name = false,
			group_empty = true,
			add_trailing = false,
			symlink_destination = true,
			highlight_git = "all",
			-- Hide the synthetic root row; the first cursor position should be a real node.
			root_folder_label = false,
			special_files = { "Cargo.toml", "Makefile", "README.md", "readme.md", "CMakeLists.txt" },
			indent_markers = {
				enable = true,
				inline_arrows = true,
			},
			icons = {
				show = {
					file = true,
					folder = true,
					folder_arrow = true,
					git = true,
				},
				padding = " ",
				symlink_arrow = " 󰁔 ",
				git_placement = "after",
				glyphs = {
					default = icons.documents.Default,
					symlink = icons.documents.Symlink,
					bookmark = icons.ui.Bookmark,
					git = {
						unstaged = icons.git.Mod_alt,
						staged = icons.git.Add,
						unmerged = icons.git.Unmerged,
						renamed = icons.git.Rename,
						untracked = icons.git.Untracked,
						deleted = icons.git.Remove,
						ignored = icons.git.Ignore,
					},
					folder = {
						arrow_open = icons.ui.ArrowOpen,
						arrow_closed = icons.ui.ArrowClosed,
						default = icons.ui.Folder,
						open = icons.ui.FolderOpen,
						empty = icons.ui.EmptyFolder,
						empty_open = icons.ui.EmptyFolderOpen,
						symlink = icons.ui.SymlinkFolder,
						symlink_open = icons.ui.FolderOpen,
					},
				},
			},
		},
		actions = {
			use_system_clipboard = true,
			change_dir = {
				enable = true,
				global = false,
			},
			open_file = {
				quit_on_open = false,
				resize_window = true,
				window_picker = {
					enable = false,
					chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
					exclude = {
						buftype = {
							"help",
							"nofile",
							"prompt",
							"quickfix",
							"terminal",
						},
						filetype = {
							"dap-repl",
							"diff",
							"fugitive",
							"fugitiveblame",
							"git",
							"notify",
							"Outline",
							"qf",
							"TelescopePrompt",
							"toggleterm",
							"undotree",
						},
					},
				},
			},
			remove_file = {
				close_window = true,
			},
		},
		diagnostics = {
			enable = false,
			show_on_dirs = false,
			debounce_delay = 50,
			icons = {
				hint = icons.diagnostics.Hint_alt,
				info = icons.diagnostics.Information_alt,
				warning = icons.diagnostics.Warning_alt,
				error = icons.diagnostics.Error_alt,
			},
		},
		filters = {
			enable = true,
			dotfiles = false,
			no_buffer = false,
			git_clean = false,
			git_ignored = true,
			no_bookmark = false,
			custom = { ".DS_Store" },
		},
		update_focused_file = {
			enable = true,
			update_root = { enable = true },
		},
		trash = {
			cmd = "gio trash",
		},
		log = {
			enable = false,
		},
	})
end
