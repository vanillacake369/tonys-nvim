return {
    {
        "marko-cerovac/material.nvim",
        priority = 1000,
        config = function()
            vim.g.material_style = "darker"
            require('material').setup({
                contrast = {
                    terminal = false,
                    sidebars = false,
                    floating_windows = false,
                    cursor_line = false,
                    lsp_virtual_text = false,
                    non_current_windows = false,
                    filetypes = {},
                },
                styles = {
                    comments = { italic = true },
                },
                disable = {
                    background = false,
                },
                lualine_style = "default",
                async_loading = true,
            })
            vim.cmd.colorscheme('material')
        end,
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('lualine').setup({
                options = {
                    theme = "material"
                }
            })
        end
    },
}
