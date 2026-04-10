return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    keys = function()
        return require("config.keymaps").get_keys("code")
    end,
    opts = function()
        local lang = require("config.languages")

        -- 모든 언어에 공통으로 적용될 기본 포맷터 설정
        -- (예: 코드 블록 내 주입된 코드 포맷팅)
        -- NOTE : indent 는 가시성을 위해 4 로 통일(alejandra 는 조작불가)
        local indent = 4
        local default_formatters = {
            injected = {
                options = { ignore_errors = true },
            },
            -- Java: google-java-format
            ["google-java-format"] = {
                prepend_args = { "--aosp" },
            },
            -- Lua: stylua
            ["stylua"] = {
                prepend_args = { "--indent-type", "Spaces", "--indent-width", tostring(indent) },
            },
            -- JS/TS/HTML: prettier
            ["prettier"] = {
                prepend_args = { "--tab-width", tostring(indent) },
            },
            -- C/C++: clang-format
            ["clang-format"] = {
                prepend_args = { "--style", "{IndentWidth: " .. indent .. "}" },
            },
            -- Sh/Bash: shfmt
            ["shfmt"] = {
                prepend_args = { "-i", tostring(indent) },
            },
        }

        -- languages.lua에서 정의한 언어별 특화 옵션 수집 (SSOT 원칙 준수)
        -- 예: Java의 경우 google-java-format에 --aosp 옵션 주입 등
        local custom_formatters = lang.collect_formatters_opts and lang.collect_formatters_opts() or {}

        -- 기본 설정과 사용자 설정을 병합 (동일한 포맷터 이름이 있을 경우 사용자 설정이 우선됨)
        local final_formatters = vim.tbl_deep_extend("force", default_formatters, custom_formatters)

        return {
            default_format_opts = {
                timeout_ms = 3000,
                async = false,
                quiet = false,
                lsp_format = "fallback",
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_format = "fallback",
            },
            -- 파일 타입별 포맷터 매핑을 languages.lua에서 자동으로 가져옴
            formatters_by_ft = lang.collect_formatters(),

            -- 병합된 최종 포맷터 상세 설정을 적용
            formatters = final_formatters,
        }
    end,
}
