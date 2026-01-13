return {
	{
		"numToStr/Comment.nvim",
		keys = function()
			return require("config.keymaps").get_keys("comment")
		end,
		opts = {},
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
	},
}
