local CODE_ACTION_TIMEOUT_MS = 1000
local LSP_DEBOUNCE_TEXT_CHANGES_MS = 150

local M = {}

local HOVER_POPUP_MIN_WIDTH = 96
local HOVER_POPUP_WIDTH_RATIO = 0.82
local HOVER_POPUP_MAX_WIDTH = 160
local HOVER_POPUP_MIN_HEIGHT = 24
local HOVER_POPUP_HEIGHT_RATIO = 0.72
local HOVER_POPUP_MAX_HEIGHT = 48
local HOVER_POPUP_BACKDROP = 60

local hover_generation = 0

-- 비동기 응답은 요청 당시 편집 위치에만 표시한다.
-- 요청 실패는 정의 탐색으로 연결하고 지난 요청의 응답은 UI 를 변경하지 않는다.
function M.show_documentation()
    hover_generation = hover_generation + 1
    local generation = hover_generation
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(winid)
    local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
    local function is_current()
        return generation == hover_generation
            and vim.api.nvim_win_is_valid(winid)
            and vim.api.nvim_buf_is_valid(bufnr)
            and vim.api.nvim_get_current_win() == winid
            and vim.api.nvim_get_current_buf() == bufnr
            and vim.api.nvim_buf_get_changedtick(bufnr) == changedtick
            and vim.deep_equal(vim.api.nvim_win_get_cursor(winid), cursor)
    end

    local client = vim.lsp.get_clients({
        bufnr = bufnr,
        method = "textDocument/hover",
    })[1]

    local function definitions()
        Snacks.picker.lsp_definitions()
    end

    if not client then
        return definitions()
    end

    local request_sent = client:request(
        "textDocument/hover",
        vim.lsp.util.make_position_params(winid, client.offset_encoding or "utf-16"),
        function(err, result)
            local is_current_request = is_current()
            if not is_current_request then
                return
            end
            local has_hover_contents = not err and result and result.contents
            if not has_hover_contents then
                return definitions()
            end

            local contents =
                vim.split(table.concat(vim.lsp.util.convert_input_to_markdown_lines(result.contents), "\n"), "\n", {
                    plain = true,
                    trimempty = true,
                })

            if vim.tbl_isempty(contents) then
                return definitions()
            end

            Snacks.win({
                text = table.concat(contents, "\n"),
                ft = "markdown",
                width = math.max(
                    HOVER_POPUP_MIN_WIDTH,
                    math.min(math.floor(vim.o.columns * HOVER_POPUP_WIDTH_RATIO), HOVER_POPUP_MAX_WIDTH)
                ),
                height = math.max(
                    HOVER_POPUP_MIN_HEIGHT,
                    math.min(math.floor(vim.o.lines * HOVER_POPUP_HEIGHT_RATIO), HOVER_POPUP_MAX_HEIGHT)
                ),
                border = "rounded",
                backdrop = HOVER_POPUP_BACKDROP,
                enter = true,
                wo = {
                    wrap = true,
                    linebreak = true,
                    conceallevel = 2,
                },
                keys = {
                    q = "close",
                    ["<Esc>"] = "close",
                    ["<CR>"] = function(win)
                        win:close()
                        definitions()
                    end,
                },
            })
        end,
        bufnr
    )
    if not request_sent then
        return definitions()
    end
end

function M.is_java_mapper_method_name(line, cursor_col)
    local offset = 1
    while true do
        local start_col, end_col = line:find("[%a_$][%w_$]*%s*%(", offset)
        if not start_col then
            return false
        end

        local identifier_end = assert(line:find("%s*%(", start_col)) - 1
        while identifier_end >= start_col and line:sub(identifier_end, identifier_end):match("%s") do
            identifier_end = identifier_end - 1
        end

        if cursor_col >= start_col - 1 and cursor_col < identifier_end then
            return true
        end
        offset = end_col + 1
    end
end

local function should_use_mybatis_definition()
    if vim.bo.filetype == "xml" then
        return true
    end
    if vim.bo.filetype ~= "java" then
        return false
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()
    return M.is_java_mapper_method_name(line, cursor[2])
end

function M.get_capabilities()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok, blink = pcall(require, "blink.cmp")
    if ok and blink.get_lsp_capabilities then
        return blink.get_lsp_capabilities(capabilities)
    end
    return capabilities
end

function M.smart_definition()
    local ok, mybatis = pcall(require, "mybatis")
    if ok and mybatis.is_mapper_file(0) and should_use_mybatis_definition() then
        mybatis.jump_or_fallback()
        return
    end

    local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/definition" })
    if #clients == 0 then
        vim.notify(
            ("No LSP definition provider attached (filetype: %s). Check :LspInfo."):format(vim.bo.filetype),
            vim.log.levels.INFO
        )
        return
    end

    Snacks.picker.lsp_definitions()
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
        -- Neovim 0.11 은 pull-diagnostic refresh 를 구현하지 않는다.
        -- rust-analyzer 가 시끄럽게 경고하지 않도록 요청만 인정한다.
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
    -- Rust refactor action 은 커서 주변 expression 범위가 더 정확함.
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
    -- jdtls 는 resolve 동작이 달라 built-in action 경로가 안정적.
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
    -- organizeImports/fixAll 은 buffer 전체 문맥이 필요하다.
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

    -- jdtls snapshot 은 generic codeAction/source.fixAll 에서 crash 날 수 있다.
    -- 전용 java/organizeImports request 를 대신 사용한다.
    if client.name == "jdtls" then
        run_jdtls_organize_imports(client, bufnr)
        return
    end

    -- Rust save workflow 는 rustaceanvim/rustfmt 가 소유한다.
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
    -- JSON/YAML schema catalog 를 로컬 플러그인으로 공급하기 위해 추가.
    -- yaml.lua 같은 언어 설정에서 schemaStore fetch 대신 이 catalog 를 사용한다.
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false,
}

M[2] = {
    -- code action 을 snacks picker 로 고르고 적용하기 위해 추가.
    -- Java/Rust 처럼 예외가 있는 언어는 smart_code_action 에서 분기한다.
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
    -- 공통 LSP 진단, keymap attach, save action 실행을 담당하는 기본 LSP spec.
    -- 언어별 파일은 opts.servers 만 확장해서 서버 등록을 이 spec 에 맡긴다.
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp" },
    config = function(_, opts)
        M.setup_diagnostics()
        M.setup_handlers()

        -- LspAttach 는 Java 포함 모든 LSP 클라이언트에 동작한다.
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(attach_args)
                local keymaps = require("config.keymaps")
                keymaps.bind({ "lsp", "lsp_actions", "code", "debug" }, { buffer = attach_args.buf })

                local attached_client_id = attach_args.data and attach_args.data.client_id or nil

                -- save action 은 buffer 와 client id 단위로 scope 를 나눈다.
                -- client restart 때 handler 중복을 막고, 여러 LSP 의 독립 handler 는 유지한다.
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

        -- 종료는 Neovim 기본 LSP handler 가 현재 인스턴스의 client 만 정리한다.
        -- 이름 기반 pkill 은 다른 세션의 nixd/evaluator 까지 종료하므로 사용하지 않는다.

        -- 각 서버 설정 및 활성화 (Neovim 0.11+ 신규 API 활용)
        local servers = opts.servers or {}
        local base_capabilities = M.get_capabilities()

        for server, config in pairs(servers) do
            local final_config = vim.tbl_deep_extend("force", {
                capabilities = base_capabilities,
                flags = {
                    debounce_text_changes = LSP_DEBOUNCE_TEXT_CHANGES_MS,
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
