return {
    -- 일반/visual 모드 주석 토글을 안정적으로 처리하기 위해 추가.
    -- keymap 정의는 config.keymaps 의 comment 그룹으로 모아둔다.
    {
        "numToStr/Comment.nvim",
        keys = function()
            return require("config.keymaps").bind("comment")
        end,
        opts = {},
    },
    -- 코드 안 TODO/FIXME 류 메모를 하이라이트하고 검색하기 위해 추가.
    -- 프로젝트에서 쓰는 TIP/IMPORTANT/COMPAT 같은 태그도 같은 흐름에 태운다.
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        event = { "BufReadPost", "BufNewFile" },
        keys = function()
            return require("config.keymaps").bind("todo")
        end,
        opts = {
            keywords = {
                TIP = { icon = "💡", color = "info", alt = { "HINT", "IDEA", "SUGGEST" } },
                IMPORTANT = { icon = "❗", color = "hint", alt = { "REQUIRED", "CRITICAL", "CHECK" } },
                CAUTION = { icon = "⚠️", color = "warning", alt = { "WARNING", "BEWARE", "DANGER" } },
                VERSION = { icon = "📌", color = "test", alt = { "V_", "TAG", "MIGRATE" } },
                DEBUG = { icon = "🐞", color = "default", alt = { "BUG", "TEST", "TRACE" } },
                COMPAT = { icon = "🔄", color = "default", alt = { "LEGACY", "BACKWARD" } },
            },
        },
    },
    -- visual 영역이나 표 형태 코드를 기준 문자에 맞춰 정렬하기 위해 추가.
    -- 실제 keymap 은 align 그룹에서 lazy-load trigger 로 연결한다.
    {
        "junegunn/vim-easy-align",
        event = "VeryLazy",
        keys = function()
            return require("config.keymaps").bind("align")
        end,
        config = function() end,
    },
    -- 선택한 visual-block 에 따라
    -- multi cursor 를 만들어주는 플러그인
    {
        "mg979/vim-visual-multi",
    },
}
