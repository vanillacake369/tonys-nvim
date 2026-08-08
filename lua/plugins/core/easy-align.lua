return {
    {
        "junegunn/vim-easy-align",
        event = "VeryLazy",
        keys = function()
            return require("config.keymaps").bind("align")
        end,
        config = function() end,
    },
}
