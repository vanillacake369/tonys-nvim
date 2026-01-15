return {
	"nvim-pack/nvim-spectre",
	dependencies = { "folke/trouble.nvim", "nvim-mini/mini.icons" },
	keys = function()
		return require("config.keymaps").get_keys("search_replace")
	end,
	opts = {},
}
