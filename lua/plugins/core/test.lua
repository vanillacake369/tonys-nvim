-- NOTE: Neotest 가 테스트별 gutter sign, 진단, summary, DAP 실행을 소유한다.
-- Java, Go, Python, Rust adapter 를 함께 등록해서 어떤 언어 버퍼가 먼저
-- 로드되어도 테스트 keymap 동작이 달라지지 않게 한다.
--
-- COMPAT: Nix host 에서는 tonys-nix 가 home.file symlink 로 제공하는 JUnit
-- Platform Console Standalone JAR 를 neotest-java 가 사용한다.

local M = {}

-- NOTE: 테스트 terminal 은 public test keymap, Gradle runner, DAP handoff,
-- alternate-file helper 가 하나의 vertical slice 로 수렴하도록 이 파일 안에 둔다.
-- 다른 호출자가 안정적인 module 경계를 요구하기 전까지는 plain function 으로 둔다.

local terminal = {}

local terminals = {}
local watch_terminal

local function bottom(buf)
    vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
            return
        end
        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_call(win, function()
                    vim.cmd("normal! G")
                end)
            end
        end
    end)
end

local function forget(term)
    terminals[term] = nil
    if watch_terminal == term then
        watch_terminal = nil
    end
end

local function track(term, opts)
    opts = opts or {}
    if not (term and term.buf and vim.api.nvim_buf_is_valid(term.buf)) then
        return term
    end

    terminals[term] = true
    bottom(term.buf)
    vim.api.nvim_create_autocmd("TermClose", {
        buffer = term.buf,
        once = true,
        callback = function()
            local status = tonumber(vim.v.event.status) or 0
            bottom(term.buf)
            forget(term)
            if opts.init_script then
                pcall(vim.fn.delete, opts.init_script)
            end
            if opts.notify_result then
                local level = status == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
                vim.notify(status == 0 and "Java tests passed" or ("Java tests failed: exit " .. status), level)
            end
        end,
    })
    return term
end

local function close(term)
    if not (term and term.buf and vim.api.nvim_buf_is_valid(term.buf)) then
        return
    end

    local job = vim.b[term.buf].terminal_job_id
    if job then
        pcall(vim.fn.jobstop, job)
    end
    if term.close then
        pcall(function()
            term:close()
        end)
        return
    end
    vim.api.nvim_buf_delete(term.buf, { force = true })
end

function terminal.stop()
    local stopped = false
    for term in pairs(terminals) do
        stopped = true
        close(term)
        terminals[term] = nil
    end
    watch_terminal = nil
    return stopped
end

function terminal.run(cmd, cwd, opts)
    opts = opts or {}
    if _G.Snacks and Snacks.terminal then
        return track(
            Snacks.terminal.open(cmd, {
                cwd = cwd,
                interactive = false,
                win = {
                    position = "bottom",
                    height = 0.45,
                },
            }),
            opts
        )
    end

    vim.cmd("botright split")
    vim.fn.termopen(cmd, { cwd = cwd })
    return track({ buf = vim.api.nvim_get_current_buf() }, opts)
end

function terminal.toggle_watch(cmd, cwd, opts)
    if watch_terminal and watch_terminal.buf and vim.api.nvim_buf_is_valid(watch_terminal.buf) then
        close(watch_terminal)
        forget(watch_terminal)
        vim.notify("Java test watch stopped", vim.log.levels.INFO)
        return
    end

    watch_terminal = terminal.run(cmd, cwd, opts)
end

-- NOTE: JVM Gradle runner 는 project discovery, test discovery, command argv
-- 구성, terminal 실행, watch mode, debug attach 를 소유한다. 테스트는 별도 DSL
-- 대신 같은 risk 축으로 이 section 들을 검증한다.

local jvm_gradle = {}

local function get_gradle_root_from(filename)
    return vim.fs.root(
        filename,
        { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "gradlew" }
    )
end

local function get_gradle_settings_root_from(filename)
    return vim.fs.root(filename, { "settings.gradle", "settings.gradle.kts", "gradlew" })
        or get_gradle_root_from(filename)
end

local function find_build_root_from(filename, stop_dir)
    local dir = vim.fn.fnamemodify(filename, ":p:h")
    while dir and dir ~= "" do
        if vim.fn.filereadable(dir .. "/build.gradle") == 1 or vim.fn.filereadable(dir .. "/build.gradle.kts") == 1 then
            return dir
        end
        if dir == stop_dir then
            return stop_dir
        end
        local parent = vim.fs.dirname(dir)
        if parent == dir then
            return stop_dir
        end
        dir = parent
    end
    return stop_dir
