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
		formatters = { "ruff_format", "black" },
	},
	java = {
		lsp_server = "jdtls",
		lsp_opts = {
			cmd = { "jdtls" },
			filetypes = { "java" },
		},
		treesitter = {
			"java",
		},
		formatters = { "google-java-format" },
	},
	c_cpp = {
		lsp_server = "clangd",
		lsp_opts = {
			cmd = { "clangd" },
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
		linters = { "yamllint" },
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
			filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
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
					-- This expression will be interpreted as "nixpkgs" toplevel
					-- Nixd provides package, lib completion/information from it.
					nixpkgs = {
						expr = "import (builtins.getFlake(toString ./.)).inputs.nixpkgs { }",
					},
					-- Tell the language server your desired option set, for completion
					-- This is lazily evaluated.
					-- options = {
					-- 	nixos = {
					-- 		expr = '(builtins.getFlake(toString ./.)).nixosConfigurations."tony".options',
					-- 	},
					-- 	home_manager = {
					-- 		expr = '(builtins.getFlake(toString ./.)).homeConfigurations."hm-aarch64-darwin".options',
					-- 	},
					-- 	darwin = {
					-- 		expr = '(builtins.getFlake(toString ./.)).darwinConfigurations."tony-aarch64-darwin".options',
					-- 	},
					-- },
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
		treesitter = {
			"dockerfile",
		},
		linters = { "hadolint" },
	},
	helm = {
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
				-- filetype별 매핑: lsp_opts.filetypes 우선, 없으면 lang_name 사용
				local fts = (config.lsp_opts and config.lsp_opts.filetypes) or { lang_name }
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
