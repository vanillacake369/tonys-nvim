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
        -- Neovim 0.11 does not implement pull-diagnostic refresh. Acknowledge
        -- the server request so rust-analyzer does not emit a noisy warning.
        return vim.NIL
    end
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
    -- NOTE: organizeImports/fixAll 은 cursor 위치가 아니라 buffer 전체 문맥이 필요하다.
    -- 현재 줄 range 로 요청하면 일부 서버가 action 을 돌려주지 않는다.
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

    -- jdtls snapshot can crash on generic codeAction/source.fixAll.
    -- Use the dedicated java/organizeImports request instead.
    if client.name == "jdtls" then
        run_jdtls_organize_imports(client, bufnr)
        return
    end

    -- NOTE: Rust save workflow 는 rustaceanvim/rustfmt 가 소유한다.
    -- generic source.fixAll 을 섞으면 clippy/rust-analyzer action 과 중복될 수 있다.
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
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp" },
    config = function()
        M.setup_diagnostics()
        M.setup_handlers()

        -- LSP 연결 시 키맵 설정 (LspAttach는 Java 포함 모든 클라이언트에 동작)
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(attach_args)
                local keymaps = require("config.keymaps")
                keymaps.bind({ "lsp", "lsp_actions", "code", "debug" }, { buffer = attach_args.buf })

                local attached_client_id = attach_args.data and attach_args.data.client_id or nil

                -- NOTE: LSP attach 시점에 save action 을 client 별로 등록한다.
                -- 버퍼+클라이언트별 augroup + clear=true:
                -- (1) 동일 버퍼+클라이언트가 재부착될 때 (jdtls 재시작 등)
                --     BufWritePre 가 스택되는 것을 방지.
                -- (2) 동일 버퍼에 여러 LSP 가 동시 부착될 때
                --     서로의 handler 를 wipe 하지 않도록 client_id 까지 namespace 분리.
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
                -- nixd 와 자식 프로세스 graceful 종료 (SIGTERM).
                -- SIGKILL(-9) 은 nixd 의 nix daemon evaluation cache 가
                -- 플러시되지 못해 증분 평가 캐시가 손상될 수 있음.
                os.execute("pkill -15 nixd")
                os.execute("pkill -15 nixd-attrset-eval")
            end,
        })

        -- 각 서버 설정 및 활성화 (Neovim 0.11+ 신규 API 활용)
        local servers = require("config.languages").collect_lsp_servers()
        local base_capabilities = M.get_capabilities()

        for server, config in pairs(servers) do
            local final_config = vim.tbl_deep_extend("force", {
                capabilities = base_capabilities,
                flags = {
                    debounce_text_changes = 150, -- 텍스트 변경 시 지연 시간 설정
                    allow_incremental_sync = true, -- 증분 동기화 활성화
                },
            }, config)

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
    end,
}

return M
