-- Language configurations for LSP, Treesitter, and Linters
-- Single source of truth for all language-related settings

local M = {}

M.languages = {
    python = {
        lsp_server = "pylsp",
        lsp_opts = {
            cmd = { "pylsp" },
        },
        treesitter = {
            "python",
            "ninja",
            "rst",
        },
        linters = { "ruff" }
    },
    java = {
        lsp_server = "jdtls",
        lsp_opts = {
            cmd = { "jdtls" },
        },
        treesitter = {
            "java",
        }
    },
    c_cpp = {
        lsp_server = "clangd",
        lsp_opts = {
            cmd = { "clangd" },
        },
        treesitter = {
            "c",
            "cpp",
        }
    },
    yaml = {
        lsp_server = "yamlls",
        lsp_opts = {
            cmd = { "yaml-language-server", "--stdio" },
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
        },
        treesitter = {
            "yaml",
        },
        linters = { "yamllint" }
    },
    go = {
        lsp_server = "gopls",
        lsp_opts = {
            cmd = { "gopls" },
        },
        treesitter = {
            "go",
            "gomod",
            "gowork",
            "gosum",
        },
        linters = { "golangcilint" }
    },
    javascript = {
        lsp_server = "ts_ls",
        lsp_opts = {
            cmd = { "typescript-language-server", "--stdio" },
        },
        treesitter = {
            "javascript",
            "typescript",
            "tsx",
        },
        linters = { "biomejs" }
    },
    nix = {
        lsp_server = "nil_ls",
        lsp_opts = {
            cmd = { "nil" },
        },
        treesitter = {
            "nix",
        },
        linters = { "statix", "deadnix" }
    },
    lua = {
        lsp_server = "lua_ls",
        lsp_opts = {
            cmd = { "lua-language-server" },
        },
        treesitter = {
            "lua",
        },
        linters = { "selene" }
    },
    terraform = {
        lsp_server = "terraformls",
        lsp_opts = {
            cmd = { "terraform-ls", "serve" },
        },
        treesitter = {
            "terraform",
            "hcl",
        },
        linters = { "tflint" }
    },
    bash = {
        lsp_server = "bashls",
        lsp_opts = {
            cmd = { "bash-language-server", "start" },
        },
        treesitter = {
            "bash",
        },
        linters = { "shellcheck" }
    },
    html = {
        lsp_server = "html",
        lsp_opts = {
            cmd = { "vscode-html-language-server", "--stdio" },
        },
        treesitter = {
            "html",
        }
    },
    css = {
        lsp_server = "cssls",
        lsp_opts = {
            cmd = { "vscode-css-language-server", "--stdio" },
        },
        treesitter = {
            "css",
        }
    },
    json = {
        lsp_server = "jsonls",
        lsp_opts = {
            cmd = { "vscode-json-language-server", "--stdio" },
        },
        treesitter = {
            "json",
            "json5",
        }
    },
    docker = {
        lsp_server = "docker_compose_language_service",
        lsp_opts = {
            cmd = { "docker-compose-langserver", "--stdio" },
        },
        treesitter = {
            "dockerfile",
        },
        linters = { "hadolint" }
    },
    helm = {
        treesitter = {
            "helm",
        }
    },
    markdown = {
        treesitter = {
            "markdown",
            "markdown_inline",
        }
    },
    other = {
        treesitter = {
            "query",
            "regex",
            "vim",
        }
    }
}

-- Collect all LSP server configurations
function M.collect_lsp_servers()
    local servers = {}
    for _, lang_config in pairs(M.languages) do
        if lang_config.lsp_server then
            servers[lang_config.lsp_server] = lang_config.lsp_opts or {}
        end
    end
    return servers
end

-- Collect all Treesitter parsers
function M.collect_treesitter_parsers()
    local parsers = {}
    for _, lang_config in pairs(M.languages) do
        if lang_config.treesitter then
            for _, parser in ipairs(lang_config.treesitter) do
                table.insert(parsers, parser)
            end
        end
    end
    return parsers
end

-- Collect linters organized by filetype
function M.collect_linters()
    local linters_by_ft = {}

    -- Mapping from language config names to filetypes
    local filetype_mapping = {
        bash = { "bash", "sh" },
        javascript = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
        terraform = { "terraform", "tf" },
        docker = { "dockerfile" },
    }

    for lang_name, lang_config in pairs(M.languages) do
        if lang_config.linters then
            -- Get filetypes for this language
            local filetypes = filetype_mapping[lang_name] or { lang_name }

            -- Assign linters to each filetype
            for _, ft in ipairs(filetypes) do
                linters_by_ft[ft] = lang_config.linters
            end
        end
    end

    return linters_by_ft
end

return M
