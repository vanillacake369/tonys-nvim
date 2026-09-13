return {
    -- JS/TS 계열 LSP 를 typescript-language-server 로 공통 등록한다.
    -- React/JSX/TSX filetype 을 한 서버에 묶어 completion 과 diagnostics 를 공유한다.
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
    -- JS/TS/TSX parser 를 treesitter 공통 설치 목록에 더한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "javascript", "typescript", "tsx" })
        end,
    },
    -- JS/TS lint 는 biomejs 로 통일해 nvim-lint 에 연결한다.
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
    -- JS/TS formatter 는 biome 를 conform filetype table 에 연결한다.
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
    -- vscode-js-debug 기반 Node launch/attach DAP 설정을 등록한다.
    -- JavaScript 와 TypeScript buffer 가 같은 debug profile 을 공유한다.
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
