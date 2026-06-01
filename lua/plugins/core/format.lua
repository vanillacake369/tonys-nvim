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
        local columnLimit = 85

        -- Java clang-format style 공통 문자열
        -- (args 와 range_args 양쪽에서 재사용되므로 변수로 추출)
        local java_style = "{ "
            .. "BasedOnStyle: Google, "
            .. "Language: Java, "
            .. "IndentWidth: "
            .. indent
            .. ", "
            .. "ColumnLimit: "
            .. columnLimit
            .. ", "
            .. "ContinuationIndentWidth: "
            .. indent
            .. ", "
            .. "BinPackParameters: false, "
            .. "BinPackArguments: false, "
            .. "AlignAfterOpenBracket: Align, "
            .. "AllowAllParametersOfDeclarationOnNextLine: false, "
            .. "AlwaysBreakAfterReturnType: None, "
            .. "ReflowComments: Never"
            .. " }"
        local default_formatters = {
            injected = {
                options = { ignore_errors = true },
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
                    "width=" .. columnLimit,
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
            -- Java: clang-format 우회 (별칭으로 분리해 c_cpp 와 옵션 격리)
            -- ReflowComments: Never 는 {@link Type#method(...)} 같은 JavaDoc 인라인 태그가
            -- ColumnLimit 을 넘어도 줄바꿈/축약하지 않도록 보호하는 핵심 옵션.
            -- NOTE: clang-format-java 는 conform 빌트인이 아니므로 prepend_args 가 병합되지
            -- 않는다. --style 옵션을 args 배열 안에 직접 포함해야 한다.
            -- inherit=false: 동명의 builtin 이 없으므로 매 호출마다 발생하는 pcall lookup 제거.
            -- range_args: visual-mode 부분 포맷이 전체 버퍼 reformat → diff trim 으로 fallback
            -- 되지 않도록 --offset/--length 직접 전달.
            ["clang-format-java"] = {
                inherit = false,
                command = "clang-format",
                args = {
                    "--style",
                    java_style,
                    "-assume-filename",
                    "$FILENAME",
                },
                range_args = function(_, ctx)
                    local util = require("conform.util")
                    local start_offset, end_offset = util.get_offsets_from_range(ctx.buf, ctx.range)
                    return {
                        "--style",
                        java_style,
                        "-assume-filename",
                        "$FILENAME",
                        "--offset",
                        tostring(start_offset),
                        "--length",
                        tostring(end_offset - start_offset),
                    }
                end,
                stdin = true,
            },
            -- Sh/Bash: shfmt
            ["shfmt"] = {
                prepend_args = { "-i", tostring(indent) },
            },
        }

        return {
            notify_on_error = true,
            default_format_opts = {
                timeout_ms = 3000,
                async = false,
                quiet = false,
                lsp_format = "never",
            },
            -- sync 포맷터: 저장 전 실행 → 디스크 write 1회, 외부 file watcher 안전
            -- (format_after_save 는 async 지만 디스크에 두 번 쓰여 webpack/esbuild 등
            --  외부 watcher 가 더블 트리거됨)
            format_on_save = {
                -- 2500ms: ruff_fix + ruff_organize_imports + ruff_format 체인 마진 확보
                timeout_ms = 2500,
                lsp_format = "never",
            },
            -- 파일 타입별 포맷터 매핑을 languages.lua에서 자동으로 가져옴
            formatters_by_ft = lang.collect_formatters(),

            formatters = default_formatters,
        }
    end,
}
