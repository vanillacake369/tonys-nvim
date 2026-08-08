return {
    "nvim-pack/nvim-spectre",
    dependencies = { "folke/trouble.nvim", "nvim-mini/mini.icons" },
    keys = function()
        return require("config.keymaps").bind("search_replace")
    end,
    opts = {},
}
