local M = {}

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.WARN)
end

local function exepath(name)
    local path = vim.fn.exepath(name)
    if path == "" or vim.fn.executable(path) ~= 1 then
        return nil
    end
    return path
end

local function first_glob(patterns)
    for _, pattern in ipairs(patterns) do
        local matches = vim.fn.glob(pattern, true, true)
        if #matches > 0 then
            table.sort(matches)
            return matches[1]
        end
    end
    return nil
end

local function glob_all(patterns)
    local result = {}
    for _, pattern in ipairs(patterns) do
        for _, match in ipairs(vim.fn.glob(pattern, true, true)) do
            table.insert(result, match)
        end
    end
    table.sort(result)
    return result
end

function M.codelldb_path()
    return exepath("codelldb")
        or first_glob({
            vim.fn.expand("~/.nix-profile/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb"),
            "/nix/store/*-vscode-extension-vadimcn-vscode-lldb-*/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb",
        })
end

function M.lldb_adapter()
    local codelldb = M.codelldb_path()
    if codelldb then
        return {
            type = "server",
            host = "127.0.0.1",
            port = "${port}",
            executable = {
                command = codelldb,
                args = { "--port", "${port}" },
            },
        }
    end

    local lldb_dap = exepath("lldb-dap")
    if lldb_dap then
        return {
            type = "executable",
            command = lldb_dap,
            name = "lldb",
        }
    end

    return false
end

function M.lldb_adapter_type(adapter)
    if not adapter then
        adapter = M.lldb_adapter()
    end
    if adapter == false then
        return nil
    end
    return adapter.type == "server" and "codelldb" or "lldb"
end

function M.java_bundles()
    return glob_all({
        vim.fn.expand(
            "~/.nix-profile/share/vscode/extensions/vscjava.vscode-java-debug/server/com.microsoft.java.debug.plugin-*.jar"
        ),
        vim.fn.expand("~/.nix-profile/share/vscode/extensions/vscjava.vscode-java-test/server/*.jar"),
        "/nix/store/*-vscode-extension-vscjava-vscode-java-debug-*/share/vscode/extensions/vscjava.vscode-java-debug/server/com.microsoft.java.debug.plugin-*.jar",
        "/nix/store/*-vscode-extension-vscjava-vscode-java-test-*/share/vscode/extensions/vscjava.vscode-java-test/server/*.jar",
    })
end

function M.js_debug_adapter()
    return exepath("js-debug")
        or first_glob({
            vim.fn.expand("~/.nix-profile/bin/js-debug"),
            "/nix/store/*-vscode-js-debug-*/bin/js-debug",
        })
end

function M.input_args()
    local args = vim.fn.input("Args: ")
    return args ~= "" and vim.split(args, " +") or {}
end

function M.find_upward(names, start_path)
    local found = vim.fs.find(names, { path = start_path, upward = true, limit = 1 })[1]
    return found and vim.fs.dirname(found) or nil
end

function M.project_root(markers)
    local file = vim.api.nvim_buf_get_name(0)
    local dir = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()
    return M.find_upward(markers, dir) or vim.uv.cwd()
end

local function rust_lsp(command, opts)
    if vim.bo.filetype ~= "rust" then
        notify(command .. " is only available in Rust buffers")
        return
    end

    opts = opts or {}
    local ok, err
    if opts.bang then
        ok, err = pcall(vim.cmd.RustLsp, { command, bang = true })
    else
        ok, err = pcall(vim.cmd.RustLsp, command)
    end
    if not ok then
        notify(tostring(err), vim.log.levels.ERROR)
    end
end

local function dap_continue()
    local ok, err = pcall(function()
        require("dap").continue()
    end)
    if not ok then
        notify(tostring(err), vim.log.levels.ERROR)
    end
end

local function attach_configs()
    local configs = require("dap").configurations[vim.bo.filetype] or {}
    local matches = {}
    for _, config in ipairs(configs) do
        if config.request == "attach" then
            table.insert(matches, config)
        end
    end
    return matches
end

function M.debug_run()
    if vim.bo.filetype == "rust" then
        rust_lsp("debug")
        return
    end

    dap_continue()
end

function M.debug_test()
    local ok, err = pcall(function()
        require("neotest").run.run({ strategy = "dap" })
    end)
    if not ok then
        notify(tostring(err), vim.log.levels.ERROR)
    end
end

function M.debug_attach()
    local configs = attach_configs()
    if #configs == 0 then
        notify("No DAP attach configuration for " .. vim.bo.filetype)
        return
    end

    vim.ui.select(configs, {
        prompt = "Attach configuration:",
        format_item = function(config)
            return config.name
        end,
    }, function(config)
        if config then
            require("dap").run(config)
        end
    end)
end

function M.debug_pick()
    if vim.bo.filetype == "rust" then
        rust_lsp("debuggables")
        return
    end

    dap_continue()
end

M[1] = {
    "mfussenegger/nvim-dap",
    keys = function()
        return require("config.keymaps").bind("debug")
    end,
    dependencies = {
        "nvim-neotest/nvim-nio",
        "rcarriga/nvim-dap-ui",
        "theHamsta/nvim-dap-virtual-text",
    },
    opts = {
        setup = {},
    },
    config = function(_, opts)
        local dap = require("dap")
        require("nvim-dap-virtual-text").setup()

        for _, setup in ipairs(opts.setup or {}) do
            setup(dap, M)
        end

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
}

M[2] = {
    "rcarriga/nvim-dap-ui",
    lazy = true,
}

return M
