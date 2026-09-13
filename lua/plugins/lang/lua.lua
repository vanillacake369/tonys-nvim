return {
    -- Lua LSP 를 Neovim 설정 파일 편집용 공통 서버로 등록한다.
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.lua_ls = {
                cmd = { "lua-language-server" },
                filetypes = { "lua" },
            }
        end,
    },
    -- Lua parser 를 treesitter 공통 설치 목록에 추가한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "lua" })
        end,
    },
    -- Lua lint 는 selene 으로 nvim-lint 에 연결한다.
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.lua = { "selene" }
        end,
    },
    -- Lua formatter 는 stylua 로 conform 에 연결한다.
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.lua = { "stylua" }
        end,
    },
    -- lazydev 로 Neovim/Luv type hint 를 Lua buffer 에 보강한다.
    -- blink.cmp 와 연동해 plugin config 작성 중 completion 품질을 올린다.
    {
        "folke/lazydev.nvim",
        ft = "lua",
        dependencies = {
            { "Bilal2453/luvit-meta", lazy = true },
        },
        opts = {
            library = {
                -- `vim.uv` 단어가 보이면 luvit type 을 함께 로드한다.
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
}
