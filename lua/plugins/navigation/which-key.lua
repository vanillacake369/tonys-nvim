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
		return require("config.keymaps").get_keys("which_key")
	end,
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)
		-- local material_blue = "#26C6DA"
		-- local material_green = "#66BB6A"
		-- vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = material_green })
		-- vim.api.nvim_set_hl(0, "WhichKeyTitle", { fg = material_green, bold = true })
	end,
}
