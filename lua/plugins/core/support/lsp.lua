local M = {}

function M.get_capabilities()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok, blink = pcall(require, "blink.cmp")
    if ok and blink.get_lsp_capabilities then
        return blink.get_lsp_capabilities(capabilities)
    end
    return capabilities
end

function M.setup_diagnostics()
    vim.diagnostic.config({
        virtual_text = {
            prefix = "●",
            source = "if_many",
        },
        underline = true,
        signs = true,
        update_in_insert = true,
        severity_sort = true,
    })
end

function M.setup_handlers()
    vim.lsp.handlers["workspace/diagnostic/refresh"] = function()
        -- Neovim 0.11 does not implement pull-diagnostic refresh. Acknowledge
        -- the server request so rust-analyzer does not emit a noisy warning.
        return vim.NIL
    end
end

return M
