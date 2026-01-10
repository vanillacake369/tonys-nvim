-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.showmode = false

-- Tabs and indentation
vim.opt.tabstop = 4
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true

-- Wrap
vim.opt.wrap = false

-- Incremental Search
vim.opt.incsearch = true

-- 비주얼 모드에서 들여쓰기 후 선택 영역 유지
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
