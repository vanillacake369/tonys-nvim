return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	-- event = { "BufReadPost", "BufNewFile" },
	build = ":TSUpdate",
	config = function()
		local lang = require("config.languages")
		local configs = require("nvim-treesitter.configs")

		configs.setup({
			highlight = { enable = true },
			indent = { enable = true },
			autotag = { enable = true },
			ensure_installed = lang.collect_treesitter_parsers(),
		})
	end,
}
