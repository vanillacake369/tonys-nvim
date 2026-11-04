local M = {}
local owned_adapter
local active = {}
local REQUIRED_COMMANDS = {
    "vscode.java.resolveMainClass",
    "vscode.java.resolveJavaExecutable",
    "vscode.java.checkProjectSettings",
    "vscode.java.resolveClasspath",
}

-- 최초 Java adapter 등록에서 auto HCR 옵션을 고정한다.
-- 다른 adapter가 이미 소유한 설정은 덮지 않는다.
function M.prepare(available)
    if not available then
        return
    end

    local dap = require("dap")
    local adapter = dap.adapters.java
    if adapter and adapter ~= owned_adapter then
        vim.notify("Java debug: external adapter already exists; HCR options are unchanged", vim.log.levels.WARN)
        return
    end
    if adapter then
        return
    end

    require("jdtls").setup_dap({ hotcodereplace = "auto" })
    owned_adapter = dap.adapters.java
    require("utils.java_lsp_trace").watch_dap()
end

local function finish(operation, outcome, message)
    if active[operation.client] ~= operation then
        return
    end

    active[operation.client] = nil
    if operation.timer and not operation.timer:is_closing() then
        operation.timer:stop()
        operation.timer:close()
    end
    operation.trace.record("debug_refresh_" .. outcome, operation.client, operation.bufnr)
    if message then
        vim.notify("JavaDebugRefresh: " .. message, vim.log.levels.INFO)
    end
end

local function is_current(operation)
    if active[operation.client] ~= operation then
        return false
    end

    local client = operation.client
    local client_matches = vim.lsp.get_client_by_id(client.id) == client and not client:is_stopped()
    local buffer_matches = vim.api.nvim_buf_is_valid(operation.bufnr)
        and vim.api.nvim_get_current_buf() == operation.bufnr
        and vim.api.nvim_buf_get_name(operation.bufnr) == operation.filename
    local root_matches = client.config.root_dir == operation.root
    local still_attached = client.attached_buffers[operation.bufnr] == true
    if client_matches and buffer_matches and root_matches and still_attached then
        return true
    end

    finish(operation, "stale", "buffer/client changed; run again in the intended project")
    return false
end

-- 모든 서버 조회는 같은 client와 buffer에 직렬로 보낸다.
-- 거부·서버 오류·callback 예외를 각각 명시적으로 종료한다.
local function request_command(operation, command, arguments, next_step)
    if not is_current(operation) then
        return
    end

    local ok, sent = pcall(operation.client.request, operation.client, "workspace/executeCommand", {
        command = command,
        arguments = arguments,
    }, function(err, result)
        if not is_current(operation) then
            return
        end
        if err then
            finish(operation, "error", command .. " failed; retry when Java is ready")
            return
        end

        local handled = pcall(next_step, operation, result)
        if not handled then
            finish(operation, "error", command .. " response could not be processed")
        end
    end, operation.bufnr)
    if not ok or not sent then
        finish(operation, "error", command .. " could not be sent")
    end
end

local function on_classpath(operation, paths)
    local valid_paths = type(paths) == "table" and type(paths[1]) == "table" and type(paths[2]) == "table"
    if not valid_paths then
        finish(operation, "error", "invalid classpath response")
        return
    end

    local main = operation.main
    local config = {
        type = "java",
        request = "launch",
        name = "Launch " .. main.mainClass,
        cwd = operation.root,
        mainClass = main.mainClass,
        projectName = main.projectName or "",
        javaExec = operation.java_exec,
        modulePaths = paths[1],
        classPaths = paths[2],
        vmArgs = operation.preview and "--enable-preview" or nil,
        console = "integratedTerminal",
    }
    local submitted = pcall(require("dap").run, config)
    if not submitted then
        finish(operation, "error", "debug submission failed")
        return
    end
    finish(operation, "submitted")
end

