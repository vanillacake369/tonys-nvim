local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s\nexpected: %s\nactual: %s", message, vim.inspect(expected), vim.inspect(actual)))
    end
end

local paste_img = require("plugins.core.paste-img")

local tmp = vim.fs.normalize(vim.fn.tempname())
local post_dir = tmp .. "/src/content/posts/public/Series"
local image_dir = tmp .. "/public/images/posts/Series/2026-08-27-post"
local post = post_dir .. "/2026-08-27-post.md"
local image = image_dir .. "/diagram.png"

vim.fn.mkdir(post_dir, "p")
vim.fn.mkdir(image_dir, "p")
vim.fn.writefile({ '{ "name": "tonys-blog" }' }, tmp .. "/package.json")
vim.fn.writefile({ "export default {};" }, tmp .. "/astro.config.mjs")
vim.fn.writefile({ "# Post" }, post)
vim.fn.writefile({ "image" }, image)

local ctx = paste_img.get_context_for_path(post)

assert_eq(ctx.kind, "tonys-blog-fallback", "missing md-rule.toml uses tonys-blog fallback")
assert_eq(ctx.identity, "Series/2026-08-27-post", "fallback identity keeps post subdirectories")
assert_eq(ctx.asset_dir, image_dir, "fallback asset dir follows public image policy")
assert_eq(
    paste_img.markdown_link_for(ctx, image),
    "/images/posts/Series/2026-08-27-post/diagram.png",
    "fallback markdown link follows public image URL policy"
)

vim.fn.delete(tmp, "rf")
