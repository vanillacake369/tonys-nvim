-- NOTE: Java 는 jdtls 전용 lifecycle 이 필요해 공통 lsp.lua 와 분리.
local project_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "pom.xml" }

local function get_lombok_jar()
    -- NOTE: Nix 환경에서는 `lombok` executable 이 wrapper 일 수 있다.
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
    -- NOTE: 같은 project name 이 여러 경로에 있어 hash 를 붙인다.
    -- jdtls workspace cache 충돌은 stale diagnostics/import state 로 이어진다.
    local project_name = vim.fn.fnamemodify(vim.fs.normalize(root_dir), ":t")
    return vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name .. "_" .. vim.fn.sha256(root_dir):sub(1, 8)
end

local function java_settings_url()
    -- NOTE: Eclipse JDT task tag diagnostics 는 todo-comments 와 충돌한다.
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
    -- NOTE: jdtls 는 JVM arg 를 CLI 로만 받는다.
    -- Gradle daemon idle timeout 과 Lombok javaagent 를 LSP lifecycle 에 묶는다.
    local cmd = { "jdtls", "-data", java_workspace_dir(root_dir) }
    table.insert(cmd, "--jvm-arg=-Dfile.encoding=UTF-8")
    table.insert(cmd, "--jvm-arg=-Dorg.gradle.daemon.idletimeout=300000")

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
                    starThreshold = 9999,
                    staticStarThreshold = 9999,
                    -- NOTE: Eclipse JDT 의 일반적인 그룹 순서.
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
    local root_markers = { "pom.xml", "build.gradle", "gradlew", ".git" }
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
        on_attach = function()
            vim.schedule(setup_java_dap)
        end,
        -- NOTE: jdtls 는 UTF-16 offset 을 기대한다.
        -- incremental sync 에서 stale range 가 생겨 full sync 를 선택한다.
        offset_encoding = "utf-16",
        flags = {
            debounce_text_changes = 150,
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

local function setup_jdtls_manual_sync()
    -- WARN: jdtls 가 새 .java 파일을 놓치는 file-watcher race 에 대비.
    -- 저장 시점에 didChangeWatchedFiles 노티를 보내 인덱싱을 강제.
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
                    -- NOTE: nil callback 은 실패를 조용히 삼킨다.
                    -- Gradle/Maven reimport 실패는 바로 notify 한다.
                    client:request("java/projectConfigurationUpdate", { uri = uri }, function(err)
                        if err then
                            vim.notify(vim.inspect(err), vim.log.levels.WARN)
                        end
                    end, args.buf)
                end
            end
        end,
    })
end

return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "java" })
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.java = { "clang-format-java" }
        end,
    },
    {
        "mfussenegger/nvim-dap",
        opts = function(_, opts)
            opts.setup = opts.setup or {}
            table.insert(opts.setup, function(dap)
                dap.configurations.java = {
                    {
                        type = "java",
                        request = "attach",
                        name = "Attach remote JVM",
                        hostName = "127.0.0.1",
                        port = 5005,
                    },
                }
            end)
        end,
    },
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
