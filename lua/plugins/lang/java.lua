---@diagnostic disable: redundant-parameter
-- Java LSP(jdtls) 는 프로젝트별 workspace 와
-- 별도 lifecycle 이 필요해 공통 lsp.lua에서 분리한다.
-- Gradle/Maven classpath 동기화와 Java debug 연결도 이 파일에서 관리한다.
local project_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "pom.xml" }
local update_stale_test_classpath
local WORKSPACE_HASH_LENGTH = 8
local GRADLE_DAEMON_IDLE_TIMEOUT_MS = 300000
local ORGANIZE_IMPORTS_STAR_THRESHOLD = 9999
local JDTLS_DEBOUNCE_TEXT_CHANGES_MS = 150
local JAVA_DAP_ATTACH_PORT = 5005

-- Java DAP attach 시 디버그 포트를 입력받고, 빈 값이나 잘못된 값은 기본 포트로 처리한다.
local function java_dap_attach_port()
    local input = vim.fn.input("Debug port: ", tostring(JAVA_DAP_ATTACH_PORT))
    if input == "" then
        return JAVA_DAP_ATTACH_PORT
    end

    return tonumber(input) or JAVA_DAP_ATTACH_PORT
end

-- Lombok annotation processing을 지원할 javaagent JAR 경로를 찾는다.
-- Nix 환경에서는 `lombok` executable 이 wrapper 일 수 있다.
-- 명시 env 를 먼저 믿고, 없을 때만 wrapper 내부 jar 를 추출한다.
local function get_lombok_jar()
    local env_path = os.getenv("LOMBOK_JAR")
    if env_path and vim.fn.filereadable(env_path) == 1 then
        return env_path
    end

    local lombok_exe = vim.fn.exepath("lombok")
    if lombok_exe == "" then
        return nil
    end

    local file = io.open(lombok_exe, "r")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()

    local path = content:match('(/nix/store/[^:/"%s]+%-lombok%-[^:/"%s]+/share/java/lombok%.jar)')
    if path and vim.fn.filereadable(path) == 1 then
        return path
    end

    return nil
end

-- 프로젝트 경로별로 독립적인 JDTLS workspace cache 디렉터리를 만든다.
-- 같은 project name 이 여러 경로에 있어 hash 를 붙인다.
-- jdtls workspace cache 충돌은 stale diagnostics/import state 로 이어진다.
local function java_workspace_dir(root_dir)
    local project_name = vim.fn.fnamemodify(vim.fs.normalize(root_dir), ":t")
    return vim.fn.stdpath("cache")
        .. "/jdtls/workspace/"
        .. project_name
        .. "_"
        .. vim.fn.sha256(root_dir):sub(1, WORKSPACE_HASH_LENGTH)
end

-- TODO task tag 중복 진단을 막기 위한 Eclipse JDT preferences 파일을 생성한다.
-- Eclipse JDT task tag diagnostics 는 todo-comments 와 충돌한다.
-- 별도 prefs 파일로 jdtls 쪽 task tag 인식을 비운다.
local function java_settings_url()
    local dir = vim.fn.stdpath("cache") .. "/jdtls"
    local path = dir .. "/org.eclipse.jdt.core.prefs"
    local lines = {
        "eclipse.preferences.version=1",
        "org.eclipse.jdt.core.compiler.problem.tasks=ignore",
        "org.eclipse.jdt.core.compiler.taskTags=",
        "org.eclipse.jdt.core.compiler.taskPriorities=",
    }

    vim.fn.mkdir(dir, "p")
    if vim.fn.filereadable(path) == 0 or table.concat(vim.fn.readfile(path), "\n") ~= table.concat(lines, "\n") then
        vim.fn.writefile(lines, path)
    end

    return path
end

-- JDTLS 실행 명령에 workspace, JVM 인코딩, Gradle daemon 및 Lombok 옵션을 연결한다.
-- jdtls 는 JVM arg 를 CLI 로만 받는다.
-- Gradle daemon idle timeout 과 Lombok javaagent 를 LSP lifecycle 에 묶는다.
local function java_cmd(root_dir)
    local cmd = { "jdtls", "-data", java_workspace_dir(root_dir) }
    table.insert(cmd, "--jvm-arg=-Dfile.encoding=UTF-8")
    table.insert(cmd, "--jvm-arg=-Dorg.gradle.daemon.idletimeout=" .. GRADLE_DAEMON_IDLE_TIMEOUT_MS)

    local lombok_jar = get_lombok_jar()
    if lombok_jar then
        table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
    end

    return cmd
