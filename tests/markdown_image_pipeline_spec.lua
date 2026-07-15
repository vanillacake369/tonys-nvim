local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s\nexpected: %s\nactual: %s", message, vim.inspect(expected), vim.inspect(actual)))
    end
end

local function assert_true(value, message)
    if not value then
        error(message)
    end
end

local assets = require("config.markdown_assets")
local images = require("config.markdown_images")

local tmp = vim.fs.normalize(vim.fn.tempname())
vim.fn.mkdir(tmp .. "/assets/plain", "p")
vim.fn.writefile({ "x" }, tmp .. "/assets/plain/a.png")

local md = tmp .. "/plain.md"
vim.fn.writefile({
    "# Title",
    "",
    "![alt](./assets/plain/a.png)",
}, md)

vim.cmd.edit(vim.fn.fnameescape(md))
vim.bo.filetype = "markdown"

local first = assets.resolve_for_snacks(md, "./assets/plain/a.png")
local second = assets.resolve_for_snacks(md, "./assets/plain/a.png")
assert_eq(first, tmp .. "/assets/plain/a.png", "relative markdown image target resolves")
assert_eq(second, first, "resolve cache returns stable path")

local stats = assets.cache_stats()
assert_true(stats.resolve_hits >= 1, "resolve cache records a hit")
assert_true(stats.resolve_misses >= 1, "resolve cache records a miss")

images.enable(0)
vim.wait(200, function()
    return images.state.buffers[vim.api.nvim_get_current_buf()] ~= nil
end, 10)
assert_true(images.state.buffers[vim.api.nvim_get_current_buf()] ~= nil, "markdown image state is created")

images.disable(0)
assert_eq(images.state.buffers[vim.api.nvim_get_current_buf()].enabled, false, "disable updates buffer state")

vim.cmd("bwipeout!")
vim.fn.delete(tmp, "rf")
