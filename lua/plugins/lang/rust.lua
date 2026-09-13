local RUST_FORMAT_TIMEOUT_MS = 3000

local function enable_format_on_save(_, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        group = vim.api.nvim_create_augroup("RustFormatOnSave_buf" .. bufnr, { clear = true }),
        callback = function(args)
            vim.lsp.buf.format({
                bufnr = args.buf,
                async = false,
                timeout_ms = RUST_FORMAT_TIMEOUT_MS,
                filter = function(client)
                    return client.name == "rust-analyzer"
                end,
            })
        end,
    })
end

local function rust_analyzer_settings()
    return {
        ["rust-analyzer"] = {
            check = {
                command = "clippy",
            },
            procMacro = {
                enable = true,
            },
        },
    }
end

local function rust_analyzer_cmd()
    local file = vim.api.nvim_buf_get_name(0)
    local dir = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()
    local root = require("plugins.core.debugger").find_upward({ "Cargo.toml", "rust-toolchain.toml" }, dir)

    if root and vim.fn.filereadable(root .. "/.envrc") == 1 and vim.fn.executable("direnv") == 1 then
        return { "direnv", "exec", root, "rust-analyzer" }
    end

    return { "rust-analyzer" }
end

return {
    -- Rust/RON parser 를 treesitter 공통 설치 목록에 추가한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "rust", "ron" })
        end,
    },
    -- rustaceanvim 으로 rust-analyzer, RustLsp 명령, DAP adapter 를 묶어 관리한다.
    -- direnv project 는 rust-analyzer 도 같은 개발 shell 안에서 실행한다.
    {
        "mrcjkb/rustaceanvim",
        -- v9 는 Neovim 0.12 이상이 필요해서 v8 로 고정한다.
        version = "^8",
        lazy = false,
        dependencies = { "saghen/blink.cmp" },
        init = function()
            local lsp = require("plugins.core.lsp")
            lsp.setup_handlers()

            vim.g.rustaceanvim = {
                tools = {
                    -- rustaceanvim v8 은 nextest 에서 `--message-format json` 을 내보내지만
                    -- cargo-nextest 0.9.140 은 libtest-json 계열만 받는다.
                    -- GUI 실행은 cargo test 로 유지한다.
                    enable_nextest = false,
                    code_actions = {
                        ui_select_fallback = true,
                    },
                },
                server = {
                    cmd = rust_analyzer_cmd,
                    capabilities = lsp.get_capabilities(),
                    on_attach = enable_format_on_save,
                    default_settings = rust_analyzer_settings(),
                },
                dap = {
                    adapter = require("plugins.core.debugger").lldb_adapter,
                },
            }
        end,
    },
}
