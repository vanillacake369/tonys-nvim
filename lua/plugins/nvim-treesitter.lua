return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    local configs = require("nvim-treesitter.configs")
    configs.setup({
      highlist = {
        enable = true,
      },
      indent = { enable = true },
      autotage = { enable = true }, 
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    })
  end
}
