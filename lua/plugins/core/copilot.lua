-- GitHub Copilot 은 blink.cmp 를 통해 AI completion 을 제공한다.

local COPILOT_AUTH_DELAY_MS = 800

-- Copilot 인증 파일이 없으면 provider 를 비활성 상태로 둔다.
local function is_copilot_authenticated()
    local paths = {
        vim.fn.expand("~/.config/github-copilot/hosts.json"),
        vim.fn.expand("~/.config/github-copilot/apps.json"),
        vim.fn.expand("~/.local/share/nvim/github-copilot/hosts.json"),
    }
    for _, path in ipairs(paths) do
        if vim.fn.filereadable(path) == 1 then
            return true
        end
    end
    return false
end

local function run_auth_check()
    local status = is_copilot_authenticated()
    vim.notify(
        "Copilot Auth: " .. (status and "OK" or "FAIL"),
        status and vim.log.levels.INFO or vim.log.levels.WARN,
        { title = "Copilot" }
    )
end

return {
    -- Copilot suggestion provider 를 blink.cmp 연동용으로 띄우기 위해 추가.
    -- 프로젝트별 .copilot-disable 과 auth 상태를 확인해 불필요한 attach 를 피한다.
    "zbirenbaum/copilot.lua",
    event = { "InsertEnter", "VimEnter" },
    config = function()
        -- .copilot-disable 파일이 있으면 현재 project 에서 Copilot 을 끈다.
        local disable_file = vim.fn.findfile(".copilot-disable", ".;")
        if disable_file ~= "" then
            return
        end
        require("copilot").setup({
            suggestion = {
                enabled = true,
                auto_trigger = false,
            },
            panel = {
                enabled = false,
                auto_refresh = false,
            },
            -- Copilot 이 LSP 로 attach 되지 않도록 copilot-lsp 를 끈다.
            nes = {
                enabled = false,
            },
        })
        -- 인증이 없으면 Copilot auth 로 바로 로그인.
        --
        -- if is_copilot_authenticated() then
        --     vim.notify("Copilot: Authenticated", vim.log.levels.INFO)
        -- end
        if not is_copilot_authenticated() then
            vim.defer_fn(function()
                vim.cmd("Copilot auth")
            end, COPILOT_AUTH_DELAY_MS)
        end
        -- 인증 상태를 수동 확인하는 명령을 노출한다.
        vim.api.nvim_create_user_command("CopilotAuthCheck", run_auth_check, {})
    end,
}
