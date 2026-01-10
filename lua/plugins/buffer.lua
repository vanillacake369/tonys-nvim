return {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
        { "<leader>bdc", function() Snacks.bufdelete() end, desc = "[Buffer] Delete Current" },
        { "<leader>bda", function() Snacks.bufdelete.all() end, desc = "[Buffer] Delete All" },
        { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "[Buffer] Toggle Pin" },
        { "<leader>bdP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "[Buffer] Delete Non-Pinned" },
        { "<leader>bdr", "<Cmd>BufferLineCloseRight<CR>", desc = "[Buffer] Delete Right" },
        { "<leader>bdl", "<Cmd>BufferLineCloseLeft<CR>", desc = "[Buffer] Delete Left" },
        { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
        { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
        { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
        { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
        { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move Buffer Prev" },
        { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move Buffer Next" },
    },
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
