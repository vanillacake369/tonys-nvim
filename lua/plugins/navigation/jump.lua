return {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = function()
        return require("config.keymaps").bind("jump")
    end,
}
