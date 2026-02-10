-- GitHub Copilot Integration
-- AI-powered code completion and suggestions

return {
	"zbirenbaum/copilot.lua",
	event = "InsertEnter",
	config = function()
		require("copilot").setup({
			suggestion = {
				enabled = true,
				auto_trigger = true,
				keymap = {
					accept = "<M-l>",
					accept_word = false,
					accept_line = false,
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
			},
			panel = {
				enabled = true,
				auto_refresh = false,
			},
		})

		-- Hide Copilot suggestions when blink.cmp menu opens
		vim.api.nvim_create_autocmd("User", {
			pattern = "BlinkCmpMenuOpen",
			callback = function()
				require("copilot.suggestion").dismiss()
				vim.b.copilot_suggestion_hidden = true
			end,
		})

		-- Restore Copilot suggestions when blink.cmp menu closes
		vim.api.nvim_create_autocmd("User", {
			pattern = "BlinkCmpMenuClose",
			callback = function()
				vim.b.copilot_suggestion_hidden = false
			end,
		})
	end,
}
