return {
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
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "python", "ninja", "rst" })
        end,
    },
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.python = { "ruff" }
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.python = { "ruff_fix", "ruff_organize_imports", "ruff_format" }
        end,
    },
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
