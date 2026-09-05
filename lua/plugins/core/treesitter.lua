-- Nix 환경에서 설치된 '코어' nvim-treesitter 경로를 검색합니다.
local function find_nix_plugin()
    local paths = {
        "/nix/store/*-vimplugin-nvim-treesitter-*[0-9]*/",
        "/nix/store/*-vimplugin-nvim-treesitter/",
        "/etc/profiles/per-user/*/share/vim-plugins/nvim-treesitter",
        "~/.nix-profile/share/vim-plugins/nvim-treesitter",
    }

    for _, path in ipairs(paths) do
        local dir = vim.fn.glob(path, true, true)[1]
        if dir and vim.fn.isdirectory(dir .. "/lua") == 1 then
            return dir
        end
    end
    return nil
end

-- COMPAT: tonys-nix bundles parser .so files into rtp with
-- nvim-treesitter.withAllGrammars. Non-Nix hosts use lazy ensure_installed.
local nix_dir = find_nix_plugin()

return {
    "nvim-treesitter/nvim-treesitter",
    dir = nix_dir,
    build = not nix_dir and ":TSUpdate" or nil,
    enabled = true,
    lazy = false,

    opts = {
        ensure_installed = {},
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "<CR>",
                node_incremental = "<CR>",
                scope_incremental = "<Tab>",
                node_decremental = "<BS>",
            },
        },
    },

    config = function(_, opts)
        local ok, configs = pcall(require, "nvim-treesitter.configs")

        -- WARN: 모듈 로드 실패 시 내장 treesitter 만 켜고 조기 종료.
        if not ok then
            vim.api.nvim_create_autocmd("FileType", {
                callback = function()
                    pcall(vim.treesitter.start)
                end,
            })
            return
        end

        -- 2. 모듈 로드 성공 시 설정 적용
        local declared_parsers = vim.deepcopy(opts.ensure_installed or {})

        if nix_dir then
            opts.ensure_installed = {}
        end

        configs.setup(opts)

        -- WARN: fail early when declared parsers are missing from rtp. Missing
        -- parsers otherwise surface later as empty neotest trees or broken
        -- render-markdown behavior.
        vim.schedule(function()
            local missing = {}
            for _, parser_lang in ipairs(declared_parsers) do
                if #vim.api.nvim_get_runtime_file("parser/" .. parser_lang .. ".so", false) == 0 then
                    table.insert(missing, parser_lang)
                end
            end
            if #missing > 0 then
                vim.notify(
                    "Treesitter parsers missing from rtp: "
                        .. table.concat(missing, ", ")
                        .. "\nNeotest / render-markdown / incremental_selection will silently fail."
                        .. "\nOn Nix: ensure programs.neovim.plugins includes nvim-treesitter.withAllGrammars.",
                    vim.log.levels.ERROR
                )
            end
        end)
    end,
}
