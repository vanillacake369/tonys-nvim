return {
    -- Go LSP(gopls)를 공통 lspconfig 서버 목록에 등록한다.
    -- placeholder, unimported completion, staticcheck 로 IDE 피드백을 강화한다.
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
    -- Go 문법 파서를 treesitter 공통 ensure_installed 에 추가한다.
    -- go.mod/work/sum 까지 포함해 모듈 파일 편집도 같은 highlighting 을 쓴다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "go", "gomod", "gowork", "gosum" })
        end,
    },
    -- Go lint 는 golangci-lint 로 모아 nvim-lint 실행 흐름에 태운다.
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.go = { "golangcilint" }
        end,
    },
    -- Go formatter 는 import 정리 후 gofmt 를 적용하도록 conform 에 연결한다.
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
    -- Delve DAP adapter 와 기본 launch/test configuration 을 등록한다.
    -- 공통 debugger keymap 이 Go buffer 에서 바로 동작하도록 하기 위한 설정이다.
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
