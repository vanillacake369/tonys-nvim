-- source/test alternate 이동은 파일 기반 언어에서는 other.nvim pattern matching 을
-- 사용하고, Rust 는 treesitter 로 inline `mod tests` block 을 찾는다.
--
-- Java/Kotlin 은 예전에 `jdtls.tests.goto_subjects()` 를 썼지만
-- `vscode-java-test` bundle 이 없으면 pcall 밖에서 비동기 실패가 발생한다.
-- 새 test 파일은 other.nvim 의 `onOpenFile` hook 에서 skeleton 을 채운다.

local ALTERNATE_PICKER_WIDTH_RATIO = 0.5
local ALTERNATE_PICKER_HEIGHT_RATIO = 0.4

local function lua_source_to_spec(filename)
    local root, name = filename:match("^(.*)/lua/.*/([^/]+)%.lua$")
    if not root then
        return nil
    end
    return { root, name:gsub("%-", "_") }
end

return {
    -- source/test 파일 간 왕복과 새 test skeleton 생성을 위해 추가한다.
    -- 언어별 path 규칙은 mappings/hooks 에 모아 keymap 에서는 Other 명령만 호출한다.
    {
        "rgroli/other.nvim",
        cmd = { "Other", "OtherSplit", "OtherVSplit", "OtherTabNew", "OtherClear" },
        opts = {
            showMissingFiles = true,
            rememberBuffers = false,
            mappings = {
                -- Lua 는 repo-local plugin/config module 과 root tests/<name>_spec.lua 를 오간다.
                {
                    pattern = lua_source_to_spec,
                    target = "%1/tests/%2_spec.lua",
                    context = "test",
                },
                -- Java 는 src/main/java 와 src/test/java 의 Test suffix 파일을 오간다.
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
                -- Kotlin 은 Java 와 같은 src/main/src/test 구조를 .kt 확장자로 쓴다.
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
                -- Go 는 같은 디렉터리의 _test.go 파일을 쓴다.
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
                -- Python 은 pytest 관례인 tests/test_<name>.py 파일을 쓴다.
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
                -- 이미 test 이름인 파일에 src->test mapping 이 다시 적용되면
                -- `foo_test_test.go` 나 `tests/test_test_foo.py` 같은 후보가 생긴다.
                -- Lua pattern 은 negative lookbehind 를 표현할 수 없어서 여기서 후처리한다.
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
                -- 새로 만든 test 파일에는 언어별 skeleton 을 채우고,
                -- 실제 파일 열기는 other.nvim 흐름에 맡긴다.
                onOpenFile = function(filename, exists)
                    if not exists then
                        _G.__test_alternate.write_alternate_template(filename)
                    end
                    return true
                end,
            },
            style = {
                border = "rounded",
                width = ALTERNATE_PICKER_WIDTH_RATIO,
                height = ALTERNATE_PICKER_HEIGHT_RATIO,
                separator = "|",
                newFileIndicator = "(new)",
            },
        },
        config = function(_, opts)
            require("other-nvim").setup(opts)
        end,
    },
}
