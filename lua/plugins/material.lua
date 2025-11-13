-- Material Color Scheme
return {
  "marko-cerovac/material.nvim",
  priority = 1000, -- Load before other plugins

  config = function()
    -- Set the material style before setup
    -- Available styles: darker, lighter, oceanic, palenight, deep ocean
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
        strings = {},
        keywords = {},
        functions = {},
        variables = {},
        operators = {},
        types = {},
      },

      plugins = {
        -- Uncomment plugins you use for better integration
        -- "telescope",
        -- "nvim-tree",
        -- "gitsigns",
      },

      disable = {
        colored_cursor = false,
        borders = false,
        background = false, -- Set to true for transparent background
        term_colors = false,
        eob_lines = false,
      },

      lualine_style = "default", -- or "stealth"
      async_loading = true,
    })

    -- Apply the colorscheme
    vim.cmd.colorscheme('material')
  end,
}
