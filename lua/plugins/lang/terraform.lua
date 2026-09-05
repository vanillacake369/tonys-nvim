return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.terraformls = {
                cmd = { "terraform-ls", "serve" },
                filetypes = { "terraform", "terraform-vars" },
            }
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "terraform", "hcl" })
        end,
    },
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.terraform = { "tflint" }
            opts.linters_by_ft["terraform-vars"] = { "tflint" }
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.terraform = { "terraform_fmt" }
            opts.formatters_by_ft["terraform-vars"] = { "terraform_fmt" }
        end,
    },
}
