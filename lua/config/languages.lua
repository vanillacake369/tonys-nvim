local M = {}

M.languages = {
    python = {
        lsp_server = "pylsp",
        lsp_opts = {
            cmd = { "pylsp" },
            filetypes = { "python" },
        },
        treesitter = {
            "python",
            "ninja",
            "rst",
        },
        linters = { "ruff" },
        formatters = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
    },
    java = {
        -- 명시적 filetype: lang_name fallback 우연한 일치에 의존하지 않도록
        filetypes = { "java" },
        treesitter = {
            "java",
        },
        -- NOTE :
        -- google-java-format 사용할 수 있으나
        -- method chaining 에 대해 new line 설정을
        -- 처리할 수 없어서 clang-format 으로 우회
        -- (별칭 clang-format-java: c_cpp 와 옵션 충돌 방지)
        formatters = { "clang-format-java" },
    },
    c_cpp = {
        lsp_server = "clangd",
        lsp_opts = {
            -- query-driver: clangd 가 시스템 컴파일러를 신뢰하도록 whitelist 한 경로.
            -- 순서는 우선순위 아님 — 매칭되는 모든 항목을 허용.
            -- Nix: *-clang-* / *-gcc-* 로 좁혀 store 전체 트리 스캔 회피.
            -- macOS Xcode CLT: /usr/bin/clang
            -- macOS Homebrew (Apple Silicon): /opt/homebrew/bin/{clang,gcc}
            -- 비-Nix Linux: /usr/bin/gcc, /usr/local/bin/gcc
            cmd = {
                "clangd",
                "--query-driver=/nix/store/*-clang-*/bin/clang,/nix/store/*-gcc-*/bin/cc,/usr/bin/clang,/opt/homebrew/bin/clang,/opt/homebrew/bin/gcc,/usr/bin/gcc,/usr/local/bin/gcc",
            },
            filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
        },
        treesitter = {
            "c",
            "cpp",
        },
    },
    yaml = {
        lsp_server = "yamlls",
        lsp_opts = {
            cmd = { "yaml-language-server", "--stdio" },
            filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
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
                },
            },
        },
        treesitter = {
            "yaml",
        },
        formatters = { "prettier", "yamlfmt" },
    },
    go = {
        lsp_server = "gopls",
        lsp_opts = {
            cmd = { "gopls" },
            filetypes = { "go", "gomod", "gowork", "gotmpl" },
            settings = {
                gopls = {
                    usePlaceholders = true,
                    completeUnimported = true,
                    staticcheck = true,
                },
            },
        },
        treesitter = {
            "go",
            "gomod",
            "gowork",
            "gosum",
        },
        linters = { "golangcilint" },
        formatters = { "goimports", "gofmt" },
    },
    javascript = {
        lsp_server = "ts_ls",
        lsp_opts = {
            cmd = { "typescript-language-server", "--stdio" },
            filetypes = {
                "javascript",
                "javascriptreact",
                "javascript.jsx",
                "typescript",
                "typescriptreact",
                "typescript.tsx",
            },
        },
        treesitter = {
            "javascript",
            "typescript",
            "tsx",
        },
        linters = { "biomejs" },
        formatters = { "biome" },
    },
    nix = {
        lsp_server = "nixd",
        lsp_opts = {
            cmd = { "nixd" },
            filetypes = { "nix" },
            settings = {
                nixd = {
                    -- nixd 가 "nixpkgs" toplevel 로 해석할 표현식.
                    -- 이전엔 `getFlake(toString ./.)` 로 CWD 가 flake root 라고 가정 → non-flake silent fail.
                    -- `<nixpkgs>` 도 NIX_PATH 의존 → macOS Spotlight/Launcher 로 nvim 실행 시 NIX_PATH 비어 fail.
                    -- 글로벌 flake registry (home-manager 가 pin) 경유가 모든 launch context 에서 안전.
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
        },
        treesitter = { "nix" },
        linters = { "statix", "deadnix" },
        formatters = { "alejandra" },
    },
    lua = {
        lsp_server = "lua_ls",
        lsp_opts = {
            cmd = { "lua-language-server" },
            filetypes = { "lua" },
        },
        treesitter = {
            "lua",
        },
        linters = { "selene" },
        formatters = { "stylua" },
    },
    terraform = {
        lsp_server = "terraformls",
        lsp_opts = {
            cmd = { "terraform-ls", "serve" },
            filetypes = { "terraform", "terraform-vars" },
        },
        treesitter = {
            "terraform",
            "hcl",
        },
        linters = { "tflint" },
        formatters = { "terraform_fmt" },
    },
    bash = {
        lsp_server = "bashls",
        lsp_opts = {
            cmd = { "bash-language-server", "start" },
            filetypes = { "sh", "bash" },
        },
        treesitter = {
            "bash",
        },
        linters = { "shellcheck" },
        formatters = { "shfmt" },
    },
    just = {
        lsp_server = "just_lsp",
        lsp_opts = {
            cmd = { "just-lsp" },
            filetypes = { "just" },
            offset_encoding = "utf-8",
            capabilities = {
                offsetEncoding = { "utf-8" },
            },
        },
        treesitter = {
            "just",
        },
        formatters = { "just" },
    },
    html = {
        lsp_server = "html",
        lsp_opts = {
            cmd = { "vscode-html-language-server", "--stdio" },
            filetypes = { "html", "templ" },
        },
        treesitter = {
            "html",
        },
        formatters = { "prettier" },
    },
    css = {
        lsp_server = "cssls",
        lsp_opts = {
            cmd = { "vscode-css-language-server", "--stdio" },
            filetypes = { "css", "scss", "less" },
        },
        treesitter = {
            "css",
        },
        formatters = { "prettier" },
    },
    json = {
        lsp_server = "jsonls",
        lsp_opts = {
            cmd = { "vscode-json-language-server", "--stdio" },
            filetypes = { "json", "jsonc" },
        },
        treesitter = {
            "json",
            "json5",
        },
        formatters = { "prettier" },
    },
    docker = {
        lsp_server = "docker_compose_language_service",
        lsp_opts = {
            cmd = { "docker-compose-langserver", "--stdio" },
            filetypes = { "yaml.docker-compose" },
        },
        -- hadolint 은 Dockerfile 대상이므로 lsp_opts.filetypes 와 별도 지정
        filetypes = { "dockerfile" },
        treesitter = {
            "dockerfile",
        },
        linters = { "hadolint" },
    },
    helm = {
        -- nvim 기본에 helm filetype 이 없어 명시적으로 매핑
        filetypes = { "helm" },
        treesitter = {
            "helm",
        },
        formatters = { "prettier" },
    },
    markdown = {
        treesitter = {
            "markdown",
            "markdown_inline",
        },
        formatters = { "prettier" },
    },
    other = {
        treesitter = {
            "query",
            "regex",
            "vim",
        },
    },
}

--- 범용 수집 함수 (Helper)
local function collect_config(key, is_list)
    local result = {}
    for lang_name, config in pairs(M.languages) do
        local data = config[key]
        if data then
            if is_list then
                -- data가 테이블인지 확인하여 LSP 에러 방지
                if type(data) == "table" then
                    for _, v in ipairs(data) do
                        table.insert(result, v)
                    end
                end
            else
                -- filetype 매핑 우선순위:
                --   1) config.filetypes (linter/formatter 가 lsp filetypes 와 다를 때)
                --   2) config.lsp_opts.filetypes
                --   3) lang_name (fallback)
                local fts = config.filetypes or (config.lsp_opts and config.lsp_opts.filetypes) or { lang_name }
                for _, ft in ipairs(fts) do
                    result[ft] = data
                end
            end
        end
    end
    return result
end

-- 1. LSP: { [filetype] = opts } 매핑 반환 (lsp_server가 있는 경우만)
function M.collect_lsp_servers()
    local servers = {}
    for _, config in pairs(M.languages) do
        if config.lsp_server then
            servers[config.lsp_server] = config.lsp_opts or {}
        end
    end
    return servers
end

-- 2. Treesitter: 모든 파서 이름을 하나의 리스트로 반환
function M.collect_treesitter_parsers()
    return collect_config("treesitter", true)
end

-- 3. Linters: { [filetype] = { linter1, ... } } 매핑 반환
function M.collect_linters()
    return collect_config("linters", false)
end

-- 4. Formatters: { [filetype] = { fmt1, ... } } 매핑 반환
function M.collect_formatters()
    return collect_config("formatters", false)
end

return M
