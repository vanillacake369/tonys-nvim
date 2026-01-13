return {
	"rmagatti/auto-session",
	lazy = false,
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	config = function()
		require("auto-session").setup({
			suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
		})

		-- 세션 복원 후 모든 버퍼 강제 로드 및 오류 방지 설정
		vim.api.nvim_create_autocmd("SessionLoadPost", {
			callback = function()
				vim.defer_fn(function()
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if vim.api.nvim_buf_is_valid(buf) and not vim.api.nvim_buf_is_loaded(buf) then
							vim.fn.bufload(buf)
						end
					end
					local buf_name = vim.api.nvim_buf_get_name(0)
					if buf_name ~= "" and vim.bo.buftype == "" then
						vim.cmd("edit!")
					end
				end, 100)
			end,
		})
	end,
}