end

local function gradle_test_task(root, module_dir)
    if module_dir == root then
        return "test"
    end
    local rel = module_dir:sub(#root + 2)
    return ":" .. rel:gsub("/", ":") .. ":test"
end

local function gradle_clean_test_task(test_task)
    return test_task == "test" and "cleanTest" or test_task:gsub(":test$", ":cleanTest")
end

local function gradle_cmd(root, ...)
    local cmd = (vim.fn.filereadable(root .. "/gradlew") == 1) and { "./gradlew" } or { "gradle" }
    vim.list_extend(cmd, { ... })
    return cmd
end

local function gradle_project_probe_script()
    local path = vim.fn.tempname() .. ".gradle"
    vim.fn.writefile({
        "gradle.projectsEvaluated {",
        "    allprojects { project ->",
        "        if (project.tasks.findByName('test') != null) {",
        '            println("__NVIM_GRADLE_PROJECT__\t${project.path}\t${project.projectDir.absolutePath}")',
        "            def sourceSets = project.extensions.findByName('sourceSets')",
        "            def testSourceSet = sourceSets?.findByName('test')",
        "            testSourceSet?.allSource?.srcDirs?.each { dir ->",
        "                if (dir.exists()) {",
        '                    println("__NVIM_GRADLE_TEST_SOURCE__\t${project.path}\t${dir.absolutePath}")',
        "                }",
        "            }",
        "        }",
        "    }",
        "}",
    }, path)
    return path
end

local gradle_project_cache = {}
local cache_invalidation_started = false

local function clear_gradle_project_cache()
    gradle_project_cache = {}
end

local function setup_cache_invalidation()
    if cache_invalidation_started then
        return
    end
    cache_invalidation_started = true

    vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = {
            "settings.gradle",
            "settings.gradle.kts",
            "build.gradle",
            "build.gradle.kts",
            "gradle.properties",
        },
        callback = clear_gradle_project_cache,
    })
end

local function normalize_path(path)
    local normalized = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
    return vim.fs.normalize(normalized)
end

local function path_is_inside(parent, child)
    parent = normalize_path(parent)
    child = normalize_path(child)
    return child == parent or vim.startswith(child, parent .. "/")
end

local function gradle_test_projects(root)
    if gradle_project_cache[root] ~= nil then
        return gradle_project_cache[root]
    end

    local script = gradle_project_probe_script()
    local lines = vim.fn.systemlist(gradle_cmd(root, "-q", "--init-script", script, "help", "--console=plain"))
    local shell_error = vim.v.shell_error
    pcall(vim.fn.delete, script)

    if shell_error ~= 0 then
        gradle_project_cache[root] = false
        return nil
    end

    local projects = {}
    local project_by_path = {}
    for _, line in ipairs(lines) do
        local parts = vim.split(line, "\t", { plain = true })
        if parts[1] == "__NVIM_GRADLE_PROJECT__" and parts[2] and parts[3] then
            local project_path = parts[2]
            local project_dir = parts[3]
            local project = {
                dir = normalize_path(project_dir),
                task = project_path == ":" and "test" or (project_path .. ":test"),
                source_dirs = {},
            }
            project_by_path[project_path] = project
            table.insert(projects, project)
        elseif parts[1] == "__NVIM_GRADLE_TEST_SOURCE__" and parts[2] and parts[3] then
            local project = project_by_path[parts[2]]
            if project then
                table.insert(project.source_dirs, normalize_path(parts[3]))
            end
        end
    end
    table.sort(projects, function(left, right)
        return #left.dir > #right.dir
    end)

    gradle_project_cache[root] = projects
    return projects
end

local function gradle_project_for_file(root, file)
    local projects = gradle_test_projects(root) or {}
    for _, project in ipairs(projects) do
        for _, source_dir in ipairs(project.source_dirs or {}) do
            if path_is_inside(source_dir, file) then
                return project
            end
        end
    end

    for _, project in ipairs(projects) do
        if path_is_inside(project.dir, file) then
            return project
        end
    end

    local module_dir = find_build_root_from(file, root)
    return {
        dir = module_dir,
        task = gradle_test_task(root, module_dir),
    }
end

