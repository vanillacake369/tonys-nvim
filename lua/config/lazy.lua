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

require("lazy").setup({
	spec = {
		{ import = "plugins.core" },
		{ import = "plugins.navigation" },
		{ import = "plugins.ui" },
		-- { import = "plugins" },
	},
	checker = { enabled = true, notify = false },
	change_detection = {
		notify = false,
	},
	performance = {
		reset_packpath = false, -- Nix에서 설정한 플러그인 경로를 보존합니다.
		rtp = {
			reset = false, -- Nix에서 설정한 런타임 경로 초기화를 방지합니다.
		},
	},
})
