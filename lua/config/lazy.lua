local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazy_lock = {}
    local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
    if vim.fn.filereadable(lockfile) == 1 then
        local ok, decoded = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(lockfile), "\n"))
        lazy_lock = ok and decoded or {}
    end
    local lazy_pin = lazy_lock["lazy.nvim"] or {}

    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=" .. (lazy_pin.branch or "stable"),
        lazypath,
    })
    if vim.v.shell_error ~= 0 or not (vim.uv or vim.loop).fs_stat(lazypath) then
        error("failed to clone lazy.nvim")
    end
    if lazy_pin.commit then
        vim.fn.system({ "git", "-C", lazypath, "checkout", lazy_pin.commit })
        if vim.v.shell_error ~= 0 then
            error("failed to checkout lazy.nvim at " .. lazy_pin.commit)
        end
    end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = {
        { import = "plugins.core" },
        { import = "plugins.lang" },
        { import = "plugins.navigation" },
        { import = "plugins.ui" },
        -- 전체 plugins tree 를 한 번에 import 해야 할 때만 임시로 켠다.
        -- { import = "plugins" },
    },
    checker = { enabled = true, notify = false },
    change_detection = {
        notify = false,
    },
    -- Nix 가 구성한 packpath/runtimepath 를 lazy.nvim 초기화 과정에서
    -- 지우지 않도록 성능 옵션을 바깥 scope 에서 한 번에 설명한다.
    performance = {
        reset_packpath = false,
        rtp = {
            reset = false,
        },
    },
    rocks = {
        hererocks = false,
    },
})
