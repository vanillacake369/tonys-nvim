local H = require("tests.helpers")
local assert_eq = H.assert_eq
local runner = H.gradle_runner()

-- GIVEN
local root = H.temp_root()
local kotlin_file = root .. "/src/test/kotlin/com/acme/FooTest.kt"
H.write(kotlin_file, {
    "package com.acme",
    "",
    "internal class FooTest {",
    "    private val fixture = 42",
    "",
    "    @Test",
    "    internal fun `does work`() {",
    "        val result = 1 + 1",
    "        assertEquals(2, result)",
    "    }",
    "",
    "    @Test",
    "    fun acceptsInput() {",
    "        assertTrue(true)",
    "    }",
    "}",
})
local metadata = {
    [kotlin_file] = {
        display_path = "src/test/kotlin/com/acme/FooTest.kt",
        task = "test",
        module_dir = root,
    },
}

-- WHEN
local items = runner.discover_kotlin_tests({ kotlin_file }, metadata)
runner.attach_test_previews(items)

-- THEN
assert_eq(items[1].pos, { 7, 0 }, "picker item exposes Snacks location for selected test preview")
assert_eq(items[1].preview.ft, "kotlin", "preview keeps source syntax")
assert_eq(
    items[1].preview.text:match("// === test  com%.acme%.FooTest%.does work  .+FooTest%.kt:7 ===") ~= nil,
    true,
    "preview starts with a visible separator"
)
assert_eq(
    items[1].preview.text:find("private val fixture = 42", 1, true) ~= nil,
    true,
    "preview includes a few lines before the selected method"
)
assert_eq(
    items[1].preview.text:find("internal fun `does work`()", 1, true) ~= nil,
    true,
    "preview includes selected method"
)
assert_eq(items[1].preview.text:find("fun acceptsInput()", 1, true), nil, "preview stops before the next test method")
assert_eq(
    items[1].preview.text:find("// === end com.acme.FooTest.does work ===", 1, true) ~= nil,
    true,
    "preview ends with a visible separator"
)

vim.fn.delete(root, "rf")
