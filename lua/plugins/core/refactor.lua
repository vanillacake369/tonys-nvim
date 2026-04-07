return {
	"ThePrimeagen/refactoring.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	keys = function()
		return require("config.keymaps").get_keys("code")
	end,
	config = function()
		require("refactoring").setup({
			prompt_func_return_type = {
				go = true,
				cpp = true,
				c = true,
				java = true,
			},
			prompt_func_param_type = {
				go = true,
				cpp = true,
				c = true,
				java = true,
			},
			printf_statements = {},
			print_var_statements = {},
		})
	end,
}
