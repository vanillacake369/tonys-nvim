-- Overseer 기반 code runner 설정

-- Project/file 탐지 helper
local TASK_LIST_HEIGHT_RATIO = 0.5
local TASK_LIST_DEFAULT_DETAIL = 1

local function get_buf_file()
    return vim.fn.expand("%:p")
end
local function get_buf_dir()
    return vim.fn.expand("%:p:h")
end

local function find_upward(names, start_path)
    local found = vim.fs.find(names, { path = start_path, upward = true, limit = 1 })[1]
    return found and vim.fs.dirname(found) or nil
end

local function read_file(path)
    if vim.fn.filereadable(path) == 0 then
        return ""
    end
    return table.concat(vim.fn.readfile(path), "\n")
end

-- Java/Gradle project 탐지
local function get_gradle_root_from(dir)
    return find_upward({ "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "gradlew" }, dir)
end

local function get_gradle_root()
    return get_gradle_root_from(get_buf_dir())
end

-- Rust/Cargo project 탐지
local function get_cargo_root_from(dir)
    return find_upward({ "Cargo.toml" }, dir)
end

local function get_cargo_root()
    return get_cargo_root_from(get_buf_dir())
end

local function require_executable(name)
    if vim.fn.executable(name) ~= 1 then
        error(name .. " not found on PATH; enter nix develop or install the tool for this project.")
    end
end

-- OverseerRun 을 호출한 Java test buffer 를 찾는다.
-- Snacks picker 는 builder 실행 전에 focus 를 옮기므로 현재 window/buffer 를 믿을 수 없다.
local function find_java_test_window()
    local function as_target(bufnr)
        if not bufnr or bufnr <= 0 then
            return nil
        end
        local name = vim.api.nvim_buf_get_name(bufnr)
        if not name:match("/src/test/java/.*%.java$") then
            return nil
        end
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == bufnr then
                return { bufnr = bufnr, win = win, file = name }
            end
        end
        return nil
    end
    return as_target(vim.api.nvim_get_current_buf())
        or as_target(vim.fn.bufnr("#"))
        or (function()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                local t = as_target(vim.api.nvim_win_get_buf(win))
                if t then
                    return t
                end
            end
            return nil
        end)()
end

local function is_spring_project(root)
    if not root then
        return false
    end
    local content = read_file(root .. "/build.gradle") .. "\n" .. read_file(root .. "/build.gradle.kts")
    return content:find("org.springframework.boot", 1, true) ~= nil or content:find("spring%-boot") ~= nil
end

local function get_java_package(file)
    if vim.fn.filereadable(file) == 0 then
        return nil
    end
    for _, line in ipairs(vim.fn.readfile(file)) do
        local pkg = line:match("^%s*package%s+([%w_%.]+)%s*;")
        if pkg then
            return pkg
        end
    end
    return nil
end

local function get_java_main_class(file)
    local class = vim.fn.fnamemodify(file, ":t:r")
    local pkg = get_java_package(file)
    return pkg and (pkg .. "." .. class) or class
end

local function get_java_classpath_root(file)
    local root = file:match("^(.*)/src/main/java/")
        or file:match("^(.*)/src/test/java/")
        or file:match("^(.*)/src/java/")
    return root or vim.fn.fnamemodify(file, ":h")
end

-- Template 과 실행 설정
local function default_components()
    return {
        { "open_output", direction = "float", on_start = "always", focus = true },
        { "on_output_quickfix", set_diagnostics = true, open_on_match = true },
        "on_result_diagnostics",
        "default",
    }
end

-- Gradle 실패 시 output 을 다시 열고 stack frame 을 quickfix 로 파싱한다.
-- expected/actual 상세 확인을 위해 HTML report 도 이어서 연다.
local OPENER = (vim.uv or vim.loop).os_uname().sysname == "Darwin" and "open" or "xdg-open"

local function gradle_test_components(root)
    return {
        {
            "open_output",
            direction = "float",
            on_start = "always",
            on_complete = "failure",
            focus = true,
        },
        {
            "on_output_quickfix",
            errorformat = "%.%#at %m(%f:%l),%-G%.%#",
            set_diagnostics = true,
            open_on_match = true,
            relative_file_root = root,
        },
        "on_result_diagnostics",
        "default",
    }
end

-- 실패 시 HTML report 를 열면서도 Gradle exit code 는 보존한다.
local function with_report_on_failure(root, cmd)
    local quoted = {}
    for _, a in ipairs(cmd) do
        table.insert(quoted, vim.fn.shellescape(a))
    end
    local report = root .. "/build/reports/tests/test/index.html"
    local script = string.format(
        "%s; rc=$?; if [ $rc -ne 0 ] && [ -f %s ]; then %s %s >/dev/null 2>&1 & fi; exit $rc",
        table.concat(quoted, " "),
        vim.fn.shellescape(report),
        OPENER,
        vim.fn.shellescape(report)
    )
    return { "sh", "-c", script }
end

local run_cmds = {
    c = { "cc" },
    go = { "go", "run" },
    python = { "python" },
    lua = { "lua" },
    sh = { "bash" },
    bash = { "bash" },
    javascript = { "node" },
    typescript = { "npx", "ts-node" },
    rust = { "cargo", "run" },
}

local function shell_join(cmd)
    local quoted = {}
    for _, arg in ipairs(cmd) do
        table.insert(quoted, vim.fn.shellescape(arg))
    end
    return table.concat(quoted, " ")
end

local function gradle_cmd(root, task)
    return (vim.fn.filereadable(root .. "/gradlew") == 1) and { "./gradlew", task } or { "gradle", task }
end

local templates = {
    {
        name = "Run Script",
        builder = function()
            local file, ft = get_buf_file(), vim.bo.filetype
            local cmd = run_cmds[ft] and vim.list_extend({ unpack(run_cmds[ft]) }, { file }) or { file }
            local cwd = nil
            if ft == "c" then
                -- 단일 C 실행은 임시 binary 를 trap 으로 정리한다.
                -- project build system 이 없는 scratch 파일용 빠른 경로다.
                local out = vim.fn.tempname() .. "-" .. vim.fn.fnamemodify(file, ":t:r")
                cmd = {
                    "sh",
                    "-c",
                    string.format(
                        "trap %s EXIT; cc %s -o %s && %s",
                        vim.fn.shellescape("rm -f " .. out),
                        vim.fn.shellescape(file),
                        vim.fn.shellescape(out),
                        vim.fn.shellescape(out)
                    ),
                }
            elseif ft == "rust" then
                local root = get_cargo_root()
                if root then
                    -- Cargo project 에서는 package entrypoint 를 실행.
                    -- 단일 파일 rustc 경로는 Cargo.toml 없을 때만 fallback.
                    cmd = { "cargo", "run" }
                    cwd = root
                else
                    local out = vim.fn.tempname() .. "-" .. vim.fn.fnamemodify(file, ":t:r")
                    cmd = {
                        "sh",
                        "-c",
                        string.format(
                            "trap %s EXIT; rustc %s -o %s && %s",
                            vim.fn.shellescape("rm -f " .. out),
                            vim.fn.shellescape(file),
                            vim.fn.shellescape(out),
                            vim.fn.shellescape(out)
                        ),
                    }
                end
            end
            return { cmd = cmd, cwd = cwd, components = default_components() }
        end,
        condition = { filetype = vim.tbl_keys(run_cmds) },
    },
    -- overseer.SearchCondition 은 `filetype` 과 `dir` 만 반영한다.
    -- condition.callback 은 무시되므로 방어 검사는 builder 안에 둔다.
    {
        name = "Java: Compile & Run (Single File)",
        builder = function()
            local file = get_buf_file()
            if get_gradle_root() then
                error("This project uses Gradle; use a Gradle template.")
            end
            local cp, main = get_java_classpath_root(file), get_java_main_class(file)
            return {
                cmd = { "sh", "-c", shell_join({ "javac", file }) .. " && " .. shell_join({ "java", "-cp", cp, main }) },
                components = default_components(),
            }
        end,
        condition = { filetype = { "java" } },
    },
    {
        name = "Gradle: Build",
        builder = function()
            local root = assert(get_gradle_root(), "no Gradle root for current buffer")
            return { cmd = gradle_cmd(root, "build"), cwd = root, components = default_components() }
        end,
        condition = { filetype = { "java" } },
        tags = { "BUILD" },
    },
    {
        name = "Spring Boot: Run",
        builder = function()
            local root = assert(get_gradle_root(), "no Gradle root for current buffer")
            if not is_spring_project(root) then
                error("Not a Spring Boot project (no spring-boot in build.gradle).")
            end
            return { cmd = gradle_cmd(root, "bootRun"), cwd = root, components = default_components() }
        end,
        condition = { filetype = { "java" } },
    },
    {
        name = "Gradle: Test",
        builder = function()
            local root = assert(get_gradle_root(), "no Gradle root for current buffer")
            return {
                cmd = with_report_on_failure(root, gradle_cmd(root, "test")),
                cwd = root,
                components = gradle_test_components(root),
            }
        end,
        condition = { filetype = { "java" } },
    },
    {
        name = "Gradle: Test (Current Class)",
        builder = function()
            local target = find_java_test_window() or error("open a file under src/test/java/ first")
            local root = assert(get_gradle_root_from(vim.fn.fnamemodify(target.file, ":h")), "no Gradle root")
            local fqcn = get_java_main_class(target.file)
            local raw = gradle_cmd(root, "test")
            vim.list_extend(raw, { "--tests", fqcn })
            return {
                cmd = with_report_on_failure(root, raw),
                cwd = root,
                components = gradle_test_components(root),
            }
        end,
        condition = { filetype = { "java" } },
    },
    -- method 단위 test 실행은 neotest-java 가 소유한다.
    -- Overseer 에는 cursor context, gutter sign, test별 status model 이 없다.
    {
        name = "Cargo: Run",
        builder = function()
            local root = assert(get_cargo_root(), "no Cargo.toml for current buffer")
            return { cmd = { "cargo", "run" }, cwd = root, components = default_components() }
        end,
        condition = { filetype = { "rust" } },
        tags = { "RUN" },
    },
    {
        name = "Cargo: Check",
        builder = function()
            local root = assert(get_cargo_root(), "no Cargo.toml for current buffer")
            return { cmd = { "cargo", "check" }, cwd = root, components = default_components() }
        end,
        condition = { filetype = { "rust" } },
    },
    {
        name = "Cargo: Clippy",
        builder = function()
            local root = assert(get_cargo_root(), "no Cargo.toml for current buffer")
            return { cmd = { "cargo", "clippy", "--", "-D", "warnings" }, cwd = root, components = default_components() }
        end,
        condition = { filetype = { "rust" } },
    },
    {
        name = "Cargo: Test",
        builder = function()
            local root = assert(get_cargo_root(), "no Cargo.toml for current buffer")
            return { cmd = { "cargo", "test" }, cwd = root, components = default_components() }
        end,
        condition = { filetype = { "rust" } },
    },
    {
        name = "Cargo: Nextest",
        builder = function()
            require_executable("cargo-nextest")
            local root = assert(get_cargo_root(), "no Cargo.toml for current buffer")
            return { cmd = { "cargo", "nextest", "run" }, cwd = root, components = default_components() }
        end,
        condition = { filetype = { "rust" } },
    },
    {
        name = "Cargo: Watch Check",
        builder = function()
            require_executable("cargo-watch")
            local root = assert(get_cargo_root(), "no Cargo.toml for current buffer")
            return { cmd = { "cargo", "watch", "-x", "check" }, cwd = root, components = default_components() }
        end,
        condition = { filetype = { "rust" } },
    },
    {
        name = "Bacon",
        builder = function()
            require_executable("bacon")
            local root = assert(get_cargo_root(), "no Cargo.toml for current buffer")
            return { cmd = { "bacon" }, cwd = root, components = default_components() }
        end,
        condition = { filetype = { "rust" } },
    },
    {
        name = "Go: Test",
        builder = function()
            return { cmd = { "go", "test", "-v", "./..." }, components = default_components() }
        end,
        condition = { filetype = { "go" } },
    },
    {
        name = "Nix: Build",
        builder = function()
            return { cmd = { "nix", "build" }, components = default_components() }
        end,
        condition = { filetype = { "nix" } },
        tags = { "BUILD" },
    },
}

return {
    -- Overseer 로 파일 실행, Gradle/Cargo/Go/Nix 작업을 task UI 에 모은다.
    -- 언어별 runner template 을 등록해 빌드/테스트 output 을 quickfix 와 연결한다.
    "stevearc/overseer.nvim",
    cmd = {
        "OverseerRun",
        "OverseerToggle",
        "OverseerBuild",
        "OverseerTaskAction",
        "OverseerQuickAction",
        "OverseerRestartLast",
    },
    keys = function()
        return require("config.keymaps").bind("runner")
    end,
    opts = {
        task_list = {
            direction = "bottom",
            min_height = TASK_LIST_HEIGHT_RATIO,
            max_height = TASK_LIST_HEIGHT_RATIO,
            default_detail = TASK_LIST_DEFAULT_DETAIL,
        },
        templates = { "builtin" },
    },
    config = function(_, opts)
        local overseer = require("overseer")
        overseer.setup(opts)
        local group = vim.api.nvim_create_augroup("OverseerOutputCloseKeymaps", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            pattern = "OverseerOutput",
            callback = function(args)
                -- Overseer output 은 float/terminal 양쪽에서 열린다.
                -- buffer-local q/Esc 로 같은 buffer 의 모든 window 를 닫는다.
                local close_output = function()
                    for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
                        if vim.api.nvim_win_is_valid(win) then
                            pcall(vim.api.nvim_win_close, win, true)
                        end
                    end
                end
                vim.keymap.set({ "n", "t" }, "q", close_output, { buffer = args.buf, nowait = true, silent = true })
                vim.keymap.set({ "n", "t" }, "<Esc>", close_output, { buffer = args.buf, nowait = true, silent = true })
            end,
        })
        for _, template in ipairs(templates) do
            -- 파일타입별 custom template 을 builtin template 옆에 등록한다.
            overseer.register_template(template)
        end
    end,
}
