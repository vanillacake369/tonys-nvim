return {}

-- Ayu Color Scheme (Replaced by Material theme - see material.lua)
--[[
return {
  "Shatur/neovim-ayu",
  priority = 1000, -- Load before other plugins

  config = function()
    require('ayu').setup({
      mirage = false, -- Set to true for ayu-mirage variant
      terminal = true, -- Enable terminal colors

      overrides = {
        -- Example: Transparent background
        -- Normal = { bg = "None" },
        -- NormalFloat = { bg = "None" },
        -- ColorColumn = { bg = "None" },
        -- SignColumn = { bg = "None" },

        -- Example: Custom highlight colors
        -- Comment = { fg = "#5C6773", italic = true },
      },
    })

    -- Apply the colorscheme
    vim.cmd.colorscheme('ayu-dark')
  end,
}
--]]
