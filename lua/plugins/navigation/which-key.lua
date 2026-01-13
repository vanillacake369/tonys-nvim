return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = function()
		return {
			preset = "modern",
			win = {
				border = "rounded",
				title = true,
				title_pos = "center",
				padding = { 2, 2 },
			},
			spec = require("config.keymaps").get_which_key_spec(),
		}
	end,
	keys = function()
		local keymaps = require("config.keymaps")
		local keys = keymaps.get_keys("which_key")
		return keys
	end,
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)
	end,
}
