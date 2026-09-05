local CODE_ACTION_TIMEOUT_MS = 1000

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
        virtual_lines = false,
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
        -- COMPAT: Neovim 0.11 does not implement pull-diagnostic refresh.
        -- Acknowledge the request so rust-analyzer does not warn noisily.
        return vim.NIL
    end
end

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
    -- NOTE: Rust refactor action 은 커서 주변 expression 범위가 더 정확함.
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
    -- NOTE: jdtls 는 resolve 동작이 달라 built-in action 경로가 안정적.
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

    if java_code_action(bufnr) then
        return
    end

    tiny_code_action(bufnr, {
        range = rust_expression_range(bufnr),
    })
end

local function get_lsp_client(client_id)
    if not client_id then
        return nil
    end
    return vim.lsp.get_client_by_id(client_id)
end

local function apply_workspace_edit_if_present(edit, offset_encoding)
    if edit then
        vim.lsp.util.apply_workspace_edit(edit, offset_encoding)
    end
end

local function request_full_buffer_code_actions(client, bufnr, kind)
    -- NOTE: organizeImports/fixAll 은 buffer 전체 문맥이 필요하다.
    -- 현재 줄 range 는 일부 서버가 action 을 돌려주지 않는다.
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local last_line = math.max(line_count - 1, 0)
    local last_line_text = vim.api.nvim_buf_get_lines(bufnr, last_line, last_line + 1, false)[1] or ""

    local params = vim.lsp.util.make_given_range_params(
        { 0, 0 },
        { last_line, #last_line_text },
        bufnr,
        client.offset_encoding
    )
    params.context = {
        only = { kind },
        diagnostics = {},
    }

    return client:request_sync("textDocument/codeAction", params, CODE_ACTION_TIMEOUT_MS, bufnr)
end

local function run_code_action_kind(client, bufnr, kind)
    local response = request_full_buffer_code_actions(client, bufnr, kind)
    for _, action in ipairs((response and response.result) or {}) do
        apply_workspace_edit_if_present(action.edit, client.offset_encoding)
        if action.command then
            client:request_sync("workspace/executeCommand", action.command, CODE_ACTION_TIMEOUT_MS, bufnr)
        end
    end
end

local function run_generic_save_actions(client, bufnr)
    for _, kind in ipairs({ "source.organizeImports", "source.fixAll" }) do
        run_code_action_kind(client, bufnr, kind)
    end
end

local function run_jdtls_organize_imports(client, bufnr)
    local params = {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        context = { diagnostics = {} },
    }
    local response = client:request_sync("java/organizeImports", params, CODE_ACTION_TIMEOUT_MS, bufnr)
    apply_workspace_edit_if_present(response and response.result, client.offset_encoding)
end

local function run_lsp_save_actions(bufnr, client_id)
    local client = get_lsp_client(client_id)
    if not client then
        return
    end

    -- COMPAT: jdtls snapshot can crash on generic codeAction/source.fixAll.
    -- Use the dedicated java/organizeImports request instead.
    if client.name == "jdtls" then
        run_jdtls_organize_imports(client, bufnr)
        return
    end

    -- NOTE: Rust save workflow 는 rustaceanvim/rustfmt 가 소유한다.
    -- generic source.fixAll 은 clippy/rust-analyzer action 과 중복될 수 있다.
    if client.name == "rust-analyzer" then
        return
    end

    if not client:supports_method("textDocument/codeAction") then
        return
    end

    run_generic_save_actions(client, bufnr)
end

M[1] = {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false,
}

M[2] = {
    "rachartier/tiny-code-action.nvim",
    dependencies = {
        { "nvim-lua/plenary.nvim" },
    },
    lazy = true,
    opts = {
        backend = "vim",
        picker = "snacks",
    },
}

M[3] = {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp" },
    config = function(_, opts)
        M.setup_diagnostics()
        M.setup_handlers()

        -- NOTE: LspAttach 는 Java 포함 모든 LSP 클라이언트에 동작한다.
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(attach_args)
                local keymaps = require("config.keymaps")
                keymaps.bind({ "lsp", "lsp_actions", "code", "debug" }, { buffer = attach_args.buf })

                local attached_client_id = attach_args.data and attach_args.data.client_id or nil

                -- NOTE: save actions are scoped by buffer and client id.
                -- This prevents duplicate handlers on client restart while
                -- preserving independent handlers for multiple attached LSPs.
                vim.api.nvim_create_autocmd("BufWritePre", {
                    buffer = attach_args.buf,
                    group = vim.api.nvim_create_augroup(
                        "LspSaveActions_buf" .. attach_args.buf .. "_client" .. tostring(attached_client_id or 0),
                        { clear = true }
                    ),
                    callback = function(write_args)
                        run_lsp_save_actions(write_args.buf, attached_client_id)
                    end,
                })
            end,
        })

        -- nixd 프로세스 정리 (Vim 종료 시)
        vim.api.nvim_create_autocmd("VimLeavePre", {
            group = vim.api.nvim_create_augroup("CleanupNixd", { clear = true }),
            callback = function()
                -- WARN: stop nixd with SIGTERM so evaluation caches can flush.
                -- SIGKILL can leave stale incremental evaluation state behind.
                os.execute("pkill -15 nixd")
                os.execute("pkill -15 nixd-attrset-eval")
            end,
        })

        -- 각 서버 설정 및 활성화 (Neovim 0.11+ 신규 API 활용)
        local servers = opts.servers or {}
        local base_capabilities = M.get_capabilities()

        for server, config in pairs(servers) do
            local final_config = vim.tbl_deep_extend("force", {
                capabilities = base_capabilities,
                flags = {
                    debounce_text_changes = 150, -- 텍스트 변경 시 지연 시간 설정
                    allow_incremental_sync = true, -- 증분 동기화 활성화
                },
            }, config)

            if config.enabled ~= false then
                -- 실행 가능 여부 확인
                local cmd = (type(final_config.cmd) == "table" and final_config.cmd[1]) or final_config.cmd or server
                if vim.fn.executable(cmd) == 1 then
                    vim.lsp.config(server, final_config)
                    vim.lsp.enable(server)
                else
                    vim.notify(
                        string.format(
                            "LSP '%s' not found in PATH. Install it via your package manager (nix, brew, apt, etc.).",
                            cmd
                        ),
                        vim.log.levels.ERROR
                    )
                end
            end
        end
    end,
    opts = {
        servers = {},
    },
}

return M
