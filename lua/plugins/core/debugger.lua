return {
    {
        "mfussenegger/nvim-dap",
        keys = function()
            return require("config.keymaps").get_keys("debug")
        end,
        dependencies = {
            "nvim-neotest/nvim-nio",
            "rcarriga/nvim-dap-ui",
        },
        config = function()
            local dap = require("dap")

            -- Go (delve)
            dap.adapters.delve = {
                type = "server",
                port = "${port}",
                executable = {
                    command = "dlv",
                    args = { "dap", "-l", "127.0.0.1:${port}" },
                },
            }
            dap.configurations.go = {
                {
                    type = "delve",
                    name = "Debug",
                    request = "launch",
                    program = "${file}",
                },
                {
                    type = "delve",
                    name = "Debug (test)",
                    request = "launch",
                    mode = "test",
                    program = "${file}",
                },
            }

            -- Python (debugpy)
            dap.adapters.python = {
                type = "executable",
                command = "python3",
                args = { "-m", "debugpy.adapter" },
            }
            dap.configurations.python = {
                {
                    type = "python",
                    name = "Debug",
                    request = "launch",
                    program = "${file}",
                },
            }

            local dapui = require("dapui")
            dapui.setup()

            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end
        end,
    },
}
