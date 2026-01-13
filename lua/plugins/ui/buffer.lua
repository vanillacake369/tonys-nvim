return {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = function()
        return require("config.keymaps").get_keys("buffer")
    end,
    opts = function(_, opts)
        opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
            close_command = function(n) Snacks.bufdelete(n) end,
            diagnostics = "nvim_lsp",
            offsets = {
                {
                    filetype = "neo-tree",
                    text = "Neo-tree",
                    highlight = "Directory",
                    text_align = "left",
                },
                {
                    filetype = "snacks_layout_box",
                },
            },
            always_show_bufferline = false,
        })
    end,
}
