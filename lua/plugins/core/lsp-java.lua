-- TODO :
-- vercel style 의 comment 를 달아줄 것 !!!
local project_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "pom.xml" }

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

local function java_workspace_dir(root_dir)
    local project_name = vim.fn.fnamemodify(vim.fs.normalize(root_dir), ":t")
    return vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name .. "_" .. vim.fn.sha256(root_dir):sub(1, 8)
end

local function java_cmd(root_dir)
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
                    -- Eclipse JDT 의 일반적인 그룹 순서.
                    -- Spring/Checkstyle 등 프로젝트별 규칙이 있으면
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

local function setup_jdtls()
    local root_dir = java_root_dir()
    local jdtls = require("jdtls")

    jdtls.start_or_attach({
        cmd = java_cmd(root_dir),
        root_dir = root_dir,
        capabilities = require("plugins.core.support.lsp").get_capabilities(),
        offset_encoding = "utf-16",
        flags = {
            debounce_text_changes = 150,
            allow_incremental_sync = false,
        },
        init_options = {
            extendedClientCapabilities = jdtls.extendedClientCapabilities,
            bundles = {},
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
    -- jdtls 가 새 .java 파일을 놓치는 케이스 (file-watcher race) 대비.
    -- 저장 시점에 didChangeWatchedFiles 노티를 직접 쏴 인덱싱을 강제.
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
                    client:request("java/projectConfigurationUpdate", { uri = uri }, nil, args.buf)
                end
            end
        end,
    })
end

return {
    "mfussenegger/nvim-jdtls",
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
}
