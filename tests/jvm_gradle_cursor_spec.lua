local H = require("tests.helpers")
local assert_eq = H.assert_eq
local runner = H.gradle_runner()

-- NOTE: cursor test 는 normal run, verbose run, debug run 이 공유하는 nearest-test
-- filter 동작을 고정한다. cursor resolver 는 production slice 안에 의도적으로
-- 남겨두었으므로 command 구성 경로로 검증한다.

-- 준비
local root = H.temp_root()
local kotlin_file = root .. "/src/test/kotlin/com/acme/FooTest.kt"
H.write(kotlin_file, {
    "package com.acme",
    "",
    "internal class FooTest {",
    "    @Test",
    "    internal fun `does work`() {",
    "    }",
    "",
    "    @Test fun inlineAnnotation() {",
    "    }",
    "",
    "    fun helper() {",
    "    }",
    "}",
})
vim.cmd.edit(vim.fn.fnameescape(kotlin_file))
vim.bo.filetype = "kotlin"

-- 실행
vim.api.nvim_win_set_cursor(0, { 5, 8 })
local commands = runner.build_gradle_test_commands({
    root = root,
    file = kotlin_file,
    init_script = "/tmp/init.gradle",
    nearest = true,
})

-- 검증
assert_eq(commands[1][7], "com.acme.FooTest.does work", "nearest handles Kotlin modifiers and backtick names")

-- 실행
vim.api.nvim_win_set_cursor(0, { 8, 8 })
commands = runner.build_gradle_test_commands({
    root = root,
    file = kotlin_file,
    init_script = "/tmp/init.gradle",
    nearest = true,
})

-- 검증
assert_eq(commands[1][7], "com.acme.FooTest.inlineAnnotation", "nearest handles inline Kotlin test annotations")

-- 실행
vim.api.nvim_win_set_cursor(0, { 11, 8 })
commands = runner.build_gradle_test_commands({
    root = root,
    file = kotlin_file,
    init_script = "/tmp/init.gradle",
    nearest = true,
})

-- 검증
assert_eq(commands[1][7], "com.acme.FooTest", "nearest falls back to class filter for unannotated helpers")

vim.cmd.bwipeout({ bang = true })
vim.fn.delete(root, "rf")
