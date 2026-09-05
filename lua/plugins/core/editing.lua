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
                COMPAT = { icon = "C ", color = "hint", alt = { "VERSION" } },
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
