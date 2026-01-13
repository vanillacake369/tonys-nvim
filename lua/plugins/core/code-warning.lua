return {
	{
		"b0o/SchemaStore.nvim",
		lazy = true,
		version = false,
	},
	{
		"folke/trouble.nvim",
		opts = {},
		cmd = "Trouble",
		keys = function()
			return require("config.keymaps").get_keys("diagnostics")
		end,
	},
}
