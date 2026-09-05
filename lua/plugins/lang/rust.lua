local function enable_format_on_save(_, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        group = vim.api.nvim_create_augroup("RustFormatOnSave_buf" .. bufnr, { clear = true }),
        callback = function(args)
            vim.lsp.buf.format({
                bufnr = args.buf,
                async = false,
                timeout_ms = 3000,
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
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "rust", "ron" })
        end,
    },
    {
        "mrcjkb/rustaceanvim",
        -- v9 requires Neovim 0.12+.
        version = "^8",
        lazy = false,
        dependencies = { "saghen/blink.cmp" },
        init = function()
            local lsp = require("plugins.core.lsp")
            lsp.setup_handlers()

            vim.g.rustaceanvim = {
                tools = {
                    -- COMPAT: rustaceanvim v8 emits `--message-format json`
                    -- on nextest, but cargo-nextest 0.9.140 accepts
                    -- libtest-json variants. Keep GUI runs on cargo test.
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
