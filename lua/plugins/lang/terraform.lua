return {
    -- Terraform LSP(terraform-ls)를 공통 lspconfig 서버 목록에 등록한다.
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
    -- Terraform/HCL parser 를 treesitter 공통 설치 목록에 추가한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "terraform", "hcl" })
        end,
    },
    -- Terraform lint 는 tflint 로 nvim-lint 에 연결한다.
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.terraform = { "tflint" }
            opts.linters_by_ft["terraform-vars"] = { "tflint" }
        end,
    },
    -- Terraform formatter 는 terraform fmt 를 conform 에 연결한다.
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.terraform = { "terraform_fmt" }
            opts.formatters_by_ft["terraform-vars"] = { "terraform_fmt" }
        end,
    },
}
