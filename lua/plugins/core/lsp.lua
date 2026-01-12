return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lang = require("config.languages")
		local servers = lang.collect_lsp_servers()

		-- 진단 설정
		vim.diagnostic.config({
			virtual_text = {
				prefix = "●",
				source = "if_many",
			},
			underline = true,
			signs = true,
			update_in_insert = true,
			severity_sort = true,
		})

		-- LSP 연결 시 키맵 설정
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local opts = { buffer = args.buf }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
			end,
		})

		-- 각 서버 설정 및 활성화
		for server, config in pairs(servers) do
			local cmd
			if config.cmd and type(config.cmd) == "table" then
				cmd = config.cmd[1]
			elseif config.cmd and type(config.cmd) == "string" then
				cmd = config.cmd
			else
				cmd = server
			end

			if vim.fn.executable(cmd) == 1 then
				-- Use new vim.lsp.config API (Nvim 0.11+)
				vim.lsp.config(server, config)
				vim.lsp.enable(server)
			else
				vim.notify(string.format("LSP '%s' not found. Install via nix.", cmd), vim.log.levels.ERROR)
			end
		end
	end,
}
