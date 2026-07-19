return {
    {
        "folke/trouble.nvim",
        opts = {},
        cmd = "Trouble",
        keys = function()
            return require("config.keymaps").get_keys("diagnostics")
        end,
    },
}
