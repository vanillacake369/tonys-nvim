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

            local function find_upward(names, start_path)
                local found = vim.fs.find(names, { path = start_path, upward = true, limit = 1 })[1]
                return found and vim.fs.dirname(found) or nil
            end

            local function get_cargo_root()
                local file = vim.api.nvim_buf_get_name(0)
                local dir = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()
                return find_upward({ "Cargo.toml" }, dir) or vim.uv.cwd()
            end

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

            -- Rust / C / C++ (lldb-dap)
            dap.adapters.lldb = {
                type = "executable",
                command = "lldb-dap",
                name = "lldb",
            }
            dap.configurations.rust = {
                {
                    type = "lldb",
                    name = "Debug executable",
                    request = "launch",
                    program = function()
                        return vim.fn.input("Path to executable: ", get_cargo_root() .. "/target/debug/", "file")
                    end,
                    cwd = function()
                        return get_cargo_root()
                    end,
                    stopOnEntry = false,
                    args = {},
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
