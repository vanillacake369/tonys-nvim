return {
    -- Python LSP(pylsp)를 공통 lspconfig 서버 목록에 등록한다.
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.pylsp = {
                cmd = { "pylsp" },
                filetypes = { "python" },
            }
        end,
    },
    -- Python 및 관련 문서/build 문법 parser 를 treesitter 에 추가한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "python", "ninja", "rst" })
        end,
    },
    -- Python lint 는 ruff 를 nvim-lint filetype table 에 연결한다.
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.python = { "ruff" }
        end,
    },
    -- Python formatter 는 ruff fix/import/format 순서로 conform 에 맡긴다.
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.python = { "ruff_fix", "ruff_organize_imports", "ruff_format" }
        end,
    },
    -- debugpy adapter 를 DAP 에 등록해 현재 파일 launch 를 지원한다.
    {
        "mfussenegger/nvim-dap",
        opts = function(_, opts)
            opts.setup = opts.setup or {}
            table.insert(opts.setup, function(dap)
                dap.adapters.python = {
                    type = "executable",
                    command = "python3",
                    args = { "-m", "debugpy.adapter" },
                }
                dap.configurations.python = {
                    {
                        type = "python",
                        name = "Debug",
                        request = "launch",
                        program = "${file}",
                    },
                }
            end)
        end,
    },
}
