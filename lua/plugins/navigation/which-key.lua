return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = function()
		return {
			preset = "modern",
			-- Hide builtin g-prefix and noisy operator keymaps (gU, gu, g~)
			filter = function(mapping)
				local dominated = { gU = true, gu = true, ["g~"] = true, gw = true }
				return not dominated[mapping.lhs]
			end,
			plugins = {
				presets = {
					g = false,
				},
			},
			win = {
				border = "rounded",
				title = true,
				title_pos = "center",
				padding = { 2, 2 },
				height = { min = 4, max = 25 },
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
