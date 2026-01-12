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
                lualine_style = "stealth",
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
                    theme = 'material',
                    globalstatus = true,
                    component_separators = '', -- 구분선 제거 (깔끔하게)
                    section_separators = '',   -- 구분선 제거
                },
                sections = {
                    lualine_a = { 'mode' },    -- 모드(INSERT/NORMAL)만 표시
                    lualine_b = {},            -- git branch 제거
                    lualine_y = {},            -- progress(5%) 제거
                },
            })
        end
    },
}