end

-- Java completion, import 정리, Gradle/Maven 연동과 빌드 설정 갱신 정책을 구성한다.
local function java_settings()
    return {
        ["java.settings.url"] = java_settings_url(),
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
                    starThreshold = ORGANIZE_IMPORTS_STAR_THRESHOLD,
                    staticStarThreshold = ORGANIZE_IMPORTS_STAR_THRESHOLD,
                    -- Eclipse JDT 의 일반적인 그룹 순서.
                    -- Spring/Checkstyle 등 프로젝트별 규칙은
                    -- .editorconfig 나 jdt.core.prefs 로 override.
                    importOrder = { "java", "javax", "org", "com" },
                },
            },
            import = {
                gradle = { enabled = true, wrapper = { enabled = true } },
                maven = { enabled = true },
            },
            configuration = {
                updateBuildConfiguration = "interactive",
            },
        },
    }
end

-- Gradle multi-module의 settings root를 우선하고, 그 외에는 빌드 파일로 프로젝트 root를 찾는다.
-- multi-module Gradle project 에서는 jdtls 를 settings root 에 붙인다.
-- 가장 가까운 submodule build.gradle 에 붙이면 정상적인 src/test/java 파일이
-- imported classpath model 밖으로 밀릴 수 있다.
local function java_root_dir()
    local settings_root = vim.fs.find({ "settings.gradle", "settings.gradle.kts" }, {
        path = vim.fn.expand("%:p:h"),
        upward = true,
        limit = 1,
    })[1]
    if settings_root then
        return vim.fs.dirname(settings_root)
    end

    local root_markers = { "pom.xml", "build.gradle", "build.gradle.kts", "gradlew", ".git" }
    local root_dir = require("jdtls.setup").find_root(root_markers)
    if root_dir == "" or root_dir == nil then
        return vim.fn.expand("%:p:h")
    end
    return root_dir
end

-- 공통 debugger 설정에서 Java debug/test bundle을 가져와 JDTLS 확장 기능에 연결한다.
local function java_debug_bundles()
    local selection = require("plugins.core.debugger").java_bundle_selection()
    local bundles = selection.bundles
    if vim.tbl_isempty(bundles) then
        vim.notify(
            "Java DAP bundles not found: " .. "install vscode-java-debug and vscode-java-test",
            vim.log.levels.WARN
        )
    end
    return bundles, selection.java_debug ~= false
end

-- Java buffer에 JDTLS를 시작하거나 재사용하고, 계측·completion·debug 기능을 연결한다.
local function setup_jdtls()
    local trace = require("utils.java_lsp_trace")
    trace.record("setup_enter", nil, vim.api.nvim_get_current_buf())
    local root_dir = java_root_dir()
    local jdtls = require("jdtls")
    local java_debug = require("utils.java_debug")
    local bundles, debug_available = java_debug_bundles()

    -- 첫 attach 전에 HCR을 등록하고 main 탐색은 debug 실행 시점으로 미룬다.
    -- attach 시 executeCommand의 동기 index 대기가 첫 completion을 막지 않게 한다.
    java_debug.prepare(debug_available)

    trace.record("start_or_attach", nil, vim.api.nvim_get_current_buf(), {
        root_id = vim.fn.sha256(root_dir):sub(1, 12),
        mode = "lazy",
    })
    local client_id = jdtls.start_or_attach({
        cmd = java_cmd(root_dir),
        root_dir = root_dir,
        capabilities = require("plugins.core.lsp").get_capabilities(),
        on_init = function(client)
            trace.watch(client)
            trace.record("on_init", client, vim.api.nvim_get_current_buf())
        end,
        on_attach = function(client, bufnr)
            if update_stale_test_classpath then
                update_stale_test_classpath(client, bufnr)
            end
        end,
        -- jdtls 는 UTF-16 offset 을 기대한다.
        -- incremental sync 을 활성화하여 글자 입력에 따른 증분파싱 처리 활성화
        -- +) 활성화 하지 않으면 매 입력마다 fuul sync 가 발생해 성능 저하
        -- +) incremental sync 에서 stale range 가 생기는 이슈는 0.10 이전 버전
        offset_encoding = "utf-16",
        flags = {
            debounce_text_changes = JDTLS_DEBOUNCE_TEXT_CHANGES_MS,
            allow_incremental_sync = true,
        },
        init_options = {
            extendedClientCapabilities = jdtls.extendedClientCapabilities,
            bundles = bundles,
        },
        settings = java_settings(),
    })
    trace.record("setup_return", vim.lsp.get_client_by_id(client_id or -1), vim.api.nvim_get_current_buf())
