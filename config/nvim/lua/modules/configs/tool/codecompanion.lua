return function()
	local settings = require("core.settings")
	local icons = { aichat = require("modules.utils.icons").get("aichat", true) }
	local secret_key = settings.chat_api_key
	local chat_lang = settings.chat_lang
	local codex_rules = vim.fn.expand("~/.codex/AGENTS.md")
	local codex_cli = vim.fn.exepath("codex")

	require("modules.utils").load_plugin("codecompanion", {
		opts = {
			language = chat_lang,
		},
		interactions = {
			chat = {
				-- ACP gives the right pane Codex sessions, tool calls and permission prompts.
				adapter = "codex",
				roles = {
					llm = function(adapter)
						return icons.aichat.Chat .. " " .. adapter.formatted_name
					end,
					user = icons.aichat.Me .. " Me",
				},
			},
			-- Codex ACP is a chat-only adapter; use Copilot for quick inline edits.
			inline = {
				adapter = "copilot",
			},
		},
		adapters = {
			acp = {
				codex = function()
					return require("codecompanion.adapters").extend("codex", {
						commands = {
							default = { "codex-acp" },
						},
						defaults = {
							auth_method = settings.codex_acp_auth_method or "chat-gpt",
						},
						env = {
							-- Do not let the shell's cliproxyapi key win over ChatGPT auth.
							OPENAI_API_KEY = "",
							CODEX_API_KEY = "",
							DEFAULT_AUTH_REQUEST = '{"methodId":"chat-gpt"}',
							-- Use the same Codex binary and ~/.codex state as the terminal CLI.
							CODEX_PATH = codex_cli,
						},
					})
				end,
			},
			-- Keep the existing HTTP provider available as an opt-in fallback.
			openrouter = function()
				return require("codecompanion.adapters").extend("openai_compatible", {
					env = {
						url = "https://openrouter.ai/api",
						api_key = secret_key,
						chat_url = "/v1/chat/completions",
					},
					schema = {
						model = {
							default = settings.chat_models[1],
						},
					},
				})
			end,
		},
		rules = {
			default = {
				description = "Codex and common project rules",
				files = {
					".clinerules",
					".cursorrules",
					".goosehints",
					".rules",
					".windsurfrules",
					".github/copilot-instructions.md",
					"AGENT.md",
					"AGENTS.md",
					{ path = "CLAUDE.md", parser = "claude" },
					{ path = "CLAUDE.local.md", parser = "claude" },
					{ path = codex_rules, parser = "claude" },
				},
				is_preset = true,
			},
		},
		display = {
			diff = {
				enabled = true,
				close_chat_at = 100,
				layout = "vertical",
				opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
				provider = "default",
			},
			chat = {
				window = {
					layout = "vertical",
					position = "right",
					border = "single",
					width = 0.30,
					relative = "editor",
					full_height = true,
					opts = {
						breakindent = true,
						linebreak = true,
						wrap = true,
					},
				},
			},
		},
		extensions = {
			history = {
				enabled = true,
				opts = {
					keymap = "gh",
					auto_generate_title = true,
					continue_last_chat = false,
					delete_on_clearing_chat = false,
					picker = "telescope",
					enable_logging = false,
					dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
					auto_save = true,
					save_chat_keymap = "sc",
					expiration_days = 0,
				},
			},
		},
	})
end
