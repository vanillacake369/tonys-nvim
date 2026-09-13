return {
    -- TOML LSP(taplo)를 공통 lspconfig 서버 목록에 등록한다.
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.taplo = {
                cmd = { "taplo", "lsp", "stdio" },
                filetypes = { "toml" },
            }
        end,
    },
    -- TOML parser 를 treesitter 공통 설치 목록에 추가한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "toml" })
        end,
    },
    -- TOML formatter 는 taplo 로 conform 에 연결한다.
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.toml = { "taplo" }
        end,
    },
}
