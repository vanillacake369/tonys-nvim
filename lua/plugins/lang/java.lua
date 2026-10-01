-- Java 는 jdtls 전용 lifecycle 이 필요해 공통 lsp.lua 와 분리.
local project_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "pom.xml" }
local update_stale_test_classpath
local WORKSPACE_HASH_LENGTH = 8
local GRADLE_DAEMON_IDLE_TIMEOUT_MS = 300000
local ORGANIZE_IMPORTS_STAR_THRESHOLD = 9999
local JDTLS_DEBOUNCE_TEXT_CHANGES_MS = 150
local JAVA_DAP_ATTACH_PORT = 5005

local function java_dap_attach_port()
    local input = vim.fn.input("Debug port: ", tostring(JAVA_DAP_ATTACH_PORT))
    if input == "" then
        return JAVA_DAP_ATTACH_PORT
    end

    return tonumber(input) or JAVA_DAP_ATTACH_PORT
end

local function get_lombok_jar()
    -- Nix 환경에서는 `lombok` executable 이 wrapper 일 수 있다.
    -- 명시 env 를 먼저 믿고, 없을 때만 wrapper 내부 jar 를 추출한다.
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

local function java_workspace_dir(root_dir)
    -- 같은 project name 이 여러 경로에 있어 hash 를 붙인다.
    -- jdtls workspace cache 충돌은 stale diagnostics/import state 로 이어진다.
    local project_name = vim.fn.fnamemodify(vim.fs.normalize(root_dir), ":t")
    return vim.fn.stdpath("cache")
        .. "/jdtls/workspace/"
        .. project_name
        .. "_"
        .. vim.fn.sha256(root_dir):sub(1, WORKSPACE_HASH_LENGTH)
end

local function java_settings_url()
    -- Eclipse JDT task tag diagnostics 는 todo-comments 와 충돌한다.
    -- 별도 prefs 파일로 jdtls 쪽 task tag 인식을 비운다.
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

local function java_cmd(root_dir)
    -- jdtls 는 JVM arg 를 CLI 로만 받는다.
    -- Gradle daemon idle timeout 과 Lombok javaagent 를 LSP lifecycle 에 묶는다.
    local cmd = { "jdtls", "-data", java_workspace_dir(root_dir) }
    table.insert(cmd, "--jvm-arg=-Dfile.encoding=UTF-8")
    table.insert(cmd, "--jvm-arg=-Dorg.gradle.daemon.idletimeout=" .. GRADLE_DAEMON_IDLE_TIMEOUT_MS)

    local lombok_jar = get_lombok_jar()
    if lombok_jar then
        table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
    end

    return cmd
end

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
            configuration = {
                updateBuildConfiguration = "interactive",
                import = {
                    gradle = { enabled = true, wrapper = { enabled = true } },
                    maven = { enabled = true },
                },
            },
        },
    }
end

local function java_root_dir()
    -- multi-module Gradle project 에서는 jdtls 를 settings root 에 붙인다.
    -- 가장 가까운 submodule build.gradle 에 붙이면 정상적인 src/test/java 파일이
    -- imported classpath model 밖으로 밀릴 수 있다.
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

local function java_debug_bundles()
    local bundles = require("plugins.core.debugger").java_bundles()
    if vim.tbl_isempty(bundles) then
        vim.notify("Java DAP bundles not found: install vscode-java-debug and vscode-java-test", vim.log.levels.WARN)
    end
    return bundles
end

local function setup_java_dap()
    local jdtls = require("jdtls")
    local jdtls_dap = require("jdtls.dap")
    jdtls.setup_dap({ hotcodereplace = "auto" })
    jdtls_dap.setup_dap_main_class_configs()
end

