return {
    {
        "folke/trouble.nvim",
        opts = {},
        cmd = "Trouble",
        keys = function()
            return require("config.keymaps").bind("diagnostics")
        end,
    },
}
