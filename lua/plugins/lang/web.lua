return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.html = {
                cmd = { "vscode-html-language-server", "--stdio" },
                filetypes = { "html", "templ" },
            }
            opts.servers.cssls = {
                cmd = { "vscode-css-language-server", "--stdio" },
                filetypes = { "css", "scss", "less" },
            }
            opts.servers.jsonls = {
                cmd = { "vscode-json-language-server", "--stdio" },
                filetypes = { "json", "jsonc" },
            }
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "html", "css", "json", "json5" })
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.html = { "prettier" }
            opts.formatters_by_ft.templ = { "prettier" }
            opts.formatters_by_ft.css = { "prettier" }
            opts.formatters_by_ft.scss = { "prettier" }
            opts.formatters_by_ft.less = { "prettier" }
            opts.formatters_by_ft.json = { "prettier" }
            opts.formatters_by_ft.jsonc = { "prettier" }
        end,
    },
}
