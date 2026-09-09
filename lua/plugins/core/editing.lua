return {
    {
        "numToStr/Comment.nvim",
        keys = function()
            return require("config.keymaps").bind("comment")
        end,
        opts = {},
    },
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
            },
        },
    },
    {
        "junegunn/vim-easy-align",
        event = "VeryLazy",
        keys = function()
            return require("config.keymaps").bind("align")
        end,
        config = function() end,
    },
    {
        "mg979/vim-visual-multi",
    },
}
