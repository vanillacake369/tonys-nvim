local H = require("tests.helpers")
local assert_eq = H.assert_eq
local runner = H.gradle_runner()

-- project spec 은 Gradle 탐지를 사용할 수 없을 때의 fallback mapping 을
-- 검증한다. Gradle 을 실행하지 않고 headless Neovim 에서 nested module 동작을
-- 결정적으로 유지한다.

-- GIVEN
local root = H.temp_root()
local kotlin_file = root .. "/feature/src/test/kotlin/com/acme/FooTest.kt"
H.write(root .. "/settings.gradle.kts", { 'include("feature")' })
H.write(root .. "/feature/build.gradle.kts", { 'plugins { kotlin("jvm") }' })
H.write(kotlin_file, {
    "package com.acme",
    "",
    "class FooTest {",
    "    @Test",
    "    fun works() {",
    "    }",
    "}",
})

-- WHEN
local commands = runner.build_gradle_test_commands({
    root = root,
    file = kotlin_file,
    init_script = "/tmp/init.gradle",
})

-- THEN
assert_eq(commands, {
    {
        "gradle",
        "--init-script",
        "/tmp/init.gradle",
        ":feature:cleanTest",
        ":feature:test",
        "--tests",
        "com.acme.FooTest",
        "--console=plain",
    },
}, "nested Gradle test files fallback to the nearest module task")

vim.fn.delete(root, "rf")

-- GIVEN
local alternate_target = _G.__test_alternate._test.alternate_target
root = H.temp_root()

-- WHEN / THEN
assert_eq(
    alternate_target(root .. "/src/main/java/com/acme/Foo.java"),
    root .. "/src/test/java/com/acme/FooTest.java",
    "Java source files create matching test files"
)
assert_eq(
    alternate_target(root .. "/lua/plugins/core/paste-img.lua"),
    root .. "/tests/paste_img_spec.lua",
    "Lua source files create root spec files with module-safe names"
)
assert_eq(
    alternate_target(root .. "/src/test/java/com/acme/FooTest.java"),
    root .. "/src/main/java/com/acme/Foo.java",
    "Java test files jump back to source files"
)
H.write(root .. "/lua/plugins/core/debugger.lua", { "return {}" })
assert_eq(
    alternate_target(root .. "/tests/debugger_spec.lua"),
    root .. "/lua/plugins/core/debugger.lua",
    "Lua spec files jump back to the matching source file"
)
assert_eq(
    alternate_target(root .. "/service.go"),
    root .. "/service_test.go",
    "Go source files create sibling test files"
)
assert_eq(
    alternate_target(root .. "/tests/test_service.py"),
    root .. "/service.py",
    "Python test files jump back to source files"
)

vim.fn.delete(root, "rf")

-- GIVEN
root = H.temp_root()
local java_file = root .. "/src/test/java/FooTest.java"
H.write(root .. "/build.gradle", { "plugins { id 'java' }" })
H.write(java_file, {
    "class FooTest {",
    "    @org.junit.jupiter.api.Test",
    "    void works() {",
    "    }",
    "}",
})

-- WHEN
commands = runner.build_gradle_test_commands({
    root = root,
    file = java_file,
    init_script = "/tmp/init.gradle",
})

-- THEN
assert_eq(commands[1][1], "gradle", "system Gradle is used when wrapper is absent")
assert_eq(commands[1][7], "FooTest", "package-less JVM files use class-name filters")

vim.fn.delete(root, "rf")
