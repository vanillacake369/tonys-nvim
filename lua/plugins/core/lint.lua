return {
    -- formatter 와 분리된 lint 진단을 파일타입별로 붙이기 위해 추가.
    -- 언어별 플러그인 파일에서 linters_by_ft 를 확장해 공통 실행 흐름을 쓴다.
    {
        "mfussenegger/nvim-lint",
        event = { "BufWritePost", "BufReadPost" },
        opts = {
            linters_by_ft = {},
        },
        config = function(_, opts)
            local lint = require("lint")
            local conventions = require("config.conventions")

            local function default_linters_for_ft(ft)
                local names = lint.linters_by_ft[ft]
                if names then
                    return names
                end

                local deduped = {}
                local result = {}
                for _, part in ipairs(vim.split(ft, ".", { plain = true })) do
                    for _, name in ipairs(lint.linters_by_ft[part] or {}) do
                        if not deduped[name] then
                            deduped[name] = true
                            table.insert(result, name)
                        end
                    end
                end
                return result
            end

            local heavy_filetypes = {
                go = true,
                terraform = true,
                ["terraform-vars"] = true,
            }

            local function try_lint_current_buffer(event)
                local ft = vim.bo.filetype
                local fallback = default_linters_for_ft(ft)
                local names = conventions.linters(0, ft, fallback)
                if not names or vim.tbl_isempty(names) then
                    return
                end

                -- 대형 프로젝트를 탐색하는 linter는 저장 시에만 실행한다.
                -- Go/Terraform은 LSP가 입력 중 실시간 피드백을 담당한다.
                if heavy_filetypes[ft] and event ~= "BufWritePost" then
                    return
                end

                -- InsertLeave는 등록하지 않는다. 편집 중 진단은 LSP가 담당한다.
                lint.try_lint(names)
            end

            -- yamllint 는 repo-local 설정 파일을 강제해 manifest lint 결과를 맞춘다.
            lint.linters.yamllint.args = {
                "-c",
                vim.fn.stdpath("config") .. "/.yamllint",
                "--format",
                "parsable",
                "-",
            }

            -- selene 은 Neovim Lua 전용 설정으로 noisy output 을 줄여 표시한다.
            lint.linters.selene.args = {
                "--display-style",
                "quiet",
                "--config",
                vim.fn.stdpath("config") .. "/selene.toml",
                "-",
            }

            lint.linters_by_ft = opts.linters_by_ft or {}

            -- 외부 linter는 파일 열기 또는 저장 후에만 실행한다.
            vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
                group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
                callback = function(args)
                    try_lint_current_buffer(args.event)
                end,
            })
        end,
    },
}
