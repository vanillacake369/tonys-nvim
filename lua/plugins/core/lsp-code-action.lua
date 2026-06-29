local M = {
    "rachartier/tiny-code-action.nvim",
    dependencies = {
        { "nvim-lua/plenary.nvim" },
    },
    lazy = true, -- LspAttach 콜백에서 수동으로 로드
    opts = {
        backend = "vim",
        picker = "snacks",
    },
}

local function has_lsp_client(bufnr, client_name)
    return #vim.lsp.get_clients({
        bufnr = bufnr or 0,
        name = client_name,
    }) > 0
end

local function code_action_clients(bufnr)
    return vim.lsp.get_clients({
        bufnr = bufnr or 0,
        method = "textDocument/codeAction",
    })
end

local rust_expression_nodes = {
    await_expression = true,
    binary_expression = true,
    call_expression = true,
    field_expression = true,
    index_expression = true,
    method_call_expression = true,
    try_expression = true,
}

local function treesitter_range_to_vim_range(bufnr, start_row, start_col, end_row, end_col)
    local end_vim_row = end_row + 1
    local end_vim_col = end_col

    if end_col > 0 then
        end_vim_col = end_col - 1
    elseif end_row > start_row then
        end_vim_row = end_row
        local previous_line = vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, false)[1] or ""
        end_vim_col = math.max(#previous_line - 1, 0)
    end

    return {
        start = { start_row + 1, start_col },
        ["end"] = { end_vim_row, end_vim_col },
    }
end

local function rust_expression_range(bufnr)
    if vim.bo[bufnr].filetype ~= "rust" or vim.fn.mode() ~= "n" or not has_lsp_client(bufnr, "rust-analyzer") then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local ok, node = pcall(vim.treesitter.get_node, {
        bufnr = bufnr,
        pos = { cursor[1] - 1, cursor[2] },
    })
    if not ok then
        return nil
    end

    local expression

    while node do
        if rust_expression_nodes[node:type()] then
            expression = node
        end
        node = node:parent()
    end

    if not expression then
        return nil
    end

    local start_row, start_col, end_row, end_col = expression:range()
    return treesitter_range_to_vim_range(bufnr, start_row, start_col, end_row, end_col)
end

local function java_code_action(bufnr)
    if not has_lsp_client(bufnr, "jdtls") then
        return false
    end

    vim.lsp.buf.code_action()
    return true
end

local function tiny_code_action(bufnr, opts)
    if #code_action_clients(bufnr) == 0 then
        vim.notify("No LSP code action provider attached to this buffer.", vim.log.levels.INFO)
        return
    end

    local ok, tiny = pcall(require, "tiny-code-action")
    if ok then
        tiny.code_action(opts)
    else
        vim.lsp.buf.code_action(opts)
    end
end

function M.smart_code_action(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- jdtls has custom request/resolve behavior; the built-in path is less fragile.
    if java_code_action(bufnr) then
        return
    end

    tiny_code_action(bufnr, {
        range = rust_expression_range(bufnr),
    })
end

return M
