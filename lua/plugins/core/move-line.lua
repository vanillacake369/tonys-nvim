return {
	"nvim-lua/plenary.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		local keymaps = require("config.keymaps")
		keymaps.apply_keymaps("move")
	end,
}
