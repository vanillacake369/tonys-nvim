-- Code Runner Templates

-- 공통 컴포넌트: 자동으로 float 출력창 열기 + 종료 후 q/Esc로 닫기
local function default_components()
    return {
        { "open_output", direction = "float", on_start = "always", focus = true },
        "close_on_keypress",
        { "on_output_quickfix", set_diagnostics = true, open_on_match = true },
        "on_result_diagnostics",
        "default",
    }
end

local templates = {
    -- Run Script (범용)
    {
        name = "Run Script",
        builder = function()
            local file = vim.fn.expand("%:p")
            local ft = vim.bo.filetype
            local cmd = { file }

            if ft == "go" then
                cmd = { "go", "run", file }
            elseif ft == "python" then
                cmd = { "python", file }
            elseif ft == "lua" then
                cmd = { "lua", file }
            elseif ft == "sh" or ft == "bash" then
                cmd = { "bash", file }
            elseif ft == "javascript" then
                cmd = { "node", file }
            elseif ft == "typescript" then
                cmd = { "npx", "ts-node", file }
            elseif ft == "rust" then
                cmd = { "cargo", "run" }
            elseif ft == "c" then
                local out = vim.fn.expand("%:p:r")
                cmd = { "sh", "-c", "gcc " .. file .. " -o " .. out .. " && " .. out }
            end

            return {
                cmd = cmd,
                components = default_components(),
            }
        end,
        condition = {
            filetype = { "go", "python", "lua", "sh", "bash", "javascript", "typescript", "rust", "c" },
        },
    },

    -- Go
    {
        name = "Go Run",
        builder = function()
            return { cmd = { "go", "run", vim.fn.expand("%:p") }, components = default_components() }
        end,
        condition = { filetype = { "go" } },
    },
    {
        name = "Go Test",
        builder = function()
            return { cmd = { "go", "test", "-v", "./..." }, components = default_components() }
        end,
        condition = { filetype = { "go" } },
    },
    {
        name = "Go Build",
        builder = function()
            return { cmd = { "go", "build", "-v", "./..." }, components = default_components() }
        end,
        condition = { filetype = { "go" } },
        tags = { "BUILD" },
    },

    -- Python
    {
        name = "Python Run",
        builder = function()
            return { cmd = { "python", vim.fn.expand("%:p") }, components = default_components() }
        end,
        condition = { filetype = { "python" } },
    },
    {
        name = "Python Test (pytest)",
        builder = function()
            return { cmd = { "pytest", "-v" }, components = default_components() }
        end,
        condition = { filetype = { "python" } },
    },

    -- Java (Gradle)
    {
        name = "Gradle Build",
        builder = function()
            return { cmd = { "gradle", "build" }, components = default_components() }
        end,
        condition = { filetype = { "java" }, callback = function()
            return vim.fn.filereadable("build.gradle") == 1 or vim.fn.filereadable("build.gradle.kts") == 1
        end },
        tags = { "BUILD" },
    },
    {
        name = "Gradle Test",
        builder = function()
            return { cmd = { "gradle", "test" }, components = default_components() }
        end,
        condition = { filetype = { "java" }, callback = function()
            return vim.fn.filereadable("build.gradle") == 1 or vim.fn.filereadable("build.gradle.kts") == 1
        end },
    },
    {
        name = "Gradle Run",
        builder = function()
            return { cmd = { "gradle", "run" }, components = default_components() }
        end,
        condition = { filetype = { "java" }, callback = function()
            return vim.fn.filereadable("build.gradle") == 1 or vim.fn.filereadable("build.gradle.kts") == 1
        end },
    },

    -- Rust
    {
        name = "Cargo Run",
        builder = function()
            return { cmd = { "cargo", "run" }, components = default_components() }
        end,
        condition = { filetype = { "rust" } },
    },
    {
        name = "Cargo Build",
        builder = function()
            return { cmd = { "cargo", "build" }, components = default_components() }
        end,
        condition = { filetype = { "rust" } },
        tags = { "BUILD" },
    },
    {
        name = "Cargo Test",
        builder = function()
            return { cmd = { "cargo", "test" }, components = default_components() }
        end,
        condition = { filetype = { "rust" } },
    },

    -- Nix
    {
        name = "Nix Build",
        builder = function()
            return { cmd = { "nix", "build" }, components = default_components() }
        end,
        condition = { filetype = { "nix" } },
        tags = { "BUILD" },
    },
    {
        name = "Nix Flake Check",
        builder = function()
            return { cmd = { "nix", "flake", "check" }, components = default_components() }
        end,
        condition = { filetype = { "nix" }, callback = function()
            return vim.fn.filereadable("flake.nix") == 1
        end },
    },

    -- Lua
    {
        name = "Lua Run",
        builder = function()
            return { cmd = { "lua", vim.fn.expand("%:p") }, components = default_components() }
        end,
        condition = { filetype = { "lua" } },
    },

    -- C
    {
        name = "C Compile & Run",
        builder = function()
            local file = vim.fn.expand("%:p")
            local out = vim.fn.expand("%:p:r")
            return { cmd = { "sh", "-c", "gcc " .. file .. " -o " .. out .. " && " .. out }, components = default_components() }
        end,
        condition = { filetype = { "c" } },
    },

    -- TypeScript/JavaScript
    {
        name = "Node Run",
        builder = function()
            return { cmd = { "node", vim.fn.expand("%:p") }, components = default_components() }
        end,
        condition = { filetype = { "javascript" } },
    },
    {
        name = "TS Node Run",
        builder = function()
            return { cmd = { "npx", "ts-node", vim.fn.expand("%:p") }, components = default_components() }
        end,
        condition = { filetype = { "typescript" } },
    },
    {
        name = "NPM Test",
        builder = function()
            return { cmd = { "npm", "test" }, components = default_components() }
        end,
        condition = { filetype = { "javascript", "typescript" }, callback = function()
            return vim.fn.filereadable("package.json") == 1
        end },
    },

    -- Terraform
    {
        name = "Terraform Plan",
        builder = function()
            return { cmd = { "terraform", "plan" }, components = default_components() }
        end,
        condition = { filetype = { "terraform" } },
    },
    {
        name = "Terraform Apply",
        builder = function()
            return { cmd = { "terraform", "apply" }, components = default_components() }
        end,
        condition = { filetype = { "terraform" } },
    },

    -- Bash
    {
        name = "Bash Run",
        builder = function()
            return { cmd = { "bash", vim.fn.expand("%:p") }, components = default_components() }
        end,
        condition = { filetype = { "sh", "bash" } },
    },
}

return {
    "stevearc/overseer.nvim",
    cmd = {
        "OverseerRun",
        "OverseerToggle",
        "OverseerBuild",
        "OverseerTaskAction",
        "OverseerQuickAction",
        "OverseerRestartLast",
    },
    keys = require("config.keymaps").get_keys("runner"),
    opts = {
        task_list = {
            direction = "bottom",
            min_height = 15,
            max_height = 25,
            default_detail = 1,
        },
        templates = { "builtin" },
    },
    config = function(_, opts)
        local overseer = require("overseer")
        overseer.setup(opts)

        -- 커스텀 템플릿 등록
        for _, template in ipairs(templates) do
            overseer.register_template(template)
        end

    end,
}
