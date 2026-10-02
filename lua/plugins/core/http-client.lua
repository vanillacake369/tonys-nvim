return {
    "rest-nvim/rest.nvim",
    ft = "http",
    init = function()
        vim.filetype.add({ extension = { http = "http" } })
    end,
    config = function()
        local keymaps = require("config.keymaps")
        local group = vim.api.nvim_create_augroup("RestNvimBufferKeymaps", { clear = true })

        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            pattern = "*",
            callback = function(args)
                local bindings = keymaps.bind("rest")
                if args.match == "http" then
                    keymaps.bind("rest", { buffer = args.buf })
                else
                    for _, binding in ipairs(bindings) do
                        pcall(vim.keymap.del, binding.mode or "n", binding[1], { buffer = args.buf })
                    end
                end
            end,
        })

        if vim.bo.filetype == "http" then
            keymaps.bind("rest", { buffer = vim.api.nvim_get_current_buf() })
        end
    end,
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            table.insert(opts.ensure_installed, "http")
        end,
    },
}
