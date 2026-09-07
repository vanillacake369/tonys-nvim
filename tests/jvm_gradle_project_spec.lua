local H = require("tests.helpers")
local assert_eq = H.assert_eq
local runner = H.gradle_runner()

-- NOTE: project test 는 Gradle probe 를 사용할 수 없을 때의 fallback mapping 을
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
