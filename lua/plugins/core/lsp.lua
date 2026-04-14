-- Helper: LSP Capabilities (Blink.cmp Integration)
local function get_capabilities()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    return require("blink.cmp").get_lsp_capabilities(capabilities)
end

-- Helper: Global Diagnostics Configuration
local function setup_diagnostics()
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

-- Helper: Java (JDTLS) Specifics
local function get_lombok_jar()
    -- 1. 환경 변수 확인
    local env_path = os.getenv("LOMBOK_JAR")
    if env_path and vim.fn.filereadable(env_path) == 1 then
        return env_path
    end

    -- 2. PATH에 있는 lombok 래퍼 스크립트에서 추출 (Nix 특화 로직)
    local lombok_exe = vim.fn.exepath("lombok")
    if lombok_exe ~= "" then
        local f = io.open(lombok_exe, "r")
        if f then
            local content = f:read("*a")
            f:close()
            local path = content:match('(/nix/store/[^:/"%s]+%-lombok%-[^:/"%s]+/share/java/lombok%.jar)')
            if path and vim.fn.filereadable(path) == 1 then
                return path
            end
        end
    end
    return nil
end

local CODE_ACTION_TIMEOUT_MS = 1000

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

    if not client:supports_method("textDocument/codeAction") then
        return
    end

    run_generic_save_actions(client, bufnr)
end

return {
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
    {
        "rachartier/tiny-code-action.nvim",
        dependencies = {
            { "nvim-lua/plenary.nvim" },
        },
        lazy = true, -- LspAttach 콜백에서 수동으로 로드
        opts = {
            backend = "vim",
            picker = "snacks",
        },
    },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "saghen/blink.cmp" },
        config = function()
            -- 진단 설정
            setup_diagnostics()

            -- LSP 연결 시 키맵 설정 (LspAttach는 Java 포함 모든 클라이언트에 동작)
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(attach_args)
                    local keymaps = require("config.keymaps")
                    local groups = { "lsp", "lsp_actions", "code", "debug" }
                    for _, group in ipairs(groups) do
                        keymaps.apply_keymaps(group, { buffer = attach_args.buf })
                    end

                    local attached_client_id = attach_args.data and attach_args.data.client_id or nil

                    -- Organize Imports & Fix All on Save (Universal LSP-based)
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = attach_args.buf,
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
                    -- nixd와 그 자식 프로세스들을 모두 종료
                    os.execute("pkill -9 nixd")
                    os.execute("pkill -9 nixd-attrset-eval")
                end,
            })

            -- 각 서버 설정 및 활성화 (Neovim 0.11+ 신규 API 활용)
            local servers = require("config.languages").collect_lsp_servers()
            local base_capabilities = get_capabilities()

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
                    vim.notify(string.format("LSP '%s' not found. Install via nix.", cmd), vim.log.levels.ERROR)
                end
            end
        end,
    },
    -- JAVA 에 대해 JDTLS 설정 (별도 플러그인 관리)
    {
        "mfussenegger/nvim-jdtls",
        ft = { "java" },
        config = function()
            local function setup_jdtls()
                -- 프로젝트 루트 감지 (Maven, Gradle, Git 순)
                local root_markers = { "pom.xml", "build.gradle", "gradlew", ".git" }
                local root_dir = require("jdtls.setup").find_root(root_markers)
                if root_dir == "" or root_dir == nil then
                    root_dir = vim.fn.expand("%:p:h")
                end

                -- 프로젝트별 워크스페이스 경로 설정
                local project_name = vim.fn.fnamemodify(vim.fs.normalize(root_dir), ":t")
                local workspace_dir = vim.fn.stdpath("cache")
                    .. "/jdtls/workspace/"
                    .. project_name
                    .. "_"
                    .. vim.fn.sha256(root_dir):sub(1, 8)

                -- 동적으로 찾은 Lombok JAR 적용
                local lombok_jar = get_lombok_jar()
                local cmd = { "jdtls", "-data", workspace_dir }
                table.insert(cmd, "--jvm-arg=-Dfile.encoding=UTF-8")
                if lombok_jar then
                    table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
                end

                -- JDTLS 설정 (on_attach는 global LspAttach로 대체됨)
                local extendedClientCapabilities = require("jdtls").extendedClientCapabilities

                local config = {
                    cmd = cmd,
                    root_dir = root_dir,
                    capabilities = get_capabilities(),
                    offset_encoding = "utf-16",
                    flags = {
                        debounce_text_changes = 150,
                        allow_incremental_sync = false,
                    },
                    init_options = {
                        extendedClientCapabilities = extendedClientCapabilities,
                        bundles = {},
                    },
                    settings = {
                        java = {
                            signatureHelp = { enabled = true },
                            contentProvider = { preferred = "fernflower" },
                            completion = {
                                favoriteStaticMembers = {
                                    "org.junit.jupiter.api.Assertions.*",
                                    "org.mockito.Mockito.*",
                                    "java.util.Objects.requireNonNull",
                                    "java.util.Objects.requireNonNullElse",
                                    "org.hamcrest.MatcherAssert.assertThat",
                                    "org.hamcrest.Matchers.*",
                                },
                                filteredTypes = {
                                    "com.sun.*",
                                    "sun.*",
                                    "jdk.*",
                                    "org.graalvm.*",
                                    "io.micrometer.shaded.*",
                                },
                            },
                            sources = {
                                organizeImports = {
                                    starThreshold = 9999,
                                    staticStarThreshold = 9999,
                                },
                            },
                            configuration = {
                                updateBuildConfiguration = "interactive",
                                import = {
                                    gradle = { enabled = true, wrapper = { enabled = true } },
                                    maven = { enabled = true },
                                },
                            },
                        },
                    },
                }

                require("jdtls").start_or_attach(config)
            end

            -- Java 파일 열 때마다 실행
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "java",
                callback = setup_jdtls,
            })

            -- 초기 로드 시 이미 Java 파일인 경우 대응
            if vim.bo.filetype == "java" then
                setup_jdtls()
            end
        end,
    },
}
