-- 기본 yank/delete/change/paste 에
-- 시스템 clipboard(+) 레지스터를 사용한다.
-- yy 로 복사한 내용은 로컬에서는 OS clipboard,
-- SSH 에서는 OSC 52 를 통해 전달된다.
-- NOTE : dd, x 등 삭제 작업도 시스템 clipboard 를 덮어쓸 수 있다.
vim.opt.clipboard = "unnamedplus"

-- OSC 52 clipboard 읽기를 지원하지 않는 터미널에서
-- 응답 대기 및 timeout 이 발생하지 않도록 내부 레지스터를 반환한다.
-- NOTE : 시스템 clipboard 내용을 읽는 것이 아니라 fallback 이다.
local function paste()
    return {
        vim.fn.split(vim.fn.getreg('"'), "\n"),
        vim.fn.getregtype('"'),
    }
end

-- SSH 환경에서는 OSC 52 를 사용해 로컬 터미널 clipboard 에 복사한다.
-- 로컬 환경에서는 OS 별 clipboard provider 를 사용한다.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
    vim.g.clipboard = {
        name = "OSC 52",
        copy = {
            ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
            ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
        },
        paste = {
            ["+"] = paste,
            ["*"] = paste,
        },
        cache_enabled = 0,
    }
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
