return function()
	require("modules.utils").load_plugin("avante", {
		provider = "copilot",
		auto_suggestions_provider = "copilot",
		windows = {
			position = "right",
			width = 38,
			wrap = true,
		},
	})
end
