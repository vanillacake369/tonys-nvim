return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        win = {
            border = "rounded", 
            title = true,      
            title_pos = "center", 
            padding = { 2, 2 }, 
        },
        spec = {
            { "<leader>b", group = "[Buffer]" },
            { "<leader>c", group = "[Code]" },
            { "<leader>f", group = "[Find]" },
            { "<leader>u", group = "[UI]" },
            { "<leader>w", group = "[Window]" },
        },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer Local Keymaps (which-key)",
        },
    },
    config = function(_, opts)
        local wk = require("which-key")
        wk.setup(opts)
        -- local material_blue = "#26C6DA"
        -- local material_green = "#66BB6A"
        -- vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = material_green })
        -- vim.api.nvim_set_hl(0, "WhichKeyTitle", { fg = material_green, bold = true })
    end,
}
