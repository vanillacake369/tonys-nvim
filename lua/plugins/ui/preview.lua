return {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    ft = { "markdown", "mdx" },
    opts = {
        file_types = { "markdown", "mdx" },
        render_modes = { "n", "c", "t" },
        max_file_size = 10.0,
    },
}
