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

local function find_upward(names, start_path)
    local found = vim.fs.find(names, { path = start_path, upward = true, limit = 1 })[1]
    return found and vim.fs.dirname(found) or nil
end

local function rust_analyzer_cmd()
    local file = vim.api.nvim_buf_get_name(0)
    local dir = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()
    local root = find_upward({ "Cargo.toml", "rust-toolchain.toml" }, dir)

    if root and vim.fn.filereadable(root .. "/.envrc") == 1 and vim.fn.executable("direnv") == 1 then
        return { "direnv", "exec", root, "rust-analyzer" }
    end

    return { "rust-analyzer" }
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
                cmd = rust_analyzer_cmd,
                capabilities = lsp.get_capabilities(),
                on_attach = enable_format_on_save,
                default_settings = rust_analyzer_settings(),
            },
        }
    end,
}
