-- NOTE: Neotest owns per-test gutter signs, diagnostics, summary, and DAP runs.
-- Java, Go, Python, and Rust adapters are registered together so test keymaps
-- do not depend on which language buffer loaded first.
--
-- COMPAT: neotest-java uses the JUnit Platform Console Standalone JAR provided
-- by tonys-nix via home.file symlink on Nix hosts.

local M = {}

-- Java Gradle test runner.

local function get_gradle_root_from(filename)
    return vim.fs.root(
        filename,
        { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "gradlew" }
    )
end

local function gradle_cmd(root, ...)
    local cmd = (vim.fn.filereadable(root .. "/gradlew") == 1) and { "./gradlew" } or { "gradle" }
    vim.list_extend(cmd, { ... })
    return cmd
end

local function get_java_package(file)
    for _, line in ipairs(vim.fn.readfile(file)) do
        local pkg = line:match("^%s*package%s+([%w_%.]+)%s*;")
        if pkg then
            return pkg
        end
    end
    return nil
end

local function get_java_class(file)
    local pkg = get_java_package(file)
    local class = vim.fn.fnamemodify(file, ":t:r")
    return pkg and (pkg .. "." .. class) or class
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

local function get_java_method_at_cursor()
    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    for row = cursor, 1, -1 do
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
        local signature = line:match("^(.-)%s*{%s*$")
        signature = signature and signature:gsub("%s+throws%s+.*$", "")
        local before_params = signature and signature:match("^(.-)%s*%(")
        local name = before_params and before_params:match("([^%s]+)$")
        if before_params and name and not java_non_methods[name] and not name:find(".", 1, true) then
            return name
        end
    end
    return nil
end

local function run_terminal(cmd, cwd)
    if _G.Snacks and Snacks.terminal then
        Snacks.terminal.open(cmd, {
            cwd = cwd,
            interactive = false,
            win = {
                position = "bottom",
                height = 0.45,
            },
        })
        return
    end

    vim.cmd("botright split")
    vim.fn.termopen(cmd, { cwd = cwd })
end

local function java_gradle_filter(file, nearest)
    local fqcn = get_java_class(file)
    local method = nearest and get_java_method_at_cursor() or nil
    return method and (fqcn .. "." .. method) or fqcn
end

local function run_java_gradle_test(opts)
    opts = opts or {}
    local file = vim.api.nvim_buf_get_name(0)
    local root = get_gradle_root_from(vim.fn.fnamemodify(file, ":h"))
    if not root then
        require("neotest").run.run()
        return
    end

    if vim.bo.modified then
        vim.cmd("write")
    end

    local cmd = gradle_cmd(root, "cleanTest", "test")
    vim.list_extend(cmd, { "--tests", java_gradle_filter(file, opts.nearest), "--info", "--console=plain" })
    if opts.watch then
        table.insert(cmd, "--continuous")
    end
    run_terminal(cmd, root)
end

function M.run_nearest()
    if vim.bo.filetype ~= "java" then
        require("neotest").run.run()
        return
    end

    run_java_gradle_test({ nearest = true })
end

function M.run_file()
    if vim.bo.filetype ~= "java" then
        require("neotest").run.run(vim.fn.expand("%"))
        return
    end

    run_java_gradle_test()
end

function M.watch_file()
    if vim.bo.filetype ~= "java" then
        require("neotest").watch.toggle(vim.fn.expand("%"))
        return
    end

    run_java_gradle_test({ watch = true })
end

-- Test alternate: source/test file creation templates.

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
    -- Reuse existing package decl from sibling .go files if present.
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
    -- Ensure parent dir exists (other.nvim doesn't mkdir -p for new files).
    vim.fn.mkdir(vim.fn.fnamemodify(filename, ":h"), "p")
    -- Defer until the buffer is loaded (onOpenFile fires *before* :edit).
    vim.schedule(function()
        local bufnr = vim.fn.bufnr(filename)
        if bufnr == -1 then
            return
        end
        if vim.api.nvim_buf_line_count(bufnr) > 1 then
            return -- already has content
        end
        local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
        if first and first ~= "" then
            return
        end
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, maker(filename))
    end)
end

-- Test alternate: Rust inline `#[cfg(test)] mod tests` support.

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
    -- No mod tests block; append a skeleton at end and jump cursor inside.
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

-- Test alternate: public entry points.

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

-- Neotest plugin spec.

_G.__test_alternate = M

return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            -- COMPAT: neotest-java upgrades must be checked with the Path:append
            -- patch below and the JUnit JAR pin in tonys-nix.
            "rcasia/neotest-java",
            "fredrikaverpil/neotest-golang",
            "nvim-neotest/neotest-python",
            -- NOTE: rustaceanvim must load before neotest setup so the Rust
            -- adapter is available even when a non-Rust buffer opens first.
            "mrcjkb/rustaceanvim",
        },
        ft = { "java", "go", "python", "rust" },
        keys = function()
            return require("config.keymaps").bind("test")
        end,
        config = function()
            -- HACK: neotest-java v0.37.3 Path:append assumes `other` is a
            -- string, but Gradle build dir resolution can pass another Path.
            -- Coerce table args through tostring to keep Spring test discovery
            -- from crashing.
            --
            -- COMPAT: pinned to neotest-java HEAD behavior on 2026-05-31. After
            -- `:Lazy update neotest-java`, run:
            --   git -C ~/.local/share/nvim/lazy/neotest-java log --oneline \
            --       -- lua/neotest-java/model/path.lua \
            --       lua/neotest-java/build_tool/build_tool.lua
            -- If either file changed, disable this patch and run a Spring test.
            -- Delete the patch when upstream handles Path table concatenation.
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
            -- COMPAT: suppress neotest-java JUnit update popups because the JAR
            -- version is pinned by Nix and reviewed in tonys-nix instead.
            add("neotest-java", function(mod)
                return mod({ disable_update_notifications = true })
            end)
            add("neotest-golang", function(mod)
                return mod({})
            end)
            add("neotest-python", function(mod)
                return mod({ runner = "pytest" })
            end)
            -- rustaceanvim's neotest module IS the adapter table (no factory call).
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
