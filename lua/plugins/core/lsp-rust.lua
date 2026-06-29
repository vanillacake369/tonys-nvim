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

return {
    "mrcjkb/rustaceanvim",
    -- v9 requires Neovim 0.12+.
    version = "^8",
    lazy = false,
    dependencies = { "saghen/blink.cmp" },
    init = function()
        local lsp = require("plugins.core.support.lsp")
        lsp.setup_handlers()

        vim.g.rustaceanvim = {
            tools = {
                code_actions = {
                    ui_select_fallback = true,
                },
            },
            server = {
                capabilities = lsp.get_capabilities(),
                on_attach = enable_format_on_save,
                default_settings = rust_analyzer_settings(),
            },
        }
    end,
}
