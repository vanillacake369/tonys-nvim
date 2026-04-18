return {
    "jkeresman01/spring-initializr.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-telescope/telescope.nvim",
    },
    keys = function()
        return require("config.keymaps").get_keys("springInitializr")
    end,
    opts = {},
}
