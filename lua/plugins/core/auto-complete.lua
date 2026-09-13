-- snippet, ghost text, signature help 를 포함한 IDE형 completion 을 구성한다.

local DOCUMENTATION_AUTO_SHOW_DELAY_MS = 200
local COPILOT_SCORE_OFFSET = 100
local LAZYDEV_SCORE_OFFSET = 100

return {
    -- blink.cmp 로 LSP/snippet/path/buffer/Copilot completion 을 한 메뉴에 모은다.
    -- insert 진입 시 로드해 IDE 같은 자동완성 경험만 필요한 순간에 붙인다.
    {
        "saghen/blink.cmp",
        version = "1.*",
        event = "InsertEnter",
        dependencies = {
            "rafamadriz/friendly-snippets",
            "folke/lazydev.nvim",
            "fang2hou/blink-copilot",
        },

        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            -- C-y 는 completion 확정으로 쓰고 Enter 는 줄바꿈으로 남긴다.
            keymap = {
                preset = "none",
                ["<CR>"] = { "fallback" },
                ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
                -- iPad 와 혼용하기 위해 accept 는 C-y 로 고정한다.
                ["<C-y>"] = { "show", "accept", "fallback" },
                ["<C-Space>"] = { "show", "accept", "fallback" },
                ["<C-e>"] = { "hide", "fallback" },
                ["<C-d>"] = { "scroll_documentation_down", "fallback" },
                ["<C-u>"] = { "scroll_documentation_up", "fallback" },
                ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
            },

            appearance = {
                nerd_font_variant = "mono",
            },

            -- Completion 표시 설정
            completion = {
                -- Documentation 은 지연 후 자동으로 표시한다.
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = DOCUMENTATION_AUTO_SHOW_DELAY_MS,
                    window = {
                        border = "rounded",
                    },
                },
                -- Ghost text 는 IDE 같은 inline preview 로 보여준다.
                ghost_text = {
                    enabled = true,
                    show_with_selection = true,
                    show_without_selection = false,
                    show_with_menu = true,
                    show_without_menu = true,
                },
                -- Completion menu 의 표시 column 을 고정한다.
                menu = {
                    border = "rounded",
                    draw = {
                        columns = {
                            { "kind_icon" },
                            { "label", "label_description", gap = 1 },
                            { "source_name" },
                        },
                    },
                },
                -- 확정 동작
                accept = {
                    auto_brackets = { enabled = true },
                },
            },

            -- Signature help 는 함수 parameter 를 보여준다.
            signature = {
                enabled = true,
                trigger = {
                    enabled = true,
                    show_on_trigger_character = true,
                    show_on_insert_on_trigger_character = true,
                },
                window = {
                    border = "rounded",
                    treesitter_highlighting = true,
                    show_documentation = true,
                },
            },

            -- Snippet navigation 은 placeholder 이동을 맡는다.
            snippets = {
                preset = "default",
            },

            -- Source 목록에는 blink.cmp provider 경로를 통해서만 Copilot 을 포함한다.
            sources = {
                default = { "lazydev", "lsp", "path", "snippets", "buffer", "copilot" },
                providers = {
                    copilot = {
                        name = "copilot",
                        module = "blink-copilot",
                        score_offset = COPILOT_SCORE_OFFSET,
                        async = true,
                    },
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = LAZYDEV_SCORE_OFFSET,
                    },
                },
            },

            -- Fuzzy matching 구현체는 Rust backend 를 우선 사용한다.
            fuzzy = {
                implementation = "prefer_rust_with_warning",
            },
        },
        opts_extend = { "sources.default" },
    },
    -- 괄호/따옴표 pair 를 입력 중 자동으로 닫아 scratch coding 속도를 높인다.
    -- completion 과 같은 InsertEnter 시점에만 로드한다.
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },
    -- HTML/JSX 계열 태그 rename/close 를 treesitter 기반으로 맞추기 위해 추가.
    -- 파일을 열 때 붙여 웹 파일 편집 중 태그 불일치를 줄인다.
    {
        "windwp/nvim-ts-autotag",
        event = { "BufReadPost", "BufNewFile" },
        opts = {},
    },
    -- 세미콜론/마침표/콤마를 줄 끝으로 보내는 insert-mode 보조 동작을 추가.
    -- 문장 끝 punctuation 을 커서 이동 없이 입력하기 위한 작은 생산성 플러그인이다.
    {
        "rareitems/put_at_end.nvim",
        config = function()
            local pae = require("put_at_end")
            vim.keymap.set("i", "<C-;>", pae.put_semicolon, { desc = "Semicolon at end" })
            vim.keymap.set("i", "<C-.>", pae.put_period, { desc = "Period at end" })
            vim.keymap.set("i", "<C-,>", pae.put_comma, { desc = "Comma at end" })
        end,
    },
}
