-- 이름 없는 clipboard 연동을 끄고 normal mode c/cc/d/dd 가 시스템 clipboard 를
-- 덮어쓰지 않게 한다. 삭제 동작은 black-hole register 로 보낸다.
vim.keymap.set("n", "d", '"_d')
vim.keymap.set("n", "dd", '"_dd')

-- +/* register 를 통한 명시적인 시스템 clipboard 접근만 켠다.
vim.opt.clipboard = "unnamedplus"

-- 실행 platform 에 맞춰 clipboard provider 를 고른다.
-- 다만 SSH 환경에서는 remote clipboard tool 대신 OSC 52 로
-- local terminal 의 clipboard 에 전달한다.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
    vim.g.clipboard = "osc52"
elseif vim.fn.has("mac") == 1 then
    -- macOS 는 pbcopy/pbpaste 를 사용한다.
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
    -- WSL 은 Windows clipboard bridge 를 사용한다.
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
    -- Linux 는 xclip 또는 xsel 을 사용한다.
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
