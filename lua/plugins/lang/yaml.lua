local KUBERNETES_CRD_CATALOG_URL = "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main"

local KUBERNETES_MANIFEST_FILE_MATCHES = {
    "k8s/**/*.yaml",
    "k8s/**/*.yml",
    "kubernetes/**/*.yaml",
    "kubernetes/**/*.yml",
    "manifests/**/*.yaml",
    "manifests/**/*.yml",
}

local PRIVATE_KUBERNETES_CRD_SCHEMAS = {
    -- NOTE: CRDs-catalog 에 없는 private/operator CRD schema 는 여기에 둔다.
}

local function build_yaml_schemas()
    -- NOTE: yamlls built-in schemaStore fetch 는 끄고 SchemaStore.nvim 을 쓴다.
    -- Kubernetes repo 관례 경로는 local override 로 hover/validate 를 안정화.
    local schemas = require("schemastore").yaml.schemas()
    schemas.kubernetes = KUBERNETES_MANIFEST_FILE_MATCHES

    for schema_uri, file_matches in pairs(PRIVATE_KUBERNETES_CRD_SCHEMAS) do
        schemas[schema_uri] = file_matches
    end

    return schemas
end

return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.yamlls = {
                cmd = { "yaml-language-server", "--stdio" },
                filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
                settings = {
                    yaml = {
                        schemaStore = { enable = false, url = "" },
                        kubernetesCRDStore = {
                            enable = true,
                            url = KUBERNETES_CRD_CATALOG_URL,
                        },
                        schemas = build_yaml_schemas(),
                        validate = true,
                        completion = true,
                        hover = true,
                    },
                },
            }
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "yaml" })
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.yaml = { "prettier", "yamlfmt" }
            opts.formatters_by_ft["yaml.docker-compose"] = { "prettier", "yamlfmt" }
            opts.formatters_by_ft["yaml.gitlab"] = { "prettier", "yamlfmt" }
        end,
    },
}