local function get_jvm_package(file)
    for _, line in ipairs(vim.fn.readfile(file)) do
        local pkg = line:match("^%s*package%s+([%w_%.]+)%s*;?%s*$")
        if pkg then
            return pkg
        end
    end
    return nil
end

local function get_jvm_class(file)
    local pkg = get_jvm_package(file)
    local class = vim.fn.fnamemodify(file, ":t:r")
    return pkg and (pkg .. "." .. class) or class
end

local function gradle_test_init_script()
    local path = vim.fn.tempname() .. ".gradle"
    vim.fn.writefile({
        "allprojects {",
        "    tasks.withType(org.gradle.api.tasks.testing.Test).configureEach {",
        "        testLogging {",
        '            events "passed", "failed", "skipped", "standardOut", "standardError"',
        "            showStandardStreams = true",
        '            exceptionFormat = "full"',
        "            showExceptions = true",
        "            showCauses = true",
        "            showStackTraces = true",
        "        }",
        "    }",
        "}",
    }, path)
    return path
end

local java_non_methods = {
    ["if"] = true,
    ["for"] = true,
    ["while"] = true,
    ["switch"] = true,
    ["catch"] = true,
    ["try"] = true,
    synchronized = true,
}

local java_test_annotations = {
    Test = true,
    ParameterizedTest = true,
    RepeatedTest = true,
    TestFactory = true,
    TestTemplate = true,
}

local function jvm_test_annotation(line)
    local annotation = line:match("^%s*@([%w_%.]+)")
    return annotation and java_test_annotations[annotation:match("([%w_]+)$")] == true
end

local function kotlin_class_name(line)
    return line:match("^%s*[%w_%s]*class%s+([%w_]+)")
end

local function kotlin_method_name(line)
    return line:match("^%s*[%w_%s]*fun%s+`([^`]+)`%s*%(") or line:match("^%s*[%w_%s]*fun%s+([%w_]+)%s*%(")
end

local function annotated_kotlin_method_name(line)
    if not jvm_test_annotation(line) then
        return nil
    end
    local rest = line:match("^%s*@[%w_%.]+%b()%s*(.*)$") or line:match("^%s*@[%w_%.]+%s+(.*)$")
    return rest and kotlin_method_name(rest) or nil
end

local function is_jvm_filetype()
    return vim.bo.filetype == "java" or vim.bo.filetype == "kotlin"
end

local function has_java_test_annotation(row)
    for prev = row - 1, 1, -1 do
        local line = vim.api.nvim_buf_get_lines(0, prev - 1, prev, false)[1] or ""
        local annotation = line:match("^%s*@([%w_%.]+)")
        if annotation then
            if jvm_test_annotation(line) then
                return true
            end
        elseif not line:match("^%s*$") then
            return false
        end
    end
    return false
end

local java_discovery_adapter

local function get_java_discovery_adapter()
    if not java_discovery_adapter then
        java_discovery_adapter = require("neotest-java")({ disable_update_notifications = true })
    end
    return java_discovery_adapter
end