local function on_preview(operation, preview)
    if type(preview) ~= "boolean" then
        finish(operation, "error", "invalid preview settings response")
        return
    end

    operation.preview = preview
    local main = operation.main
    request_command(operation, "vscode.java.resolveClasspath", { main.mainClass, main.projectName or "" }, on_classpath)
end

local function on_java_exec(operation, java_exec)
    if type(java_exec) ~= "string" or java_exec == "" then
        finish(operation, "error", "Java executable could not be resolved")
        return
    end

    operation.java_exec = java_exec
    local main = operation.main
    local settings = vim.json.encode({
        className = main.mainClass,
        projectName = main.projectName or "",
        inheritedOptions = true,
        expectedOptions = {
            ["org.eclipse.jdt.core.compiler.problem.enablePreviewFeatures"] = "enabled",
        },
    })
    request_command(operation, "vscode.java.checkProjectSettings", settings, on_preview)
end

local function on_selected(operation, main)
    if not is_current(operation) then
        return
    end
    if not main then
        finish(operation, "cancelled")
        return
    end
    if type(main.mainClass) ~= "string" or main.mainClass == "" then
        finish(operation, "error", "invalid main class")
        return
    end
    if main.projectName ~= nil and type(main.projectName) ~= "string" then
        finish(operation, "error", "invalid project name")
        return
    end

    operation.main = main
    request_command(
        operation,
        "vscode.java.resolveJavaExecutable",
        { main.mainClass, main.projectName or "" },
        on_java_exec
    )
end

local function on_classes(operation, classes)
    if type(classes) ~= "table" then
        finish(operation, "error", "invalid main class response")
        return
    end
    if #classes == 0 then
        finish(operation, "empty", "No main classes found; check project readiness")
        return
    end

    local opened = pcall(vim.ui.select, classes, {
        prompt = "Java main class (JavaDebugRefresh):",
        format_item = function(item)
            return tostring(item.mainClass) .. " (" .. (item.projectName or "") .. ")"
        end,
    }, function(main)
        on_selected(operation, main)
    end)
    if not opened then
        finish(operation, "error", "main class picker failed")
    end
end

-- 첫 debug의 lazy provider 제한 이후 현재 Java buffer만 복구한다.
-- 작업 상태는 client별 하나이고, 만료되거나 root가 바뀐 응답은 launch하지 않는다.
function M.refresh(opts)
    opts = opts or {}
    local bufnr = vim.api.nvim_get_current_buf()
    local client = vim.lsp.get_clients({ bufnr = bufnr, name = "jdtls" })[1]
    if vim.bo[bufnr].filetype ~= "java" or not client or not client.config.root_dir then
        vim.notify("JavaDebugRefresh: open an attached Java buffer first", vim.log.levels.INFO)
        return
    end

    local commands = vim.tbl_get(client.server_capabilities, "executeCommandProvider", "commands") or {}
    for _, command in ipairs(REQUIRED_COMMANDS) do
        if not vim.tbl_contains(commands, command) then
            vim.notify(
                "JavaDebugRefresh: server/debug bundle is not ready (missing " .. command .. ")",
                vim.log.levels.INFO
            )
            return
        end
    end
    if active[client] then
        vim.notify("JavaDebugRefresh: discovery is already running", vim.log.levels.INFO)
        return
    end

    local operation = {
        bufnr = bufnr,
        client = client,
        root = client.config.root_dir,
        filename = vim.api.nvim_buf_get_name(bufnr),
        trace = require("utils.java_lsp_trace"),
    }
    active[client] = operation
    operation.trace.record("debug_refresh_start", client, bufnr)
    operation.timer = vim.defer_fn(function()
        finish(operation, "timeout", "discovery timed out; wait for Java readiness and retry")
    end, opts.timeout_ms or 30000)
    request_command(operation, "vscode.java.resolveMainClass", nil, on_classes)
end

function M.setup()
    vim.api.nvim_create_user_command("JavaDebugRefresh", function()
        M.refresh()
    end, { desc = "Discover Java launch config without disabling lazy DAP; use after discovery timeout" })
end

return M
