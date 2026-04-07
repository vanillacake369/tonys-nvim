local lang = require("config.languages")

-- Nix 환경에서 설치된 '코어' nvim-treesitter 경로를 검색합니다.
local function find_nix_plugin()
	local paths = {
		"/nix/store/*-vimplugin-nvim-treesitter-*[0-9]*/",
		"/nix/store/*-vimplugin-nvim-treesitter/",
		"/etc/profiles/per-user/*/share/vim-plugins/nvim-treesitter",
		"~/.nix-profile/share/vim-plugins/nvim-treesitter",
	}

	for _, path in ipairs(paths) do
		local dir = vim.fn.glob(path, true, true)[1]
		if dir and vim.fn.isdirectory(dir .. "/lua") == 1 then
			return dir
		end
	end
	return nil
end

local nix_dir = find_nix_plugin()

-- Treesitter 설정 테이블 (중첩 완화를 위해 미리 정의)
local ts_config = {
	ensure_installed = nix_dir and {} or lang.collect_treesitter_parsers(),
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
	indent = { enable = true },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<CR>",
			node_incremental = "<CR>",
			scope_incremental = "<Tab>",
			node_decremental = "<BS>",
		},
	},
}

return {
	"nvim-treesitter/nvim-treesitter",
	dir = nix_dir,
	build = not nix_dir and ":TSUpdate" or nil,
	enabled = true,
	lazy = false,

	config = function()
		local ok, configs = pcall(require, "nvim-treesitter.configs")

		-- 1. 모듈 로드 실패 시(Nix 특수 환경 등), Neovim 내장 기능만 활성화하고 조기 종료
		if not ok then
			vim.api.nvim_create_autocmd("FileType", {
				callback = function() pcall(vim.treesitter.start) end,
			})
			return
		end

		-- 2. 모듈 로드 성공 시 설정 적용
		configs.setup(ts_config)
	end,
}
