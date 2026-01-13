return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	keys = function()
		return require("config.keymaps").get_keys("window")
	end,
}