local function display_path(root, file)
    return path_is_inside(root, file) and file:sub(#normalize_path(root) + 2) or file
end

local function java_test_files(root)
    local files = {}
    local seen = {}
    for _, project in ipairs(gradle_test_projects(root) or {}) do
        for _, source_dir in ipairs(project.source_dirs or {}) do
            for _, pattern in ipairs({ "/**/*.java", "/**/*.kt" }) do
                for _, file in ipairs(vim.fn.glob(source_dir .. pattern, false, true)) do
                    if not seen[file] then
                        seen[file] = true
                        table.insert(files, file)
                    end
                end
            end
        end
    end
    if #files == 0 then
        files = vim.fn.glob(root .. "/**/src/test/java/**/*.java", false, true)
        vim.list_extend(files, vim.fn.glob(root .. "/**/src/test/kotlin/**/*.kt", false, true))
    end
    table.sort(files)
    return files
end

local function java_file_metadata(root, files)
    local metadata = {}
    for _, file in ipairs(files) do
        local project = gradle_project_for_file(root, file)
        metadata[file] = {
            package = get_jvm_package(file),
            display_path = display_path(root, file),
            task = project.task,
            module_dir = project.dir,
        }
    end
    return metadata
end

local function item_from_neotest_node(metadata, node)
    local pos = node:data()
    if pos.type ~= "test" then
        return nil
    end

    local namespace = node:parent() and node:parent():data()
    if not (namespace and namespace.name) then
        return nil
    end

    local meta = metadata[pos.path]
    if not meta then
        return nil
    end

    local pkg = meta.package
    local fqcn = pkg and (pkg .. "." .. namespace.name) or namespace.name
    local line = pos.range and pos.range[1] and (pos.range[1] + 1) or 1

    return {
        text = string.format("%s  %s.%s  %s:%d", meta.task, fqcn, pos.name, meta.display_path, line),
        file = pos.path,
        line = line,
        fqcn = fqcn,
        method = pos.name,
        filter = fqcn .. "." .. pos.name,
        module_dir = meta.module_dir,
        task = meta.task,
    }
end

local function discover_java_tests(_, files, metadata)
    local items = {}
    local adapter = get_java_discovery_adapter()
    for _, file in ipairs(files) do
        if not file:match("%.kt$") then
            local ok, tree = pcall(adapter.discover_positions, file)
            if ok and tree then
                for _, node in tree:iter_nodes() do
                    local item = item_from_neotest_node(metadata, node)
                    if item then
                        table.insert(items, item)
                    end
                end
            end
        end
    end
    return items
end

local function kotlin_test_item(file, line_number, class_name, method, meta)
    local pkg = meta.package or get_jvm_package(file)
    local fqcn = pkg and (pkg .. "." .. class_name) or class_name
    return {
        text = string.format("%s  %s.%s  %s:%d", meta.task, fqcn, method, meta.display_path, line_number),
        file = file,
        line = line_number,
        fqcn = fqcn,
        method = method,
        filter = fqcn .. "." .. method,
        module_dir = meta.module_dir,
        task = meta.task,
    }
end

local function discover_kotlin_tests(files, metadata)
    local items = {}
    for _, file in ipairs(files) do
        if file:match("%.kt$") then
            local meta = metadata[file]
            local class_name
            local has_test_annotation = false
            for line_number, line in ipairs(vim.fn.readfile(file)) do
                local declared_class = kotlin_class_name(line)
                if declared_class then
                    class_name = declared_class
                end

                local annotation = line:match("^%s*@([%w_%.]+)")
                if annotation then
                    has_test_annotation = jvm_test_annotation(line)
                    local method = annotated_kotlin_method_name(line)
                    if method and class_name and meta then
                        table.insert(items, kotlin_test_item(file, line_number, class_name, method, meta))
                        has_test_annotation = false
                    end
                else
                    local method = kotlin_method_name(line)
                    if method and has_test_annotation and class_name and meta then
                        table.insert(items, kotlin_test_item(file, line_number, class_name, method, meta))
                    end
                    if method or not line:match("^%s*$") then
                        has_test_annotation = false
                    end
                end
            end
        end
    end
    return items
end

local function discover_jvm_tests(root, files, metadata)
    local items = discover_java_tests(root, files, metadata)
    vim.list_extend(items, discover_kotlin_tests(files, metadata))
    table.sort(items, function(left, right)
        if left.file == right.file then
            return left.line < right.line
        end
        return left.file < right.file
    end)
    return items
end

local function kotlin_test_method_at_line(line, row)
    local inline_test = annotated_kotlin_method_name(line)
    if inline_test then
        return inline_test
    end

    local name = kotlin_method_name(line)
    if name and has_java_test_annotation(row) then
        return name
    end
    return name and false or nil
end

local function java_test_method_at_line(line, row)
    local signature = line:match("^(.-)%s*{%s*$")
    local before_params = signature and signature:match("^(.-)%s*%(")
    local name = before_params and before_params:match("([^%s]+)$")
    if not (before_params and name) then
        return nil
    end
    if java_non_methods[name] or name:find(".", 1, true) then
        return nil
    end
    return has_java_test_annotation(row) and name or false
end

local function get_jvm_method_at_cursor()
    local filetype = vim.bo.filetype
    for row = vim.api.nvim_win_get_cursor(0)[1], 1, -1 do
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
        local method = filetype == "kotlin" and kotlin_test_method_at_line(line, row)
            or java_test_method_at_line(line, row)
        if method ~= nil then
            return method
        end
    end
    return nil
end

local function java_gradle_filters(file, opts)
    local fqcn = get_jvm_class(file)
    if opts.filters then
        local filters = {}
        for _, method in ipairs(opts.filters) do
            table.insert(filters, fqcn .. "." .. method)
        end
        return filters
    end

    local method = opts.nearest and get_jvm_method_at_cursor() or nil
    return { method and (fqcn .. "." .. method) or fqcn }
end

local function grouped_java_items(items)
    local groups = {}
    local order = {}
    for _, item in ipairs(items) do
        if not groups[item.task] then
            groups[item.task] = {}
            table.insert(order, item.task)
        end
        table.insert(groups[item.task], item)
    end
    table.sort(order)
    return groups, order
end

local function append_gradle_flags(cmd, opts)
    opts = opts or {}
    if opts.rerun then
        table.insert(cmd, "--rerun-tasks")
    end
    if opts.verbose then
        table.insert(cmd, "--info")
    end
    if opts.debug then
        table.insert(cmd, "--debug-jvm")
    end
    if opts.watch then
        table.insert(cmd, "--continuous")
    end
    table.insert(cmd, "--console=plain")
end

local function build_gradle_test_commands(opts)
    opts = opts or {}
    local file = opts.file or vim.api.nvim_buf_get_name(0)
    local root = opts.root or get_gradle_settings_root_from(vim.fn.fnamemodify(file, ":h"))
    if not root then
        return nil
    end

    local init_script = opts.init_script or gradle_test_init_script()
    local commands = {}
    if opts.items then
        local groups, order = grouped_java_items(opts.items)
        for _, task in ipairs(order) do
            local cmd = gradle_cmd(root, "--init-script", init_script, task)
            for _, item in ipairs(groups[task]) do
                vim.list_extend(cmd, { "--tests", item.filter })
            end
            append_gradle_flags(cmd, vim.tbl_extend("force", opts, { rerun = true }))
            table.insert(commands, cmd)
        end
    else
        local test_task = gradle_project_for_file(root, file).task
        local cmd = gradle_cmd(root, "--init-script", init_script)
        vim.list_extend(cmd, { gradle_clean_test_task(test_task), test_task })
        for _, filter in ipairs(java_gradle_filters(file, opts)) do
            vim.list_extend(cmd, { "--tests", filter })
        end
        append_gradle_flags(cmd, opts)
        table.insert(commands, cmd)
    end

    return commands, root, init_script
end

local function build_gradle_debug_commands(opts)
    opts = vim.tbl_extend("force", opts or {}, { debug = true })
    local commands, root, init_script = build_gradle_test_commands(opts)
    if not commands then
        return nil
    end

    return commands, root, init_script
end

local function shell_command(cmd)
    local parts = {}
    for _, part in ipairs(cmd) do
        table.insert(parts, vim.fn.shellescape(part))
    end
    return table.concat(parts, " ")
end

local function combined_command(commands)
    if #commands == 1 then
        return commands[1]
    end

    local shell_commands = {}
    for _, cmd in ipairs(commands) do
        table.insert(shell_commands, shell_command(cmd))
    end
    return { "sh", "-lc", table.concat(shell_commands, " && ") }
end

local function run_java_gradle_test(opts)
    opts = opts or {}
    if not opts.items and vim.bo.modified then
        vim.cmd("write")
    end

    local commands, root, init_script = build_gradle_test_commands(opts)
    if not commands then
        require("neotest").run.run()
        return
    end

    local cmd = combined_command(commands)
    if opts.watch then
        terminal.toggle_watch(cmd, root, { init_script = init_script })
        return
    end
    terminal.run(cmd, root, { init_script = init_script, notify_result = true })
end

local function attach_debugger()
    vim.defer_fn(function()
        require("dap").run({
            type = "java",
            request = "attach",
            name = "Debug Gradle Test",
            hostName = "127.0.0.1",
            port = 5005,
        })
    end, 800)
end

local function run_java_gradle_debug_test(opts)
    opts = opts or {}
    if opts.items and #opts.items ~= 1 then
        vim.notify("Debug one JVM test at a time", vim.log.levels.WARN)
        return
    end
    if not opts.items and vim.bo.modified then
        vim.cmd("write")
    end

    local commands, root, init_script = build_gradle_debug_commands(opts)
    if not commands then
        require("neotest").run.run({ strategy = "dap" })
        return
    end
    if #commands ~= 1 then
        vim.notify("Debug one JVM test task at a time", vim.log.levels.WARN)
        return
    end

    terminal.run(commands[1], root, { init_script = init_script })
    attach_debugger()
end

local function open_jvm_test_picker(root, methods)
    if #methods == 0 then
        vim.notify("No JVM tests found", vim.log.levels.INFO)
        return
    end

    if not (_G.Snacks and Snacks.picker) then
        vim.ui.select(methods, {
            prompt = "JVM test method",
            format_item = function(item)
                return item.method
            end,
        }, function(item)
            if item then
                run_java_gradle_test({ root = root, items = { item } })
            end
        end)
        return
    end

    Snacks.picker({
        title = "JVM Tests",
        items = methods,
        format = "text",
        matcher = { sort = false },
        confirm = function(picker, item)
            local selected = picker:selected({ fallback = true })
            picker:close()
            if #selected == 0 and item then
                selected = { item }
            end
            local items = {}
            for _, selected_item in ipairs(selected) do
                table.insert(items, selected_item)
            end
            if #items > 0 then
                run_java_gradle_test({ root = root, items = items })
            end
        end,
    })
end

function jvm_gradle.pick_java_tests()
    if not is_jvm_filetype() then
        require("neotest").run.run(vim.fn.expand("%"))
        return
    end

    local file = vim.api.nvim_buf_get_name(0)
    local root = get_gradle_settings_root_from(vim.fn.fnamemodify(file, ":h"))
    if not root then
        require("neotest").run.run(vim.fn.expand("%"))
        return
    end

    if vim.bo.modified then
        vim.cmd("write")
    end

    local files = java_test_files(root)
    local metadata = java_file_metadata(root, files)
    require("nio").run(function()
        local methods = discover_jvm_tests(root, files, metadata)
        vim.schedule(function()
            open_jvm_test_picker(root, methods)
        end)
    end)
end

jvm_gradle.pick_jvm_tests = jvm_gradle.pick_java_tests

function jvm_gradle.stop()
    if terminal.stop() then
        vim.notify("Java test process stopped", vim.log.levels.INFO)
        return
    end

    require("neotest").run.stop()
end

function jvm_gradle.debug_test()
    if not is_jvm_filetype() then
        require("neotest").run.run({ strategy = "dap" })
        return
    end

    run_java_gradle_debug_test({ nearest = true })
end

function jvm_gradle.run_nearest_verbose()
    if not is_jvm_filetype() then
        require("neotest").run.run()
        return
    end

    run_java_gradle_test({ nearest = true, verbose = true })
end

function jvm_gradle.run_nearest()
    if not is_jvm_filetype() then
        require("neotest").run.run()
        return
    end

    run_java_gradle_test({ nearest = true })
end

function jvm_gradle.run_file()
    if not is_jvm_filetype() then
        require("neotest").run.run(vim.fn.expand("%"))
        return
    end

    run_java_gradle_test()
end

function jvm_gradle.watch_file()
    if not is_jvm_filetype() then
        require("neotest").watch.toggle(vim.fn.expand("%"))
        return
    end

    run_java_gradle_test({ watch = true })
end

jvm_gradle._test = {
    build_gradle_test_commands = build_gradle_test_commands,
    build_gradle_debug_commands = build_gradle_debug_commands,
    combined_command = combined_command,
    clear_gradle_project_cache = clear_gradle_project_cache,
    discover_kotlin_tests = discover_kotlin_tests,
}

setup_cache_invalidation()

-- NOTE: Alternate-file template 은 재사용 project generator 가 아니라 같은 test
-- workflow keymap 표면에 속하므로 이 파일 안에 둔다.

local alternate_templates = {}

local function derive_java_package(filename)
    local rel = filename:match("/src/[^/]+/java/(.*)/[^/]+%.java$")
        or filename:match("/src/[^/]+/kotlin/(.*)/[^/]+%.kt$")
    return rel and rel:gsub("/", ".") or ""
end

local function derive_class_name(filename)
    return vim.fn.fnamemodify(filename, ":t:r")
end

local function go_package(filename)
    -- NOTE: 같은 디렉터리의 기존 Go package 선언이 있으면 그대로 재사용한다.
    local dir = vim.fn.fnamemodify(filename, ":h")
    for _, sibling in ipairs(vim.fn.glob(dir .. "/*.go", false, true)) do
        if sibling ~= filename then
            for _, line in ipairs(vim.fn.readfile(sibling, "", 20)) do
                local pkg = line:match("^package%s+([%w_]+)")
                if pkg then
                    return pkg
                end
            end
        end
    end
    return vim.fn.fnamemodify(dir, ":t")
end

local templates = {
    java = function(filename)
        local pkg = derive_java_package(filename)
        local class = derive_class_name(filename)
        return {
            "package " .. pkg .. ";",
            "",
            "import org.junit.jupiter.api.Test;",
            "import org.junit.jupiter.api.DisplayName;",
            "",
            "class " .. class .. " {",
            "",
            "    @Test",
            '    @DisplayName("테스트코드명")',
            "    void 테스트코드명() {",
            "        // GIVEN",
            "        // WHEN",
            "        // THEN",
            "    }",
            "}",
            "",
        }
    end,
    kt = function(filename)
        local pkg = derive_java_package(filename)
        local class = derive_class_name(filename)
        return {
            "package " .. pkg,
            "",
            "import org.junit.jupiter.api.Test",
            "import org.junit.jupiter.api.DisplayName",
            "",
            "class " .. class .. " {",
            "",
            "    @Test",
            '    @DisplayName("테스트코드명")',
            "    fun `테스트코드명`() {",
            "        // GIVEN",
            "        // WHEN",
            "        // THEN",
            "    }",
            "}",
            "",
        }
    end,
    go = function(filename)
        return {
            "package " .. go_package(filename),
            "",
            'import "testing"',
            "",
            "func Test테스트코드명(t *testing.T) {",
            '    t.Run("테스트코드명", func(t *testing.T) {',
            "        // GIVEN",
            "        // WHEN",
            "        // THEN",
            '        t.Fatal("Should be implemented")',
            "    })",
            "}",
            "",
        }
    end,
    py = function(_)
        return {
            "def test_테스트코드명() -> None:",
            '    """테스트코드명"""',
            "    # GIVEN",
            "    # WHEN",
            "    # THEN",
            '    raise NotImplementedError("Should be implemented")',
            "",
        }
    end,
}

function alternate_templates.write(filename)
    local ext = filename:match("%.([^.]+)$")
    local maker = templates[ext]
    if not maker then
        return
    end
    -- NOTE: other.nvim 은 새 파일의 상위 디렉터리를 만들지 않으므로 직접 보장한다.
    vim.fn.mkdir(vim.fn.fnamemodify(filename, ":h"), "p")
    -- NOTE: onOpenFile 은 :edit 보다 먼저 실행되므로 buffer 로드 이후로 지연한다.
    vim.schedule(function()
        local bufnr = vim.fn.bufnr(filename)
        if bufnr == -1 then
            return
        end
        if vim.api.nvim_buf_line_count(bufnr) > 1 then
            return -- NOTE: 이미 내용이 있는 buffer 는 건드리지 않는다.
        end
        local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
        if first and first ~= "" then
            return
        end
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, maker(filename))
    end)
