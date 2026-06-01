-- Source ↔ Test file navigation (alternate file).
--
-- Strategy: other.nvim pattern matching for all file-based languages,
-- treesitter in-file jump for Rust (idiomatic inline `#[cfg(test)] mod tests`).
--
-- We previously dispatched to `jdtls.tests.goto_subjects()` for Java/Kotlin
-- (multi-module accuracy + auto-generate via vscode-java-test bundle), but it
-- needs the `vscode-java-test` JDTLS bundle installed — without it the LSP
-- command fails asynchronously *past* any pcall guard, leaving the user with
-- an opaque error. Until that bundle is wired in, one path is simpler and
-- always works. Add the dispatch back once the bundle ships.
--
-- Newly-created test files get a templated skeleton via other.nvim's
-- `onOpenFile` hook (the plugin itself has no `template` field).
--
-- Keymap (single): <leader>ta — Jump to alternate (or surface picker with a
-- `(new)` entry when missing; selecting it creates the file with template).

local M = {}

-- ─────────────────────────────────────────────────────────────────────────
-- Path helpers (compute Java package + class name from src/test path).
-- ─────────────────────────────────────────────────────────────────────────

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

-- ─────────────────────────────────────────────────────────────────────────
-- Template content for newly-created test files.
-- ─────────────────────────────────────────────────────────────────────────

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

local function write_template(filename)
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

-- ─────────────────────────────────────────────────────────────────────────
-- Rust: in-file jump to `#[cfg(test)] mod tests` block.
-- ─────────────────────────────────────────────────────────────────────────

local function rust_jump_to_test_block()
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

-- ─────────────────────────────────────────────────────────────────────────
-- Dispatch entry points (called from keymaps.lua).
-- ─────────────────────────────────────────────────────────────────────────

function M.jump()
    if vim.bo.filetype == "rust" then
        rust_jump_to_test_block()
        return
    end
    vim.cmd("Other")
end

-- ─────────────────────────────────────────────────────────────────────────
-- other.nvim plugin spec.
-- ─────────────────────────────────────────────────────────────────────────

return {
    {
        "rgroli/other.nvim",
        cmd = { "Other", "OtherSplit", "OtherVSplit", "OtherTabNew", "OtherClear" },
        -- Expose dispatcher to keymaps.lua via a global table (keymaps.lua
        -- loads at startup, before lazy resolves this plugin).
        init = function()
            _G.__alternate = M
        end,
        opts = {
            showMissingFiles = true,
            rememberBuffers = false,
            mappings = {
                -- Java: src/main/java ↔ src/test/java (Test suffix)
                {
                    pattern = "(.*)/src/main/java/(.*)%.java$",
                    target = "%1/src/test/java/%2Test.java",
                    context = "test",
                },
                {
                    pattern = "(.*)/src/test/java/(.*)Test%.java$",
                    target = "%1/src/main/java/%2.java",
                    context = "source",
                },
                -- Kotlin: same shape, .kt
                {
                    pattern = "(.*)/src/main/kotlin/(.*)%.kt$",
                    target = "%1/src/test/kotlin/%2Test.kt",
                    context = "test",
                },
                {
                    pattern = "(.*)/src/test/kotlin/(.*)Test%.kt$",
                    target = "%1/src/main/kotlin/%2.kt",
                    context = "source",
                },
                -- Go: sibling _test.go
                {
                    pattern = "(.*)/([^/]+)%.go$",
                    target = "%1/%2_test.go",
                    context = "test",
                },
                {
                    pattern = "(.*)/(.+)_test%.go$",
                    target = "%1/%2.go",
                    context = "source",
                },
                -- Python: pytest standard (tests/test_<name>.py)
                {
                    pattern = "(.*)/([^/]+)%.py$",
                    target = "%1/tests/test_%2.py",
                    context = "test",
                },
                {
                    pattern = "(.*)/tests/test_(.+)%.py$",
                    target = "%1/%2.py",
                    context = "source",
                },
            },
            hooks = {
                -- Drop nonsense matches like `foo_test_test.go` or
                -- `tests/test_test_foo.py` that arise when src→test mappings
                -- fire on files already named as tests. Lua patterns can't
                -- express negative lookbehind, so post-filter here.
                onFindOtherFiles = function(matches)
                    local current = vim.fn.expand("%:p")
                    return vim.tbl_filter(function(m)
                        if m.filename == current then
                            return false
                        end
                        if m.filename:match("_test_test%.go$") then
                            return false
                        end
                        if m.filename:match("/test_test_[^/]+%.py$") then
                            return false
                        end
                        if m.filename:match("/tests/test_[^/]+%.py$") and current:match("/tests/test_") then
                            return false
                        end
                        return true
                    end, matches)
                end,
                -- Fill freshly-created test files with a language-aware skeleton.
                -- Return true to let other.nvim still handle opening the file.
                onOpenFile = function(filename, exists)
                    if not exists then
                        write_template(filename)
                    end
                    return true
                end,
            },
            style = {
                border = "rounded",
                width = 0.5,
                height = 0.4,
                separator = "|",
                newFileIndicator = "(new)",
            },
        },
        config = function(_, opts)
            require("other-nvim").setup(opts)
        end,
    },
}
