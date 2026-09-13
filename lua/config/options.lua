-- 줄 번호
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.showmode = false

-- 최대 줄 너비
vim.opt.textwidth = 80

-- 탭과 들여쓰기
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.autoindent = true

-- 마우스 입력 허용
vim.opt.mouse = "a"

-- 자동 줄바꿈
vim.opt.wrap = false

-- 접기
vim.opt.foldenable = true
vim.opt.foldmethod = "manual"
vim.opt.foldlevelstart = 99
vim.opt.foldcolumn = "1"

-- 검색은 incremental 로 수행하고, 대문자를 입력하기 전까지는 대소문자를 구분하지 않는다.
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