end

-- NOTE: Rust project 는 unit test 를 대상 코드 옆에 두는 경우가 많으므로
-- alternate 는 inline `#[cfg(test)] mod tests` 로 이동한다.

local alternate_rust = {}

function alternate_rust.jump_to_test_block()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "rust")
    if not ok or not parser then
        vim.notify("rust treesitter parser not available", vim.log.levels.WARN)
        return
    end
    local tree = parser:parse()[1]
    if not tree then
        return
    end
    local query = vim.treesitter.query.parse(
        "rust",
        [[
        (mod_item
          name: (identifier) @name
          (#match? @name "^tests?$")
        ) @mod
        ]]
    )
    for id, node in query:iter_captures(tree:root(), bufnr) do
        if query.captures[id] == "mod" then
            local row, col = node:range()
            vim.api.nvim_win_set_cursor(0, { row + 1, col })
            return
        end
    end
    -- NOTE: tests module 이 없으면 파일 끝에 skeleton 을 추가하고 내부로 이동한다.
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local skeleton = {
        "",
        "#[cfg(test)]",
        "mod tests {",
        "    use super::*;",
        "",
        "    #[test]",
        "    fn 테스트코드명() {",
        "        // GIVEN",
        "        // WHEN",
        "        // THEN",
        '        unimplemented!("Should be implemented");',
        "    }",
        "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, skeleton)
    vim.api.nvim_win_set_cursor(0, { line_count + 3, 0 })
end

-- NOTE: keymap 과 debugger 호출이 같은 JVM/Rust/Neotest 동작으로 수렴하도록
-- public entry point 는 얇게 유지한다.

function M.pick_java_tests()
    jvm_gradle.pick_java_tests()
end

function M.pick_jvm_tests()
    jvm_gradle.pick_jvm_tests()
end

function M.stop()
    jvm_gradle.stop()
end

function M.run_nearest_verbose()
    jvm_gradle.run_nearest_verbose()
end

function M.run_nearest()
    jvm_gradle.run_nearest()
end

function M.run_file()
    jvm_gradle.run_file()
end

function M.watch_file()
    jvm_gradle.watch_file()
end

function M.debug_test()
    jvm_gradle.debug_test()
end

function M.jump_alternate()
    if vim.bo.filetype == "rust" then
        alternate_rust.jump_to_test_block()
        return
    end
    vim.cmd("Other")
end

function M.write_alternate_template(filename)
    alternate_templates.write(filename)
end

-- NOTE: load policy, adapter, keymap-facing test API 가 하나의 vertical slice 로
-- 남도록 Neotest plugin spec 도 이 파일에 둔다.

M._test = {
    gradle = jvm_gradle._test,
}

_G.__test_alternate = M

return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            -- COMPAT: neotest-java update 는 아래 Path:append patch 와 tonys-nix 의
            -- JUnit JAR pin 을 함께 확인해야 한다.
            "rcasia/neotest-java",
            "fredrikaverpil/neotest-golang",
            "nvim-neotest/neotest-python",
            -- NOTE: non-Rust buffer 가 먼저 열려도 Rust adapter 를 사용할 수 있도록
            -- neotest setup 전에 rustaceanvim 을 로드한다.
            "mrcjkb/rustaceanvim",
        },
        ft = { "java", "kotlin", "go", "python", "rust" },
        keys = function()
            return require("config.keymaps").bind("test")
        end,
        config = function()
            -- HACK: neotest-java v0.37.3 의 Path:append 는 `other` 를 string 으로
            -- 가정하지만 Gradle build dir resolution 은 다른 Path 를 넘길 수 있다.
            -- Spring test discovery 가 crash 나지 않도록 table arg 를 tostring 으로
            -- 강제 변환한다.
            --
            -- COMPAT: 2026-05-31 neotest-java HEAD 동작에 맞춘 patch 다.
            -- `:Lazy update neotest-java` 이후에는 다음을 실행한다.
            --   git -C ~/.local/share/nvim/lazy/neotest-java log --oneline \
            --       -- lua/neotest-java/model/path.lua \
            --       lua/neotest-java/build_tool/build_tool.lua
            -- 두 파일 중 하나라도 바뀌면 이 patch 를 끄고 Spring test 를 실행한다.
            -- upstream 이 Path table concatenation 을 처리하면 이 patch 를 삭제한다.
            do
                local ok, Path = pcall(require, "neotest-java.model.path")
                if ok and Path and Path.append then
                    local orig_append = Path.append
                    Path.append = function(self, other)
                        if type(other) == "table" then
                            other = tostring(other)
                        end
                        return orig_append(self, other)
                    end
                end
            end

            local adapters = {}
            local function add(name, factory)
                local ok, mod = pcall(require, name)
                if ok then
                    table.insert(adapters, factory and factory(mod) or mod)
                end
            end
            -- COMPAT: JAR version 은 Nix 로 pin 하고 tonys-nix 에서 review 하므로
            -- neotest-java 의 JUnit update popup 은 숨긴다.
            add("neotest-java", function(mod)
                return mod({ disable_update_notifications = true })
            end)
            add("neotest-golang", function(mod)
                return mod({})
            end)
            add("neotest-python", function(mod)
                return mod({ runner = "pytest" })
            end)
            -- NOTE: rustaceanvim 의 neotest module 은 factory 가 아니라 adapter table 이다.
            add("rustaceanvim.neotest")

            require("neotest").setup({
                adapters = adapters,
                quickfix = { open = false },
                output = { open_on_run = false },
                output_panel = { open = "botright 18split" },
                summary = {
                    open = "botright 50vsplit",
                    follow = true,
                    expand_errors = true,
                    count = true,
                },
                consumers = {
                    open_output_panel = function(client)
                        client.listeners.run = function()
                            vim.schedule(function()
                                require("neotest").output_panel.open()
                            end)
                        end
                        return {}
                    end,
                },
                icons = {
                    passed = "✓",
                    failed = "✗",
                    running = "",
                    skipped = "",
                    unknown = "?",
                },
                discovery = { enabled = true },
                diagnostic = { enabled = true },
                status = { enabled = true, signs = true, virtual_text = false },
            })
        end,
    },
}
