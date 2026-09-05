return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.gopls = {
                cmd = { "gopls" },
                filetypes = { "go", "gomod", "gowork", "gotmpl" },
                settings = {
                    gopls = {
                        usePlaceholders = true,
                        completeUnimported = true,
                        staticcheck = true,
                    },
                },
            }
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "go", "gomod", "gowork", "gosum" })
        end,
    },
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.go = { "golangcilint" }
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.go = { "goimports", "gofmt" }
            opts.formatters_by_ft.gomod = { "goimports", "gofmt" }
            opts.formatters_by_ft.gowork = { "goimports", "gofmt" }
            opts.formatters_by_ft.gotmpl = { "goimports", "gofmt" }
        end,
    },
    {
        "mfussenegger/nvim-dap",
        opts = function(_, opts)
            opts.setup = opts.setup or {}
            table.insert(opts.setup, function(dap)
                dap.adapters.delve = {
                    type = "server",
                    port = "${port}",
                    executable = {
                        command = "dlv",
                        args = { "dap", "-l", "127.0.0.1:${port}" },
                    },
                }
                dap.configurations.go = {
                    {
                        type = "delve",
                        name = "Debug",
                        request = "launch",
                        program = "${file}",
                    },
                    {
                        type = "delve",
                        name = "Debug (test)",
                        request = "launch",
                        mode = "test",
                        program = "${file}",
                    },
                }
            end)
        end,
    },
}
