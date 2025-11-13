-- Neovim Configuration Entry Point
-- Set leader key FIRST before any plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load core configuration
require("config.keybinds")
require("config.settings")
require("config.lazy")
