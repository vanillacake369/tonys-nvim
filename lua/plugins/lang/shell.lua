return {
    -- shell/bash LSP 를 공통 lspconfig 서버 목록에 등록한다.
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.bashls = {
                cmd = { "bash-language-server", "start" },
                filetypes = { "sh", "bash" },
            }
        end,
    },
    -- Bash parser 를 treesitter 공통 설치 목록에 추가한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "bash" })
        end,
    },
    -- shell lint 는 shellcheck 로 nvim-lint 에 연결한다.
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.sh = { "shellcheck" }
            opts.linters_by_ft.bash = { "shellcheck" }
        end,
    },
    -- shell formatter 는 shfmt 로 conform 에 연결한다.
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.sh = { "shfmt" }
            opts.formatters_by_ft.bash = { "shfmt" }
        end,
    },
}
