-- GitHub Copilot Integration
-- AI-powered code completion and suggestions

-- 인증 체크 로직
-- copilot 인증파일이 존재하지 않으면 return false
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

local copilot_init_time = 800

return {
    "zbirenbaum/copilot.lua",
    event = { "InsertEnter", "VimEnter" },
    config = function()
        -- .copilot-disable 파일이 있다면 copilot 비활성화
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
            -- copilot-lsp 를 비활성화하여 LSP 서버로서의 기능을 끔
            nes = {
                enabled = false,
            },
        })
        -- NOTE : 인증이 안 되어있다면Copilot auth 를 통해 바로 로그인하게 함
        --
        -- if is_copilot_authenticated() then
        --     vim.notify("Copilot: Authenticated", vim.log.levels.INFO)
        -- end
        if not is_copilot_authenticated() then
            vim.defer_fn(function()
                -- vim.notify("Copilot: Not authenticated! Run :Copilot auth", vim.log.levels.WARN)
                vim.cmd("Copilot auth")
            end, copilot_init_time)
        end
        -- 전역 커맨드 등록
        vim.api.nvim_create_user_command("CopilotAuthCheck", run_auth_check, {})
    end,
}
