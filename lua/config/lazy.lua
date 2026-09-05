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
