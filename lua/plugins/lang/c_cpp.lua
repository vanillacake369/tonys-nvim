return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.clangd = {
                -- PERF: query-driver 는 clangd 가 신뢰할 컴파일러 경로.
                -- 순서는 우선순위가 아니고, 매칭 항목을 모두 허용.
                -- Nix 는 *-clang-* / *-gcc-* 로 좁혀 store 전체 스캔을 회피.
                -- macOS Xcode CLT: /usr/bin/clang
                -- macOS Homebrew (Apple Silicon): /opt/homebrew/bin/{clang,gcc}
                -- non-Nix Linux: /usr/bin/gcc, /usr/local/bin/gcc
                cmd = {
                    "clangd",
                    "--log=error",
                    "--query-driver=/nix/store/*-clang-*/bin/clang,/nix/store/*-gcc-*/bin/cc,/usr/bin/clang,/opt/homebrew/bin/clang,/opt/homebrew/bin/gcc,/usr/bin/gcc,/usr/local/bin/gcc",
                },
                filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
            }
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "c", "cpp" })
        end,
    },
    {
        "mfussenegger/nvim-dap",
        opts = function(_, opts)
            opts.setup = opts.setup or {}
            table.insert(opts.setup, function(dap, debugger)
                local lldb_adapter = debugger.lldb_adapter()
                local lldb_adapter_type = debugger.lldb_adapter_type(lldb_adapter)
                if not lldb_adapter_type then
                    vim.notify("LLDB DAP adapter not found: install codelldb or lldb-dap", vim.log.levels.WARN)
                    return
                end

                dap.adapters[lldb_adapter_type] = lldb_adapter
                local native_configs = {
                    {
                        type = lldb_adapter_type,
                        name = "Debug executable",
                        request = "launch",
                        program = function()
                            return vim.fn.input("Path to executable: ", vim.uv.cwd() .. "/", "file")
                        end,
                        cwd = function()
                            return debugger.project_root({
                                "compile_commands.json",
                                "Makefile",
                                "CMakeLists.txt",
                                ".git",
                            })
                        end,
                        stopOnEntry = false,
                        args = debugger.input_args,
                    },
                }
                dap.configurations.c = native_configs
                dap.configurations.cpp = native_configs
                dap.configurations.objc = native_configs
                dap.configurations.objcpp = native_configs
            end)
        end,
    },
}
