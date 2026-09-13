return {
    -- Nix LSP(nixd)를 공통 lspconfig 서버 목록에 등록한다.
    -- flake registry 와 alejandra formatting 설정을 서버 쪽에도 맞춘다.
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.nixd = {
                cmd = { "nixd" },
                filetypes = { "nix" },
                settings = {
                    nixd = {
                        -- home-manager 가 pin 한 global flake registry 사용.
                        nixpkgs = {
                            expr = 'import (builtins.getFlake "nixpkgs") { }',
                        },
                        diagnostic = {
                            suppress = { "shadowing" },
                        },
                        formatting = {
                            command = { "alejandra" },
                        },
                    },
                },
            }
        end,
    },
    -- Nix parser 를 treesitter 공통 설치 목록에 추가한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "nix" })
        end,
    },
    -- Nix lint 는 statix/deadnix 를 nvim-lint 에 연결한다.
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.nix = { "statix", "deadnix" }
        end,
    },
    -- Nix formatter 는 alejandra 로 conform 에 연결한다.
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.nix = { "alejandra" }
        end,
    },
}
