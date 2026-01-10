vim.opt.clipboard = "unnamedplus"

local clipboard_cache = { "", "" }

vim.g.clipboard = {
    name = "OSC 52",
    copy = {
        ["+"] = function(lines, regtype)
            clipboard_cache = { lines, regtype }
            require("vim.ui.clipboard.osc52").copy("+")(lines, regtype)
        end,
        ["*"] = function(lines, regtype)
            clipboard_cache = { lines, regtype }
            require("vim.ui.clipboard.osc52").copy("*")(lines, regtype)
        end,
    },
    paste = {
        ["+"] = function() return clipboard_cache end,
        ["*"] = function() return clipboard_cache end,
    },
}
