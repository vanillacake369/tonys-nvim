local H = require("tests.helpers")
local assert_eq = H.assert_eq
local runner = H.gradle_runner()

-- NOTE: discovery test 는 neotest-java 를 쓰지 않는 Kotlin 경로를 검증한다.
-- 여기서 DSL 을 만들면 실패 원인을 읽기 어려워지므로 case 는 구체적으로 둔다.

-- 준비
local root = H.temp_root()
local kotlin_file = root .. "/feature/src/test/kotlin/com/acme/FooTest.kt"
H.write(kotlin_file, {
    "package com.acme",
    "",
    "internal class FooTest {",
    "    @Test",
    "    internal fun `does work`() {",
    "    }",
    "",
    "    @org.junit.jupiter.params.ParameterizedTest",
    "    fun acceptsInput() {",
    "    }",
    "",
    "    @Test fun inlineAnnotation() {",
    "    }",
    "",
    "    fun helper() {",
    "    }",
    "}",
})
local metadata = {
    [kotlin_file] = {
        display_path = "feature/src/test/kotlin/com/acme/FooTest.kt",
        task = ":feature:test",
        module_dir = root .. "/feature",
    },
}

-- 실행
local items = runner.discover_kotlin_tests({ kotlin_file }, metadata)

-- 검증
assert_eq({
    items[1].filter,
    items[2].filter,
    items[3].filter,
}, {
    "com.acme.FooTest.does work",
    "com.acme.FooTest.acceptsInput",
    "com.acme.FooTest.inlineAnnotation",
}, "Kotlin discovery resolves modifiers, fq annotations, and inline annotations")
assert_eq(#items, 3, "Kotlin discovery ignores unannotated helpers")

vim.fn.delete(root, "rf")
