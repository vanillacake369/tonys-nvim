vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Window splits
vim.keymap.set("n", "<leader>w-", "<C-w>s", { desc = "[Window] Split Below" })
vim.keymap.set("n", "<leader>w|", "<C-w>v", { desc = "[Window] Split Right" })
