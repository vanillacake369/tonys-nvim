-- Rust ecosystem standard: rustaceanvim
-- Provides rust-analyzer LSP, runnables/debuggables, and built-in neotest adapter.

return {
    {
        "mrcjkb/rustaceanvim",
        version = "^9",
        ft = { "rust" },
        -- `init` calls `require("blink.cmp")` synchronously; without this dep,
        -- opening a .rs file from a cold start (before any completion event
        -- forces blink to load) crashes.
        dependencies = { "saghen/blink.cmp" },
        init = function()
            -- Hand capabilities from blink.cmp to rustaceanvim's auto-configured LSP.
            vim.g.rustaceanvim = {
                server = {
                    capabilities = require("blink.cmp").get_lsp_capabilities(
                        vim.lsp.protocol.make_client_capabilities()
                    ),
                },
            }
        end,
    },
}
