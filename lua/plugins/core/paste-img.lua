return {
	"HakonHarnes/img-clip.nvim",
	event = "VeryLazy",
	opts = {},
	keys = function()
		return require("config.keymaps").get_keys("paste")
	end,
}
