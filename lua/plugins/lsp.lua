return {
    {
        "b0o/SchemaStore.nvim",
        lazy = true,
        version = false,
    },
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        build = ':TSUpdate',
        config = function()
            local configs = require("nvim-treesitter.configs")
            configs.setup({
                highlist = {
                    enable = true,
                },
                indent = { enable = true },
                autotage = { enable = true }, 
                ensure_installed = {
                    "bash",
                    "html",
                    "helm",
                    "dockerfile",
                    "java",
                    "javascript",
                    "json5",
                    "lua",
                    "markdown",
                    "markdown_inline",
                    "nix",
                    "terraform", 
                    "hcl",
                    "python",
                    "query",
                    "regex",
                    "tsx",
                    "typescript",
                    "vim",
                    "go", 
                    "gomod", 
                    "gowork", 
                    "gosum",
                    "yaml",
                },
            })
        end
    },
    {
        -- TODO : 어떻게 하면 mason 이 아닌 nix 패키지를 확인하고
        -- nix 에서 찾을 수 없다면 에러가 발생하게 하지 ? 
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                pylsp = {},
                jdtls = {},
                clangd = {},
                copilot = { enabled = false },
                -- k8s lsp
                -- Refered to following sources
                -- https://www.reddit.com/r/neovim/comments/ze9gbe/kubernetes_auto_completion_support_in_neovim/
                -- https://www.youtube.com/watch?v=pKCzpfqBbYs
                yamlls = {
                    settings = {
                        yaml = {
                            schemas = {
                                kubernetes = "*.yaml",
                                ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
                                ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
                                ["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/*.{yml,yaml}",
                                ["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
                                ["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
                                ["http://json.schemastore.org/ansible-playbook"] = "*play*.{yml,yaml}",
                                ["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
                                ["https://json.schemastore.org/dependabot-v2"] = ".github/dependabot.{yml,yaml}",
                                ["https://json.schemastore.org/gitlab-ci"] = "*gitlab-ci*.{yml,yaml}",
                                ["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json"] = "*api*.{yml,yaml}",
                                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*docker-compose*.{yml,yaml}",
                                ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] = "*flow*.{yml,yaml}",
                            },
                        }
                    }
                }
            },
        },
    },
    {
        "zbirenbaum/copilot.lua",
        opts = function()
            LazyVim.cmp.actions.ai_accept = function()
                if require("copilot.suggestion").is_visible() then
                    LazyVim.create_undo()
                    require("copilot.suggestion").accept()
                    return true
                end
            end
        end,
    },
}
