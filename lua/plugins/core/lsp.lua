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

			-- nixd 프로세스 정리
			vim.api.nvim_create_autocmd("VimLeavePre", {
				group = vim.api.nvim_create_augroup("CleanupNixd", { clear = true }),
				callback = function()
					-- nixd와 그 자식 프로세스들을 모두 종료
					os.execute("pkill -9 nixd")
					os.execute("pkill -9 nixd-attrset-eval")
				end,
			})

			-- LSP 성능 향상을 위한 공통 Capabilities 설정
			local base_capabilities = vim.lsp.protocol.make_client_capabilities()
			if package.loaded["blink.cmp"] then
				base_capabilities = require("blink.cmp").get_lsp_capabilities(base_capabilities)
			end

			-- 각 서버 설정 및 활성화
			for server, config in pairs(servers) do
				-- 파일 변경 감시를 제한하여 메모리 앰플리케이션 방지
				local final_config = vim.tbl_deep_extend("force", {
					capabilities = base_capabilities,
					flags = {
						debounce_text_changes = 150, -- 텍스트 변경 시 지연 시간 설정
						allow_incremental_sync = true, -- 증분 동기화 활성화
					},
				}, config)


				local cmd
				if final_config.cmd and type(final_config.cmd) == "table" then
					cmd = final_config.cmd[1]
				elseif final_config.cmd and type(final_config.cmd) == "string" then
					cmd = final_config.cmd
				else
					cmd = server
				end

				if vim.fn.executable(cmd) == 1 then
					vim.lsp.config(server, final_config)
					vim.lsp.enable(server)
				else
					vim.notify(string.format("LSP '%s' not found. Install via nix.", cmd), vim.log.levels.ERROR)
				end
			end
		end,
	},
}
