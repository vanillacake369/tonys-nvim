local H = require("tests.helpers")
local debugger = require("plugins.core.debugger")
local bundles = debugger._test

-- GIVEN
local jdtls_asm_range = "[9.9.0,9.10.0)"

-- WHEN / THEN
H.assert_eq(bundles.version_in_range("9.9.0", jdtls_asm_range), true, "lower bound should be inclusive")
H.assert_eq(bundles.version_in_range("9.10.0", jdtls_asm_range), false, "upper bound should be exclusive")
H.assert_eq(bundles.version_in_range("9.10.1", jdtls_asm_range), false, "newer incompatible versions should fail")
H.assert_eq(
    bundles.version_in_range("1.0.0.v20260209-1721", "1.0.0"),
    true,
    "qualified OSGi versions should satisfy base versions"
)
H.assert_eq(bundles.compare_versions("0.46.0", "0.45.0") > 0, true, "newer java-test candidates should win")

-- GIVEN
local nix_java_test_path = "/nix/store/x-vscode-extension-vscjava-vscode-java-test-0.45.0/share/server"

-- WHEN / THEN
H.assert_eq(bundles.extension_version(nix_java_test_path), "0.45.0", "Nix extension version is parsed")

-- GIVEN
local manifest_list = 'org.eclipse.lsp4j,org.objectweb.asm;bundle-version="[9.9.0,9.10.0)",org.eclipse.jdt.core'

-- WHEN
local manifest_items = bundles.split_manifest_list(manifest_list)

-- THEN
H.assert_eq(manifest_items, {
    "org.eclipse.lsp4j",
    'org.objectweb.asm;bundle-version="[9.9.0,9.10.0)"',
    "org.eclipse.jdt.core",
}, "manifest lists should not split commas inside quoted version ranges")

-- GIVEN
local dir = vim.fn.tempname()
vim.fn.mkdir(dir .. "/server", "p")
vim.fn.writefile({
    vim.fn.json_encode({
        contributes = {
            javaExtensions = {
                "./server/declared-one.jar",
                "./server/declared-two.jar",
            },
        },
    }),
}, dir .. "/package.json")
vim.fn.writefile({ "" }, dir .. "/server/declared-one.jar")
vim.fn.writefile({ "" }, dir .. "/server/declared-two.jar")
vim.fn.writefile({ "" }, dir .. "/server/unlisted.jar")

-- WHEN
local jars = bundles.java_extension_jars({ path = dir })

-- THEN
H.assert_eq(
    vim.tbl_map(function(path)
        return vim.fn.fnamemodify(path, ":t")
    end, jars),
    { "declared-one.jar", "declared-two.jar" },
    "Java extension bundle discovery should follow package.json contributes.javaExtensions"
)

-- GIVEN
local notified = false
local original_notify = vim.notify
vim.notify = function()
    notified = true
end

-- WHEN
debugger.java_bundles()
vim.notify = original_notify

-- THEN
H.assert_eq(notified, false, "optional incompatible Java bundles should not warn during startup")
