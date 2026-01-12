return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = "ConformInfo",
	keys = {
		{
			"<leader>cf",
			function()
				local conform = require("conform")
				-- Visual 모드라면 선택 영역을, 아니라면 전체 파일을 포맷팅
				conform.format({
					async = true,
					lsp_format = "fallback",
					range = true,
				})
			end,
			mode = { "n", "v" },
			desc = "Format file or range",
		},
	},
	opts = function()
		local lang = require("config.languages")

		return {
			default_format_opts = {
				timeout_ms = 3000,
				async = false,
				quiet = false,
				lsp_format = "fallback",
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback",
			},
			-- languages.lua에서 수집한 포맷터 맵을 자동으로 주입합니다.
			formatters_by_ft = lang.collect_formatters(),

			formatters = {
				injected = {
					options = {
						ignore_errors = true,
					},
				},
			},
		}
	end,
}
