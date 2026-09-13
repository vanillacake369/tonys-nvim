return {
    -- query/regex/vim 같은 보조 문법 parser 를 treesitter 에 추가한다.
    -- 플러그인 설정과 검색 패턴 편집에서 highlighting 을 보완한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "query", "regex", "vim" })
        end,
    },
}
