return function()
	vim.defer_fn(function()
		require("modules.utils").load_plugin("copilot", {
			cmp = {
				enabled = false,
			},
			panel = {
				enabled = false,
			},
			suggestion = {
				enabled = true,
				auto_trigger = true,
				hide_during_completion = true,
				keymap = {
					accept = "<M-l>",
					accept_word = false,
					accept_line = false,
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
					toggle_auto_trigger = false,
				},
			},
			filetypes = {
				["dap-repl"] = false,
				["fugitive"] = false,
				["fugitiveblame"] = false,
				["git"] = false,
				["gitcommit"] = false,
				["log"] = false,
				["toggleterm"] = false,
			},
		})
	end, 100)
end
