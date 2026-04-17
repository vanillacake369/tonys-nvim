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
        local indent = 4
        local columLimit = 85
        local default_formatters = {
            injected = {
                options = { ignore_errors = true },
            },
            -- Java: google-java-format
            -- aosp: 4칸 들여쓰기
            -- skip-reflow-long-strings: 긴 문자열 자동 줄바꿈 방지
            -- skip-javadoc-formatting: JavaDoc 주석 포맷팅 방해 최소화
            ["google-java-format"] = {
                prepend_args = {
                    "--aosp",
                    "--skip-reflow-long-strings",
                    "--skip-javadoc-formatting",
                },
            },
            -- Yaml: yamlfmt
            -- retain_line_breaks_single -- 빈 줄 하나는 무조건 유지
            -- retain_line_breaks_multi -- 빈 줄 여러 개도 유지
            -- scan_folded_as_literal -- 긴 문자열 가독성 향상
            -- include_document_start -- --- 문서 시작 유지
            -- line-break-after-comment=true -- 주석 뒤에 줄바꿈
            -- preserve-quoted=false -- 불필요한 따옴표 제거
            -- indentless_arrays=false -- 시퀀스(리스트) 들여쓰기
            ["yamlfmt"] = {

                prepend_args = {
                    "-formatter",
                    "retain_line_breaks=true",
                    "-formatter",
                    "retain_line_breaks_single=true",
                    "-formatter",
                    "retain_line_breaks_multi=true",
                    "-formatter",
                    "scan_folded_as_literal=true",
                    "-formatter",
                    "include_document_start=true",
                    "-formatter",
                    "indentless_arrays=false",
                    "-formatter",
                    "line-break-after-comment=true",
                    "-formatter",
                    "preserve-quoted=false",
                    "-formatter",
                    "indent=" .. indent,
                    "-formatter",
                    "width=" .. columLimit,
                },
            },
            -- Toml: taplo
            -- align_entries: = 기호를 정렬하여 가독성 폭발적 향상
            -- reorder_keys: 키 순서 자동 정렬
            -- separate_sections: 섹션 간 빈 줄 강제
            ["taplo"] = {
                args = {
                    "format",
                    "-",
                    "--option",
                    "align_entries=true",
                    "--option",
                    "reorder_keys=true",
                    "--option",
                    "compact_arrays=false",
                    "--option",
                    "separate_sections=true",
                },
            },
            -- Lua: stylua
            ["stylua"] = {
                prepend_args = {
                    "--indent-type",
                    "Spaces",
                    "--indent-width",
                    tostring(indent),
                },
            },
            -- JS/TS/HTML: prettier
            ["prettier"] = {
                prepend_args = {
                    "--tab-width",
                    tostring(indent),
                    "--prose-wrap",
                    "preserve",
                    "--print-width",
                    "100",
                    "--trailing-comma",
                    "all",
                },
            },
            -- C/C++: clang-format
            ["clang-format"] = {
                prepend_args = {
                    "--style",
                    "{ "
                        .. "BasedOnStyle: Google, "
                        .. "IndentWidth: "
                        .. indent
                        .. ", "
                        .. "ColumnLimit: "
                        .. columLimit
                        .. ", "
                        .. "ContinuationIndentWidth: "
                        .. indent
                        .. ", "
                        .. "BinPackParameters: false, "
                        .. "BinPackArguments: false, "
                        .. "AlignAfterOpenBracket: Align,"
                        .. "AllowAllParametersOfDeclarationOnNextLine: true, "
                        .. "AlwaysBreakAfterReturnType: None, "
                        .. "AlwaysBreakAfterDefinitionReturnType: None, "
                        .. "DerivePointerAlignment: false, "
                        .. "Language: Java"
                        .. " }",
                },
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
            notify_on_error = true,
            default_format_opts = {
                timeout_ms = 3000,
                async = false,
                quiet = false,
                lsp_format = "never",
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_format = "never",
            },
            -- 파일 타입별 포맷터 매핑을 languages.lua에서 자동으로 가져옴
            formatters_by_ft = lang.collect_formatters(),

            -- 병합된 최종 포맷터 상세 설정을 적용
            formatters = final_formatters,
        }
    end,
}
