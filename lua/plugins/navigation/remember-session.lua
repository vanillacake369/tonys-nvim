return {
	"rmagatti/auto-session",
	lazy = false,
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	opts = {
		suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
	},
	config = function(_, opts)
		require("auto-session").setup(opts)

		vim.api.nvim_create_autocmd("SessionLoadPost", {
			callback = function()
				vim.defer_fn(function()
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
							local ft = vim.bo[buf].filetype
							if ft and ft ~= "" then
								-- filetype을 다시 설정하여 treesitter 활성화
								vim.bo[buf].filetype = ft
							end
						end
					end
				end, 100) -- 100ms 지연
			end,
		})
	end,
}
