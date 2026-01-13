return {
    {
        "junegunn/vim-easy-align",
        event = "VeryLazy",
        keys = function()
            return require("config.keymaps").get_keys("align")
        end,
        config = function()
        end
    },
}
