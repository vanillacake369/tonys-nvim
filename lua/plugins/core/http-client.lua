return {
    "rest-nvim/rest.nvim",
    keys = function()
        return require("config.keymaps").bind("rest")
    end,
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            table.insert(opts.ensure_installed, "http")
        end,
    },
}
