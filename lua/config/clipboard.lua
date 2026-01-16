-- 시스템 클립보드 연동
vim.opt.clipboard = "unnamedplus"

-- 플랫폼별 클립보드 설정
if vim.fn.has("mac") == 1 then
    -- macOS: pbcopy/pbpaste
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
    -- WSL: Windows 클립보드 사용
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
