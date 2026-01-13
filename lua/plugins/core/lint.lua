return {
	"mfussenegger/nvim-lint",
	event = { "BufWritePost", "BufReadPost", "InsertLeave" },
	config = function()
		local lint = require("lint")
		local lang = require("config.languages")

		-- yamllint 설정 커스터마이징
		lint.linters.yamllint.args = {
			"-c",
			vim.fn.stdpath("config") .. "/.yamllint",
			"--format",
			"parsable",
			"-",
		}

		-- selene 설정 커스터마이징
		lint.linters.selene.args = {
			"--display-style",
			"quiet",
			"--config",
			vim.fn.stdpath("config") .. "/selene.toml",
			"-",
		}

		-- Collect linters from language configuration
		lint.linters_by_ft = lang.collect_linters()

		-- 린트 실행 자동 명령
		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
			group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
			callback = function()
				require("lint").try_lint()
			end,
		})
	end,
}