end

-- 빌드 설정 파일을 기준으로 해당 경로의 프로젝트 root를 찾는다.
local function project_root_for(path)
    local marker = vim.fs.find(project_markers, {
        path = vim.fs.dirname(path),
        upward = true,
        limit = 1,
    })[1]
    return marker and vim.fs.dirname(marker) or nil
end

-- 여러 JDTLS client 중 해당 파일을 소유한 프로젝트 client인지 확인한다.
local function client_owns_path(client, path)
    local root = client.config and client.config.root_dir
    if not root then
        return false
    end
    root = vim.fs.normalize(root)
    path = vim.fs.normalize(path)
    return path == root or path:sub(1, #root + 1) == root .. "/"
end

-- 파일이 Gradle 표준 테스트 소스 경로(src/test/java)에 있는지 확인한다.
local function is_gradle_test_java(path)
    return path:match("/src/test/java/.*%.java$") ~= nil
end

-- 생성된 .classpath에 테스트 소스 경로가 포함되어 있는지 확인한다.
-- .classpath가 없으면 stale 여부를 확정할 수 없어 갱신을 요청하지 않는다.
local function classpath_includes_test_java(path)
    local root = project_root_for(path)
    if not root then
        return true
    end

    local classpath = root .. "/.classpath"
    if vim.fn.filereadable(classpath) == 0 then
        return true
    end

    for _, line in ipairs(vim.fn.readfile(classpath)) do
        if line:find('path="src/test/java"', 1, true) then
            return true
        end
    end

    return false
end

-- 지정된 JDTLS client에 프로젝트 구성 재동기화 요청을 전송한다.
local function request_project_configuration_update(client, bufnr, uri)
    local ok, sent = pcall(client.request, client, "java/projectConfigurationUpdate", { uri = uri }, function(err)
        if err then
            vim.notify(vim.inspect(err), vim.log.levels.WARN)
        end
    end, bufnr)
    if not ok or not sent then
        vim.notify("Java project configuration update could not be sent", vim.log.levels.WARN)
    end
end

-- 테스트 소스가 classpath에서 누락된 경우에만 프로젝트 구성을 갱신한다.
update_stale_test_classpath = function(client, bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if not is_gradle_test_java(path) or classpath_includes_test_java(path) then
        return
    end

    request_project_configuration_update(client, bufnr, vim.uri_from_bufnr(bufnr))
end

-- 파일 소유권을 먼저 확인하고 해당 JDTLS client에게만 저장 알림을 보낸다.
-- 새 test source의 classpath 갱신은 기존 파일 저장과 분리한다.
local function notify_saved_java(client, args, path, uri, change_type)
    if not client_owns_path(client, path) then
        return
    end

    local ok, sent = pcall(client.notify, client, "workspace/didChangeWatchedFiles", {
        changes = { { uri = uri, type = change_type } },
    })
    if not ok or not sent then
        vim.notify("Java file change notification could not be sent", vim.log.levels.WARN)
    end
    local is_new_test_java = change_type == 1 and is_gradle_test_java(path)
    if is_new_test_java then
        request_project_configuration_update(client, args.buf, uri)
    end
end

-- JDTLS file watcher가 놓칠 수 있는 Java 파일 및 빌드 설정 변경을 수동으로 동기화한다.
-- jdtls 가 새 .java 파일을 놓치는 file-watcher race 에 대비.
-- 저장 시점에 didChangeWatchedFiles 노티를 보내 인덱싱을 강제.
-- 새 test source 는 Buildship .classpath 가 stale 할 수 있어 제한적으로
-- projectConfigurationUpdate 도 보낸다.
-- build.gradle / pom.xml 변경은 projectConfigurationUpdate 로 reimport.
local function setup_jdtls_manual_sync()
    local group = vim.api.nvim_create_augroup("JdtlsManualSync", { clear = true })
    local java_file_was_created = {}

    vim.api.nvim_create_autocmd("BufWritePre", {
        group = group,
        pattern = { "*.java" },
        callback = function(args)
            local path = vim.api.nvim_buf_get_name(args.buf)
            java_file_was_created[path] = vim.fn.filereadable(path) == 0
        end,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = { "*.java" },
        callback = function(args)
            -- 기존 Java 파일은 LSP didChange/didSave로 동기화한다.
            -- 신규 파일은 JDTLS file watcher가 생성 이벤트를 놓칠 수 있으므로
            -- 최초 저장 시에만 didChangeWatchedFiles(Created)를 보낸다.
            -- 신규 테스트 파일의 classpath 갱신은 notify_saved_java에서 처리한다.
            local path = vim.api.nvim_buf_get_name(args.buf)
            local created = java_file_was_created[path]
            java_file_was_created[path] = nil

            if not created then
                return
            end

            local uri = vim.uri_from_bufnr(args.buf)

            for _, client in
                ipairs(vim.lsp.get_clients({
                    name = "jdtls",
                }))
            do
                notify_saved_java(client, args, path, uri, 1)
            end
        end,
    })

    vim.api.nvim_create_autocmd("BufReadPost", {
        group = group,
        pattern = { "*.java" },
        callback = function(args)
            local path = vim.api.nvim_buf_get_name(args.buf)
            if not is_gradle_test_java(path) or classpath_includes_test_java(path) then
                return
            end

            local uri = vim.uri_from_bufnr(args.buf)
            for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
                if client_owns_path(client, path) then
                    request_project_configuration_update(client, args.buf, uri)
                end
            end
        end,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = project_markers,
        callback = function(args)
            local path = vim.api.nvim_buf_get_name(args.buf)
            local root = project_root_for(path)
            local uri = vim.uri_from_bufnr(args.buf)
            for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
                if not root or client_owns_path(client, root) then
                    request_project_configuration_update(client, args.buf, uri)
                end
            end
        end,
    })
end

return {
    -- Java 문법 파서를 treesitter 공통 ensure_installed에 추가한다.
    -- Java 소스의 syntax highlighting을 공통 treesitter 설정으로 처리한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "java" })
        end,
    },
    -- Java DAP attach 구성을 공통 nvim-dap setup에 등록한다.
    -- 실행 중인 Spring Boot JVM에 입력받은 debug port로 연결한다.
    {
        "mfussenegger/nvim-dap",
        opts = function(_, opts)
            opts.setup = opts.setup or {}
            table.insert(opts.setup, function(dap)
                dap.configurations.java = {
                    {
                        type = "java",
                        request = "attach",
                        name = "Attach Spring Boot JVM",
                        hostName = "127.0.0.1",
                        port = java_dap_attach_port,
                    },
                }
            end)
        end,
    },
    -- Java LSP(jdtls)를 Java 전용 plugin spec에서 시작하고 lifecycle을 관리한다.
    -- 프로젝트별 workspace, debug bundle, Gradle classpath 갱신을 함께 처리한다.
    {
        "mfussenegger/nvim-jdtls",
        dependencies = { "mfussenegger/nvim-dap" },
        ft = { "java" },
        -- Java 전용 계측과 복구 명령은 첫 FileType 이전에 등록한다.
        -- 공통 init.lua 와 LSP 설정은 이 언어의 lifecycle 을 소유하지 않는다.
        init = function()
            local trace = require("utils.java_lsp_trace")
            trace.setup()
            if vim.env.NVIM_JAVA_LSP_TRACE == "1" then
                trace.start()
            end
            require("utils.java_debug").setup()
        end,
        config = function()
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "java",
                callback = setup_jdtls,
            })

            if vim.bo.filetype == "java" then
                setup_jdtls()
            end

            setup_jdtls_manual_sync()
        end,
    },
}
