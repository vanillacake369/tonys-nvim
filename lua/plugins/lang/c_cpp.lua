return {
    -- C/C++ 계열 LSP(clangd)를 공통 lspconfig 서버 목록에 등록한다.
    -- query-driver 를 제한해 Nix/Homebrew/Linux compiler 탐색을 안정화한다.
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.clangd = {
                -- query-driver 는 clangd 가 신뢰할 컴파일러 경로.
                -- 순서는 우선순위가 아니고, 매칭 항목을 모두 허용.
                -- Nix 는 *-clang-* / *-gcc-* 로 좁혀 store 전체 스캔을 회피.
                -- macOS Xcode CLT 는 /usr/bin/clang 을 허용한다.
                -- macOS Homebrew(Apple Silicon) 는 /opt/homebrew/bin/{clang,gcc} 를 허용한다.
                -- non-Nix Linux 는 /usr/bin/gcc, /usr/local/bin/gcc 를 허용한다.
                cmd = {
                    "clangd",
                    "--log=error",
                    "--query-driver=/nix/store/*-clang-*/bin/clang,/nix/store/*-gcc-*/bin/cc,/usr/bin/clang,/opt/homebrew/bin/clang,/opt/homebrew/bin/gcc,/usr/bin/gcc,/usr/local/bin/gcc",
                },
                filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
            }
        end,
    },
    -- C/C++ parser 를 treesitter 공통 설치 목록에 추가한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "c", "cpp" })
        end,
    },
    -- LLDB/codelldb adapter 를 DAP 에 연결해 native executable debug 를 지원한다.
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
