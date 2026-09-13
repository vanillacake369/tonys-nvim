return {
    -- docker-compose YAML 전용 LSP 를 공통 lspconfig 서버 목록에 등록한다.
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.docker_compose_language_service = {
                cmd = { "docker-compose-langserver", "--stdio" },
                filetypes = { "yaml.docker-compose" },
            }
        end,
    },
    -- Dockerfile parser 를 treesitter 공통 설치 목록에 추가한다.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "dockerfile" })
        end,
    },
    -- Dockerfile lint 는 hadolint 로 nvim-lint 에 연결한다.
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.dockerfile = { "hadolint" }
        end,
    },
}
