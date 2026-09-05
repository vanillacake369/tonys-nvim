-- NOTE: disable unnamed clipboard so normal-mode c/cc/d/dd do not overwrite
-- the system clipboard. Deletes use the black-hole register instead.
vim.keymap.set("n", "d", '"_d')
vim.keymap.set("n", "dd", '"_dd')

-- NOTE: enable explicit system clipboard access through +/* registers.
vim.opt.clipboard = "unnamedplus"

-- NOTE: choose the clipboard provider by launch platform.
if vim.fn.has("mac") == 1 then
    -- NOTE: macOS uses pbcopy/pbpaste.
    vim.g.clipboard = {
        name = "macOS-clipboard",
        copy = {
            ["+"] = "pbcopy",
            ["*"] = "pbcopy",
        },
        paste = {
            ["+"] = "pbpaste",
            ["*"] = "pbpaste",
        },
        cache_enabled = 0,
    }
elseif vim.fn.has("wsl") == 1 then
    -- NOTE: WSL uses the Windows clipboard bridge.
    vim.g.clipboard = {
        name = "WslClipboard",
        copy = {
            ["+"] = "clip.exe",
            ["*"] = "clip.exe",
        },
        paste = {
            ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
        },
        cache_enabled = 0,
    }
elseif vim.fn.has("unix") == 1 then
    -- Linux: xclip 또는 xsel 사용
    if vim.fn.executable("xclip") == 1 then
        vim.g.clipboard = {
            name = "xclip",
            copy = {
                ["+"] = "xclip -selection clipboard",
                ["*"] = "xclip -selection primary",
            },
            paste = {
                ["+"] = "xclip -selection clipboard -o",
                ["*"] = "xclip -selection primary -o",
            },
            cache_enabled = 0,
        }
    elseif vim.fn.executable("xsel") == 1 then
        vim.g.clipboard = {
            name = "xsel",
            copy = {
                ["+"] = "xsel --clipboard --input",
                ["*"] = "xsel --primary --input",
            },
            paste = {
                ["+"] = "xsel --clipboard --output",
                ["*"] = "xsel --primary --output",
            },
            cache_enabled = 0,
        }
    end
end
