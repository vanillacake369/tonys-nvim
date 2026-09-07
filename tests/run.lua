-- GIVEN
local specs = {
    "tests/paste_img_fallback_spec.lua",
    "tests/jvm_gradle_command_spec.lua",
    "tests/jvm_gradle_project_spec.lua",
    "tests/jvm_gradle_discovery_spec.lua",
    "tests/jvm_gradle_cursor_spec.lua",
}

local failures = {}

-- WHEN
for _, spec in ipairs(specs) do
    local ok, err = pcall(dofile, spec)
    if not ok then
        table.insert(failures, spec .. "\n" .. tostring(err))
    end
end

-- THEN
if #failures > 0 then
    vim.api.nvim_err_writeln(table.concat(failures, "\n\n"))
    vim.cmd("cquit 1")
end

print("tests ok")
