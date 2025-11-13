-- Lazy.nvim Plugin Manager Bootstrap and Setup

-- Bootstrap Lazy.nvim installation
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Setup Lazy.nvim with plugin specifications
require("lazy").setup({
  spec = {
    { import = "plugins" }, -- Auto-import all files in plugins/
  },
  checker = { enabled = true },    -- Automatically check for updates
  change_detection = {
    notify = false                 -- Disable reload notifications
  },
})
