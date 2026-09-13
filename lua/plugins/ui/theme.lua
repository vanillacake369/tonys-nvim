return {
    -- Material colorscheme 을 기본 테마로 고정하고 lualine 과 톤을 맞춘다.
    -- darker variant 와 non-current window contrast 로 focus 영역을 분리한다.
    {
        "marko-cerovac/material.nvim",
        priority = 1000,
        config = function()
            vim.g.material_style = "darker"
            require("material").setup({
                contrast = {
                    terminal = false,
                    sidebars = false,
                    floating_windows = false,
                    cursor_line = true,
                    lsp_virtual_text = false,
                    -- non_current_windows 는 focus 가 없는 window 에 대비 배경을 적용한다.
                    non_current_windows = true,
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
            vim.cmd.colorscheme("material")
        end,
    },
    -- lualine 으로 mode, fullscreen 상태, harpoon mark 를 얇은 statusline 에 표시한다.
    -- progress 등 시끄러운 기본 섹션은 비워 작업 집중도를 높인다.
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local function fullscreen()
                local ok, window = pcall(require, "plugins.navigation.window")
                return ok and window.is_fullscreen() and "F" or ""
            end

            require("lualine").setup({
                options = {
                    theme = "material",
                    globalstatus = true,
                    -- statusline 을 얇게 유지하기 위해 구분선을 제거한다.
                    component_separators = "",
                    section_separators = "",
                },
                sections = {
                    -- mode 와 fullscreen 여부만 왼쪽에 짧게 노출하고 progress 는 숨긴다.
                    lualine_a = { "mode" },
                    lualine_b = { fullscreen },
                    lualine_c = { "harpoon2" },
                    lualine_y = {},
                },
            })
        end,
    },
    -- Harpoon mark 를 lualine component 로 노출하기 위해 추가.
    -- navigation/marks.lua 의 harpoon2 상태를 statusline 에 재사용한다.
    {
        "letieu/harpoon-lualine",
        dependencies = {
            {
                "ThePrimeagen/harpoon",
                branch = "harpoon2",
            },
        },
    },
}
