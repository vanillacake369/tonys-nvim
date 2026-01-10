return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      { "<leader>b", group = "[Buffer]" },
      { "<leader>c", group = "[Code]" },
      { "<leader>f", group = "[Find]" },
      { "<leader>u", group = "[UI]" },
      { "<leader>w", group = "[Window]" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
