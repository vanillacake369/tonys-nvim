local H = require("tests.helpers")
local assert_eq = H.assert_eq
local runner = H.gradle_runner()

-- NOTE: command test 는 argv contract 를 고정한다. 실제 Gradle build 를 실행하지
-- 않고 option 순서, wrapper fallback, shell join, debug, watch 회귀를 잡는다.

-- GIVEN
local root = H.temp_root()
H.gradlew(root)

-- WHEN
local commands = runner.build_gradle_test_commands({
    root = root,
    init_script = "/tmp/init.gradle",
    items = {
        { task = ":app:test", filter = "com.acme.AppTest.first" },
        { task = ":lib:test", filter = "com.acme.LibTest.second" },
        { task = ":app:test", filter = "com.acme.AppTest.third" },
    },
})

-- THEN
assert_eq(commands, {
    {
        "./gradlew",
        "--init-script",
        "/tmp/init.gradle",
        ":app:test",
        "--tests",
        "com.acme.AppTest.first",
        "--tests",
        "com.acme.AppTest.third",
        "--rerun-tasks",
        "--console=plain",
    },
    {
        "./gradlew",
        "--init-script",
        "/tmp/init.gradle",
        ":lib:test",
        "--tests",
        "com.acme.LibTest.second",
        "--rerun-tasks",
        "--console=plain",
    },
}, "selected multi-module tests are grouped by Gradle task")

-- WHEN
local combined = runner.combined_command(commands)
local shell = table.concat(combined, " ")

-- THEN
assert_eq(combined[1], "sh", "multi-command runs through shell")
assert_eq(combined[2], "-lc", "multi-command uses login-independent shell command")
assert_eq(
    shell:match(":app:test") ~= nil and shell:match(":lib:test") ~= nil and shell:match(" && ") ~= nil,
    true,
    "multi-task Gradle run is sequential"
)

vim.fn.delete(root, "rf")

-- GIVEN
root = H.temp_root()
H.gradlew(root)

-- WHEN
local debug_commands = runner.build_gradle_debug_commands({
    root = root,
    init_script = "/tmp/init.gradle",
    items = {
        { task = ":app:test", filter = "com.acme.AppTest.first" },
    },
})

-- THEN
assert_eq(debug_commands, {
    {
        "./gradlew",
        "--init-script",
        "/tmp/init.gradle",
        ":app:test",
        "--tests",
        "com.acme.AppTest.first",
        "--rerun-tasks",
        "--debug-jvm",
        "--console=plain",
    },
}, "debug test uses the same task-local filter with Gradle JDWP")

vim.fn.delete(root, "rf")

-- GIVEN
root = H.temp_root()
H.gradlew(root)

-- WHEN
local watch_commands = runner.build_gradle_test_commands({
    root = root,
    init_script = "/tmp/init.gradle",
    watch = true,
    items = {
        { task = ":app:test", filter = "com.acme.AppTest.first" },
        { task = ":lib:test", filter = "com.acme.LibTest.second" },
    },
})
combined = runner.combined_command(watch_commands)

-- THEN
assert_eq(watch_commands[1][#watch_commands[1] - 1], "--continuous", "watch flag stays inside each Gradle argv")
assert_eq(watch_commands[2][#watch_commands[2] - 1], "--continuous", "multi-module watch applies to every Gradle argv")
assert_eq(#combined, 3, "multi-module watch does not append Gradle flags to sh argv")

vim.fn.delete(root, "rf")

-- GIVEN
root = H.temp_root()
H.gradlew(root)

-- WHEN
commands = runner.build_gradle_test_commands({
    root = root,
    init_script = "/tmp/init.gradle",
    items = {
        { task = ":app:test", filter = "com.acme.AppTest.first" },
    },
})

-- THEN
assert_eq(commands[1][1], "./gradlew", "Gradle wrapper is preferred when present")

vim.fn.delete(root, "rf")

-- GIVEN
root = H.temp_root()
H.gradlew(root)

-- WHEN
local escaped = runner.combined_command({
    {
        "./gradlew",
        ":app:test",
        "--tests",
        "com.acme.AppTest.does work's case",
        "--console=plain",
    },
    {
        "./gradlew",
        ":lib:test",
        "--tests",
        "com.acme.LibTest.second",
        "--console=plain",
    },
})

-- THEN
assert_eq(escaped[3]:match("does work") ~= nil, true, "shell command preserves spaced filters")
assert_eq(escaped[3]:find("\\'", 1, true) ~= nil, true, "shell command escapes quoted filters")

vim.fn.delete(root, "rf")
