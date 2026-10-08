local FORMAT_INDENT_WIDTH = 4
local FORMAT_COLUMN_LIMIT = 85
local PRETTIER_PRINT_WIDTH = 100
local DEFAULT_FORMAT_TIMEOUT_MS = 3000
local FORMAT_ON_SAVE_TIMEOUT_MS = 2500

return {
    -- Conform 으로 LSP format 과 별개인 formatter pipeline 을 통합한다.
    -- 언어별 파일에서 formatters_by_ft 를 확장하고 저장 전 동기 format 을 맡긴다.
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    keys = function()
        -- code group 중 format key 만 conform lazy trigger 로 사용한다.
        return require("config.keymaps").bind({
            group = "code",
            filter = function(item)
                return item[1] == "<leader>cf"
            end,
        })
    end,
    opts = function(_, opts)
        opts = opts or {}
        local formatters_by_ft = opts.formatters_by_ft or {}
        formatters_by_ft.java = function(bufnr)
            return require("config.conventions").formatters(bufnr, "java", { "clang-format-java" })
        end

        -- Java clang-format style 은 full-buffer 와 range formatting args 에서 재사용한다.
        local java_style = "{ "
            .. "BasedOnStyle: Google, "
            .. "Language: Java, "
            .. "IndentWidth: "
            .. FORMAT_INDENT_WIDTH
            .. ", "
            .. "ColumnLimit: "
            .. FORMAT_COLUMN_LIMIT
            .. ", "
            .. "ContinuationIndentWidth: "
            .. FORMAT_INDENT_WIDTH
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
            -- yamlfmt 는 Kubernetes/Helm manifest 의 document marker, 빈 줄,
            -- comment, sequence indentation 을 안정적으로 보존한다.
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
                    "indent=" .. FORMAT_INDENT_WIDTH,
                    "-formatter",
                    "width=" .. FORMAT_COLUMN_LIMIT,
                },
            },
            -- Lua 는 stylua 로 formatting 한다.
            ["stylua"] = {
                prepend_args = {
                    "--indent-type",
                    "Spaces",
                    "--indent-width",
                    tostring(FORMAT_INDENT_WIDTH),
                },
            },
            -- JS/TS/HTML 은 prettier 로 formatting 한다.
            ["prettier"] = {
                prepend_args = {
                    "--tab-width",
                    tostring(FORMAT_INDENT_WIDTH),
                    "--prose-wrap",
                    "preserve",
                    "--print-width",
                    tostring(PRETTIER_PRINT_WIDTH),
                    "--trailing-comma",
                    "all",
                },
            },
            -- clang-format-java 는 C/C++ clang-format 기본값과 Java style 을 분리하는 alias 다.
            -- inline JavaDoc tag 가 wrap 되거나 줄어들지 않도록 ReflowComments 는 반드시 끈다.
            -- conform 빌트인이 아니므로 prepend_args 가 병합되지 않아 --style 은 args 에 직접 둔다.
            -- inherit=false 로 반복적인 builtin formatter lookup 을 피한다.
            -- range_args 는 offset/length 를 직접 넘겨 visual-mode formatting 이 whole-buffer
            -- diff trimming 으로 fallback 하지 않게 한다.
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
                prepend_args = { "-i", tostring(FORMAT_INDENT_WIDTH) },
            },
        }

        return {
            notify_on_error = true,
            default_format_opts = {
                timeout_ms = DEFAULT_FORMAT_TIMEOUT_MS,
                async = false,
                quiet = false,
                lsp_format = "never",
            },
            -- sync format_on_save 는 저장 전에 한 번만 쓴다.
            -- format_after_save 는 두 번 쓸 수 있어 webpack/esbuild watcher 를 중복 trigger 한다.
            format_on_save = {
                -- ruff_fix + ruff_organize_imports + ruff_format 여유 시간이다.
                timeout_ms = FORMAT_ON_SAVE_TIMEOUT_MS,
                lsp_format = "never",
            },
            formatters_by_ft = formatters_by_ft,

            formatters = vim.tbl_deep_extend("force", default_formatters, opts.formatters or {}),
        }
    end,
}
