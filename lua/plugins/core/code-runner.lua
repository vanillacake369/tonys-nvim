-- Code Runner Configuration (Overseer)

-- 1. Helper Functions (Project & File detection)
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

-- Java & Gradle specific detection
local function get_gradle_root()
    return find_upward(
        { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "gradlew" },
        get_buf_dir()
    )
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

-- 3. Templates & Config
local function default_components()
    return {
        { "open_output", direction = "float", on_start = "always", focus = true },
        { "on_output_quickfix", set_diagnostics = true, open_on_match = true },
        "on_result_diagnostics",
        "default",
    }
end

local run_cmds = {
    go = { "go", "run" },
    python = { "python" },
    lua = { "lua" },
    sh = { "bash" },
    bash = { "bash" },
    javascript = { "node" },
    typescript = { "npx", "ts-node" },
    rust = { "cargo", "run" },
}

local function gradle_cmd(root, task)
    return (vim.fn.filereadable(root .. "/gradlew") == 1) and { "./gradlew", task } or { "gradle", task }
end

local templates = {
    {
        name = "Run Script",
        builder = function()
            local file, ft = get_buf_file(), vim.bo.filetype
            local cmd = run_cmds[ft] and vim.list_extend({ unpack(run_cmds[ft]) }, { file }) or { file }
            if ft == "c" then
                local out = vim.fn.expand("%:p:r")
                cmd = { "sh", "-c", string.format("gcc %s -o %s && %s", file, out, out) }
            end
            return { cmd = cmd, components = default_components() }
        end,
        condition = { filetype = vim.tbl_keys(run_cmds) },
    },
    {
        name = "Java: Compile & Run (Single File)",
        builder = function()
            local file = get_buf_file()
            local cp, main = get_java_classpath_root(file), get_java_main_class(file)
            return {
                cmd = { "sh", "-c", string.format("javac %s && java -cp %s %s", file, cp, main) },
                components = default_components(),
            }
        end,
        condition = {
            filetype = { "java" },
            callback = function()
                return not get_gradle_root()
            end,
        },
    },
    {
        name = "Gradle: Build",
        builder = function()
            local root = get_gradle_root()
            return { cmd = gradle_cmd(root, "build"), cwd = root, components = default_components() }
        end,
        condition = {
            filetype = { "java" },
            callback = function()
                return get_gradle_root() ~= nil
            end,
        },
        tags = { "BUILD" },
    },
    {
        name = "Spring Boot: Run",
        builder = function()
            local root = get_gradle_root()
            return { cmd = gradle_cmd(root, "bootRun"), cwd = root, components = default_components() }
        end,
        condition = {
            filetype = { "java" },
            callback = function()
                local root = get_gradle_root()
                return root and is_spring_project(root)
            end,
        },
    },
    {
        name = "Cargo: Test",
        builder = function()
            return { cmd = { "cargo", "test" }, components = default_components() }
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
        return require("config.keymaps").get_keys("runner")
    end,
    opts = {
        task_list = { direction = "bottom", min_height = 0.5, max_height = 0.5, default_detail = 1 },
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
            overseer.register_template(template)
        end
    end,
}
