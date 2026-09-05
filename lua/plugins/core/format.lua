return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    keys = function()
        -- PERF: code group 중 format key 만 conform lazy trigger 로 사용.
        return require("config.keymaps").bind({
            group = "code",
            filter = function(item)
                return item[1] == "<leader>cf"
            end,
        })
    end,
    opts = function(_, opts)
        opts = opts or {}
        -- NOTE: shared formatter defaults cover cross-language cases like
        -- injected code blocks.
        local indent = 4
        local columnLimit = 85

        -- NOTE: Java clang-format style is reused by full-buffer and range
        -- formatting args.
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
            -- NOTE: yamlfmt keeps document markers, blank lines, comments, and
            -- sequence indentation stable for Kubernetes and Helm manifests.
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
            -- NOTE: clang-format-java is an alias that keeps Java style isolated
            -- from C/C++ clang-format defaults.
            --
            -- WARN: ReflowComments must stay disabled so inline JavaDoc tags like
            -- {@link Type#method(...)} are not wrapped or shortened.
            -- NOTE: clang-format-java 는 conform 빌트인이 아니므로
            -- prepend_args 가 병합되지 않아 --style 은 args 에 직접 둔다.
            -- PERF: inherit=false avoids a repeated builtin formatter lookup.
            -- NOTE: range_args passes offset/length directly so visual-mode
            -- formatting does not fall back to whole-buffer diff trimming.
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
            -- NOTE: sync format_on_save writes once before save. format_after_save
            -- writes twice and can double-trigger webpack/esbuild watchers.
            format_on_save = {
                -- PERF: ruff_fix + ruff_organize_imports + ruff_format 마진.
                timeout_ms = 2500,
                lsp_format = "never",
            },
            formatters_by_ft = opts.formatters_by_ft or {},

            formatters = vim.tbl_deep_extend("force", default_formatters, opts.formatters or {}),
        }
    end,
}
