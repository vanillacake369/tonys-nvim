return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"rachartier/tiny-code-action.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
		},
		lazy = true, -- LspAttach 콜백에서 수동으로 로드
		opts = {
			backend = "vim",
			picker = "snacks",
		},
	},
	{
		"saghen/blink.cmp",
		optional = true,
		opts = {
			sources = {
				-- add lazydev to your completion providers
				default = { "lazydev", "lsp", "path", "snippets", "buffer" },
				providers = {
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						-- make lazydev completions top priority (see `:h blink.cmp`)
						score_offset = 100,
					},
				},
			},
		},
	},
	{
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
					local keymaps = require("config.keymaps")
					keymaps.apply_keymaps("lsp", { buffer = args.buf })
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
	},
}
