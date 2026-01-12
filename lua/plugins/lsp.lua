local languages = {
    python = {
        lsp_server = "pylsp",
        lsp_opts = {
            cmd = { "pylsp" },
        },
        treesitter = {
            "python",
            "ninja",
            "rst",
        }
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
        }
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
        }
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
        }
    },
    nix = {
        lsp_server = "nil_ls",
        lsp_opts = {
            cmd = { "nil" },
        },
        treesitter = {
            "nix",
        }
    },
    lua = {
        lsp_server = "lua_ls",
        lsp_opts = {
            cmd = { "lua-language-server" },
        },
        treesitter = {
            "lua",
        }
    },
    terraform = {
        lsp_server = "terraformls",
        lsp_opts = {
            cmd = { "terraform-ls", "serve" },
        },
        treesitter = {
            "terraform",
            "hcl",
        }
    },
    bash = {
        lsp_server = "bashls",
        lsp_opts = {
            cmd = { "bash-language-server", "start" },
        },
        treesitter = {
            "bash",
        }
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
        }
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

local function collect_lsp_servers()
    local servers = {}
    for _, lang_config in pairs(languages) do
        if lang_config.lsp_server then
            servers[lang_config.lsp_server] = lang_config.lsp_opts or {}
        end
    end
    return servers
end

local function collect_treesitter_parsers()
    local parsers = {}
    for _, lang_config in pairs(languages) do
        if lang_config.treesitter then
            for _, parser in ipairs(lang_config.treesitter) do
                table.insert(parsers, parser)
            end
        end
    end
    return parsers
end

return {
    {
        "folke/trouble.nvim",
        opts = {}, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Diagnostics (Trouble)",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Buffer Diagnostics (Trouble)",
            },
            {
                "<leader>cs",
                "<cmd>Trouble symbols toggle focus=false<cr>",
                desc = "Symbols (Trouble)",
            },
            {
                "<leader>cl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "LSP Definitions / references / ... (Trouble)",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Location List (Trouble)",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Quickfix List (Trouble)",
            },
        },
    },
    {
        "b0o/SchemaStore.nvim",
        lazy = true,
        version = false,
    },
    {
        "mfussenegger/nvim-lint",
        event = { "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" }, -- 표준 이벤트 사용
        config = function()
            local lint = require("lint")

            lint.linters_by_ft = {
                bash = { "shellcheck" },
                sh = { "shellcheck" },
                go = { "golangcilint" },
                python = { "ruff" },
                nix = { "statix", "deadnix" },
                lua = { "selene" },
                terraform = { "tflint" },
                tf = { "tflint" },
                dockerfile = { "hadolint" },
                javascript = { "biomejs" },
                typescript = { "biomejs" },
                javascriptreact = { "biomejs" },
                typescriptreact = { "biomejs" },
                yaml = { "yamllint" },
            }

            -- 린트 실행 자동 명령
            vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
                group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
                callback = function()
                    lint.try_lint()
                end,
            })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        build = ':TSUpdate',
        config = function()
            local configs = require("nvim-treesitter.configs")
            configs.setup({
                highlight = {
                    enable = true,
                },
                indent = { enable = true },
                autotag = { enable = true },
                ensure_installed = collect_treesitter_parsers(),
            })
        end
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            local servers = collect_lsp_servers()

            -- 진단 설정
            vim.diagnostic.config({
                virtual_text = {
                    prefix = '●',
                    source = "if_many",
                },
                underline = true,
                signs = true,
                update_in_insert = true,
                severity_sort = true,
            })

            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(args)
                    local opts = { buffer = args.buf }
                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
                end,
            })

            for server, config in pairs(servers) do
                local cmd
                if config.cmd and type(config.cmd) == "table" then
                    cmd = config.cmd[1]
                elseif config.cmd and type(config.cmd) == "string" then
                    cmd = config.cmd
                else
                    cmd = server
                end

                if vim.fn.executable(cmd) == 1 then
                    -- Use new vim.lsp.config API (Nvim 0.11+)
                    vim.lsp.config(server, config)
                    vim.lsp.enable(server)
                else
                    vim.notify(
                        string.format("LSP '%s' not found. Install via nix.", cmd),
                        vim.log.levels.ERROR
                    )
                end
            end
        end,
    },
    {
        "zbirenbaum/copilot.lua",
        opts = {
            suggestion = {
                enabled = true,
                auto_trigger = true,
                keymap = {
                    accept = "<M-l>",
                    accept_word = false,
                    accept_line = false,
                    next = "<M-]>",
                    prev = "<M-[>",
                    dismiss = "<C-]>",
                },
            },
            panel = {
                enabled = true,
                auto_refresh = false,
            },
        },
    },
}
