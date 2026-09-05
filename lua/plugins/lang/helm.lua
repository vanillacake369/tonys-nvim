local function has_helm_chart(path)
    local dir = vim.fs.dirname(path)
    if not dir then
        return false
    end
    return vim.fs.find({ "Chart.yaml", "Chart.yml" }, { path = dir, upward = true, limit = 1 })[1] ~= nil
end

local function helm_template_or_yaml(path)
    return has_helm_chart(path) and "helm" or "yaml"
end

local function helm_values_or_yaml(path)
    return has_helm_chart(path) and "yaml.helm-values" or "yaml"
end

vim.filetype.add({
    filename = {
        ["Chart.yaml"] = "yaml",
        ["Chart.yml"] = "yaml",
    },
    pattern = {
        [".*/templates/.*%.tpl"] = "helm",
        [".*/templates/.*%.ya?ml"] = helm_template_or_yaml,
        [".*/values%.ya?ml"] = helm_values_or_yaml,
        [".*/helmfile%.ya?ml"] = "helm",
        [".*%.gotmpl"] = "helm",
    },
})

return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.helm_ls = {
                cmd = { "helm_ls", "serve" },
                filetypes = { "helm", "yaml.helm-values" },
            }
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "helm" })
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.helm = { "prettier" }
            opts.formatters_by_ft["yaml.helm-values"] = { "prettier" }
        end,
    },
}
