return {
    -- bufferline 으로 열린 버퍼 목록과 LSP 진단 상태를 상단에 보여준다.
    -- close 동작은 Snacks.bufdelete 로 연결해 window layout 을 덜 흔든다.
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = function()
        return require("config.keymaps").bind("buffer")
    end,
    opts = function(_, opts)
        opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
            close_command = function(n)
                Snacks.bufdelete(n)
            end,
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
