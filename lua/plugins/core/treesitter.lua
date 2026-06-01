local lang = require("config.languages")

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

-- Parser .so files are bundled into the rtp by tonys-nix via
-- `programs.neovim.plugins = [ pkgs.vimPlugins.nvim-treesitter.withAllGrammars ]`
-- (the wrapper symlinks both plugin and grammars under site/pack/hm/start/).
-- On non-Nix hosts, lazy.nvim's `ensure_installed` populates parsers itself.
local nix_dir = find_nix_plugin()

-- Treesitter 설정 테이블 (중첩 완화를 위해 미리 정의)
local ts_config = {
    ensure_installed = nix_dir and {} or lang.collect_treesitter_parsers(),
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
}

return {
    "nvim-treesitter/nvim-treesitter",
    dir = nix_dir,
    build = not nix_dir and ":TSUpdate" or nil,
    enabled = true,
    lazy = false,

    config = function()
        local ok, configs = pcall(require, "nvim-treesitter.configs")

        -- 1. 모듈 로드 실패 시(Nix 특수 환경 등), Neovim 내장 기능만 활성화하고 조기 종료
        if not ok then
            vim.api.nvim_create_autocmd("FileType", {
                callback = function()
                    pcall(vim.treesitter.start)
                end,
            })
            return
        end

        -- 2. 모듈 로드 성공 시 설정 적용
        configs.setup(ts_config)

        -- 3. Pre-flight: 선언된 언어들의 parser .so가 rtp에 실제로 잡히는지
        -- startup 시점에 확인. 누락 시 neotest position discovery 빈 트리,
        -- render-markdown 무동작 등 cryptic 실패가 나기 전에 ERROR로 알림.
        -- Nix `withAllGrammars`가 빠지거나 lazy `ensure_installed`가 안 돈
        -- 케이스를 즉시 surface.
        vim.schedule(function()
            local missing = {}
            for _, parser_lang in ipairs(lang.collect_treesitter_parsers()) do
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
