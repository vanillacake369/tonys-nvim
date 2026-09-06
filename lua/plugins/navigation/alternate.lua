-- NOTE: Source/test alternate navigation uses other.nvim pattern matching for
-- file-based languages, plus treesitter for Rust inline `mod tests`.
-- COMPAT: Java/Kotlin previously used `jdtls.tests.goto_subjects()`, but it
-- fails asynchronously without the `vscode-java-test` bundle installed.
-- NOTE: Newly-created test files get a skeleton via other.nvim's `onOpenFile`.

-- NOTE: other.nvim plugin spec.

return {
    {
        "rgroli/other.nvim",
        cmd = { "Other", "OtherSplit", "OtherVSplit", "OtherTabNew", "OtherClear" },
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
                -- NOTE: Drop nonsense matches like `foo_test_test.go` or
                -- `tests/test_test_foo.py` when src->test mappings fire on
                -- files already named as tests. Lua patterns can't express
                -- negative lookbehind, so post-filter here.
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
                -- NOTE: Fill freshly-created test files with a language-aware
                -- skeleton and let other.nvim still handle opening the file.
                onOpenFile = function(filename, exists)
                    if not exists then
                        _G.__test_alternate.write_alternate_template(filename)
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