local function setup_jdtls()
    local root_dir = java_root_dir()
    local jdtls = require("jdtls")

    jdtls.start_or_attach({
        cmd = java_cmd(root_dir),
        root_dir = root_dir,
        capabilities = require("plugins.core.lsp").get_capabilities(),
        on_attach = function(client, bufnr)
            if update_stale_test_classpath then
                update_stale_test_classpath(client, bufnr)
            end
            vim.schedule(setup_java_dap)
        end,
        -- jdtls 는 UTF-16 offset 을 기대한다.
        -- incremental sync 에서 stale range 가 생겨 full sync 를 선택한다.
        offset_encoding = "utf-16",
        flags = {
            debounce_text_changes = JDTLS_DEBOUNCE_TEXT_CHANGES_MS,
            allow_incremental_sync = false,
        },
        init_options = {
            extendedClientCapabilities = jdtls.extendedClientCapabilities,
            bundles = java_debug_bundles(),
        },
        settings = java_settings(),
    })
end

local function project_root_for(path)
    local marker = vim.fs.find(project_markers, {
        path = vim.fs.dirname(path),
        upward = true,
        limit = 1,
    })[1]
    return marker and vim.fs.dirname(marker) or nil
end

local function client_owns_path(client, path)
    local root = client.config and client.config.root_dir
    if not root then
        return false
    end
    root = vim.fs.normalize(root)
    path = vim.fs.normalize(path)
    return path == root or path:sub(1, #root + 1) == root .. "/"
end

local function is_gradle_test_java(path)
    return path:match("/src/test/java/.*%.java$") ~= nil
end

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

local function request_project_configuration_update(client, bufnr, uri)
    client:request("java/projectConfigurationUpdate", { uri = uri }, function(err)
        if err then
            vim.notify(vim.inspect(err), vim.log.levels.WARN)
        end
    end, bufnr)
end

update_stale_test_classpath = function(client, bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if not is_gradle_test_java(path) or classpath_includes_test_java(path) then
        return
    end

    request_project_configuration_update(client, bufnr, vim.uri_from_bufnr(bufnr))
end

local function setup_jdtls_manual_sync()
    -- jdtls 가 새 .java 파일을 놓치는 file-watcher race 에 대비.
    -- 저장 시점에 didChangeWatchedFiles 노티를 보내 인덱싱을 강제.
    -- 새 test source 는 Buildship .classpath 가 stale 할 수 있어 제한적으로
    -- projectConfigurationUpdate 도 보낸다.
    -- build.gradle / pom.xml 변경은 projectConfigurationUpdate 로 reimport.
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
            local path = vim.api.nvim_buf_get_name(args.buf)
            local uri = vim.uri_from_bufnr(args.buf)
            local change_type = java_file_was_created[path] and 1 or 2 -- 1=Created 2=Changed 3=Deleted
            java_file_was_created[path] = nil
            for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
                if client_owns_path(client, path) then
                    client:notify("workspace/didChangeWatchedFiles", {
                        changes = { { uri = uri, type = change_type } },
                    })
                    if change_type == 1 and is_gradle_test_java(path) then
                        request_project_configuration_update(client, args.buf, uri)
                    end
                end
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
    -- Java parser 를 treesitter 공통 설치 목록에 추가한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "java" })
        end,
    },
    -- Java formatter 는 별도 clang-format-java alias 로 conform 에 연결한다.
    -- 공통 C/C++ clang-format 설정과 Java style 을 분리하기 위한 항목이다.
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.java = { "clang-format-java" }
        end,
    },
    -- Java attach debug configuration 을 공통 nvim-dap setup 에 주입한다.
    -- Spring Boot 원격 JVM debug port 를 입력받아 붙는 흐름이다.
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
    -- jdtls lifecycle, workspace, debug bundle 설정은 Java 전용 spec 으로 분리한다.
    -- FileType 시점에 start_or_attach 하고 Gradle classpath refresh 도 여기서 묶는다.
    {
        "mfussenegger/nvim-jdtls",
        dependencies = { "mfussenegger/nvim-dap" },
        ft = { "java" },
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
