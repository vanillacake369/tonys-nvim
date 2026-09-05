return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.ts_ls = {
                cmd = { "typescript-language-server", "--stdio" },
                filetypes = {
                    "javascript",
                    "javascriptreact",
                    "javascript.jsx",
                    "typescript",
                    "typescriptreact",
                    "typescript.tsx",
                },
            }
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "javascript", "typescript", "tsx" })
        end,
    },
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.javascript = { "biomejs" }
            opts.linters_by_ft.javascriptreact = { "biomejs" }
            opts.linters_by_ft["javascript.jsx"] = { "biomejs" }
            opts.linters_by_ft.typescript = { "biomejs" }
            opts.linters_by_ft.typescriptreact = { "biomejs" }
            opts.linters_by_ft["typescript.tsx"] = { "biomejs" }
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.javascript = { "biome" }
            opts.formatters_by_ft.javascriptreact = { "biome" }
            opts.formatters_by_ft["javascript.jsx"] = { "biome" }
            opts.formatters_by_ft.typescript = { "biome" }
            opts.formatters_by_ft.typescriptreact = { "biome" }
            opts.formatters_by_ft["typescript.tsx"] = { "biome" }
        end,
    },
    {
        "mfussenegger/nvim-dap",
        opts = function(_, opts)
            opts.setup = opts.setup or {}
            table.insert(opts.setup, function(dap, debugger)
                local js_debug = debugger.js_debug_adapter()
                if not js_debug then
                    vim.notify("JavaScript DAP adapter not found: install js-debug", vim.log.levels.WARN)
                    return
                end

                dap.adapters["pwa-node"] = {
                    type = "server",
                    host = "127.0.0.1",
                    port = "${port}",
                    executable = {
                        command = js_debug,
                        args = { "${port}", "127.0.0.1" },
                    },
                }
                local js_configs = {
                    {
                        type = "pwa-node",
                        request = "launch",
                        name = "Launch file",
                        program = "${file}",
                        cwd = "${workspaceFolder}",
                        args = debugger.input_args,
                    },
                    {
                        type = "pwa-node",
                        request = "attach",
                        name = "Attach process",
                        processId = require("dap.utils").pick_process,
                        cwd = "${workspaceFolder}",
                    },
                }
                dap.configurations.javascript = js_configs
                dap.configurations.javascriptreact = js_configs
                dap.configurations.typescript = js_configs
                dap.configurations.typescriptreact = js_configs
            end)
        end,
    },
}
