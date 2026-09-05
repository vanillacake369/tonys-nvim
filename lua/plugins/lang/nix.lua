return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.nixd = {
                cmd = { "nixd" },
                filetypes = { "nix" },
                settings = {
                    nixd = {
                        -- NOTE: home-manager 가 pin 한 global flake registry 사용.
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
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "nix" })
        end,
    },
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.nix = { "statix", "deadnix" }
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.nix = { "alejandra" }
        end,
    },
}
