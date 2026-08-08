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
        opts = {},
    },
}
