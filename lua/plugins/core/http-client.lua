local REST_RESPONSE_FORMATTERS = {
    json = { "prettier --parser json" },
    jsonc = { "prettier --parser json" },
    html = { "prettier --parser html" },
    css = { "prettier --parser css" },
    javascript = { "prettier --parser babel" },
    xml = { "xmllint --format -", "prettier --parser xml" },
}

local function set_response_formatprg(args)
    local candidates = REST_RESPONSE_FORMATTERS[args.match]
    if not candidates then
        return
    end

    for _, formatprg in ipairs(candidates) do
        local executable = formatprg:match("^%S+")
        if executable and vim.fn.executable(executable) == 1 then
            vim.bo[args.buf].formatprg = formatprg
            return
        end
    end
end

return {
    "rest-nvim/rest.nvim",
    ft = "http",
    init = function()
        vim.filetype.add({ extension = { http = "http" } })
    end,
    config = function()
        local keymaps = require("config.keymaps")
        local group = vim.api.nvim_create_augroup("RestNvimBufferKeymaps", { clear = true })
        local format_group = vim.api.nvim_create_augroup("RestNvimResponseFormatprg", { clear = true })

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

        vim.api.nvim_create_autocmd("FileType", {
            group = format_group,
            pattern = vim.tbl_keys(REST_RESPONSE_FORMATTERS),
            callback = set_response_formatprg,
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
