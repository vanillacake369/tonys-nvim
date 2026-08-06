return {
    "brianhuster/live-preview.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = { "LivePreview" },
    ft = { "markdown", "mdx", "html", "htm", "asciidoc", "adoc", "svg" },
    keys = {
        { "<leader>mp", "<cmd>LivePreview start<cr>", desc = "Browser live preview" },
        { "<leader>mq", "<cmd>LivePreview close<cr>", desc = "Stop browser live preview" },
    },
    opts = {
        port = 5500,
        browser = "default",
        dynamic_root = false,
        sync_scroll = true,
        picker = "snacks",
        address = "127.0.0.1",
    },
    config = function(_, opts)
        require("livepreview.config").set(opts)
    end,
}
