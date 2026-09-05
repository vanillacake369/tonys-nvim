-- NOTE: GitHub Copilot provides AI completion through blink.cmp.

-- NOTE: missing Copilot auth files mean the provider should stay disabled.
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
        -- NOTE: .copilot-disable disables Copilot for the current project.
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
            -- NOTE: disable copilot-lsp so Copilot does not attach as an LSP.
            nes = {
                enabled = false,
            },
        })
        -- NOTE: 인증이 없으면 Copilot auth 로 바로 로그인.
        --
        -- if is_copilot_authenticated() then
        --     vim.notify("Copilot: Authenticated", vim.log.levels.INFO)
        -- end
        if not is_copilot_authenticated() then
            vim.defer_fn(function()
                vim.cmd("Copilot auth")
            end, copilot_init_time)
        end
        -- NOTE: expose a manual auth-status check command.
        vim.api.nvim_create_user_command("CopilotAuthCheck", run_auth_check, {})
    end,
}
