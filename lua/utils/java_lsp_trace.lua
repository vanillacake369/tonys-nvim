local M = {}
local session
local hooks = {}
local dap_hook
local sequence = 0
local MAX_EVENTS = 10000

local function pack(...)
    return { n = select("#", ...), ... }
end

local function identity(value)
    return value and vim.fn.sha256(value):sub(1, 12) or vim.NIL
end

function M.record(event, client, bufnr, detail)
    if not session or not session.active then
        return
    end
    if #session.events >= MAX_EVENTS then
        session.dropped = session.dropped + 1
        return
    end
    local entry = {
        run_id = session.run_id,
        event = event,
        elapsed_ms = (vim.uv.hrtime() - session.started) / 1e6,
        client_id = client and client.id or vim.NIL,
        root_id = identity(client and client.config.root_dir),
        bufnr = bufnr or vim.NIL,
    }
    for key, value in pairs(detail or {}) do
        entry[key] = value
    end
    table.insert(session.events, entry)
end

-- RPC payload 대신 method, 시각, 결과 상태만 보존한다.
-- client별 wrapper를 원복해 다른 언어와 이후 추적 세션을 건드리지 않는다.
function M.watch(client)
    if not session or not session.active or client.name ~= "jdtls" or hooks[client] then
        return
    end
    local run = session
    local hook = { rpc = client.rpc.request, handlers = {} }
    hooks[client] = hook
    local function record(event, bufnr, detail)
        if session == run and run.active then
            M.record(event, client, bufnr, detail)
        end
    end
    hook.request = function(method, params, callback, ...)
        sequence = sequence + 1
        local request = sequence
        local detail = { method = method, request = request }
        if method == "workspace/executeCommand" and params then
            detail.command = params.command
        end
        record("rpc_request", nil, detail)
        local values = pack(hook.rpc(method, params, function(err, result, ...)
            record("rpc_response", nil, { method = method, request = request, outcome = err and "error" or "ok" })
            if callback then
                return callback(err, result, ...)
            end
        end, ...))
        record("rpc_sent", nil, {
            method = method,
            request = request,
            protocol_id = values[2] or vim.NIL,
            outcome = values[1] and "sent" or "rejected",
        })
        return unpack(values, 1, values.n)
    end
    client.rpc.request = hook.request
    for _, method in ipairs({
        "language/status",
        "textDocument/publishDiagnostics",
        "client/registerCapability",
        "workspace/executeClientCommand",
    }) do
        local previous = client.handlers[method]
        local original = previous or vim.lsp.handlers[method]
        local wrapper = function(err, result, ctx, ...)
            local detail = { method = method, outcome = err and "error" or "ok" }
            if method == "language/status" and result then
                detail.status = result.type
            elseif method == "textDocument/publishDiagnostics" and result then
                detail.count = #(result.diagnostics or {})
                detail.version = result.version or vim.NIL
                detail.uri_id = identity(result.uri)
            end
            record("handler_begin", ctx and ctx.bufnr, detail)
            local values = original and pack(original(err, result, ctx, ...)) or { n = 0 }
            record("handler_end", ctx and ctx.bufnr, { method = method })
            return unpack(values, 1, values.n)
        end
        hook.handlers[method] = { previous = previous, wrapper = wrapper }
        client.handlers[method] = wrapper
    end
end

-- upstream coroutine provider의 yield/반환은 그대로 두고 준비 시간만 관측한다.
-- 빈 결과는 main 부재와 provider timeout을 구분할 수 없어 성공으로 기록하지 않는다.
function M.watch_dap()
    local dap = package.loaded.dap
    if not session or not session.active or not dap or (dap_hook and dap_hook.wrapper) then
        return
    end
    local run = session
    dap_hook = { dap = dap, listeners = {} }
    local provider = dap.providers and dap.providers.configs.jdtls
    if provider then
        dap_hook.provider = provider
        dap_hook.wrapper = function(bufnr)
            local client = vim.lsp.get_clients({ name = "jdtls", bufnr = bufnr })[1]
            if session == run and run.active then
                M.record("debug_provider_begin", client, bufnr)
            end
            local configs = provider(bufnr)
            if session == run and run.active then
                M.record("debug_provider_end", client, bufnr, {
                    count = #configs,
                    outcome = #configs == 0 and "empty_or_timeout" or "candidates",
                })
            end
            return configs
        end
        dap.providers.configs.jdtls = dap_hook.wrapper
    end
    for _, event in ipairs({ "event_initialized", "event_stopped", "event_terminated", "event_exited" }) do
        local listener = function(debug_session)
            if session == run and run.active and debug_session.config and debug_session.config.type == "java" then
                M.record("debug_" .. event, nil, nil)
            end
        end
        dap.listeners.after[event].JavaLspTrace = listener
        dap_hook.listeners[event] = listener
    end
end

-- trace가 설치한 wrapper만 되돌려 후속 플러그인의 handler를 보존한다.
local function restore_client(client, hook)
    if client.rpc.request == hook.request then
        client.rpc.request = hook.rpc
    end
    for method, handler in pairs(hook.handlers) do
        if client.handlers[method] == handler.wrapper then
            client.handlers[method] = handler.previous
        end
    end
end

-- DAP provider와 listener가 아직 trace 소유일 때만 원래 상태로 복구한다.
local function restore_dap_hook(hook)
    local dap = hook.dap
    if hook.wrapper and dap.providers.configs.jdtls == hook.wrapper then
        dap.providers.configs.jdtls = hook.provider
    end
    for event, listener in pairs(hook.listeners) do
        if dap.listeners.after[event].JavaLspTrace == listener then
            dap.listeners.after[event].JavaLspTrace = nil
        end
    end
end

function M.stop()
    if session then
        session.active = false
    end
    for client, hook in pairs(hooks) do
        restore_client(client, hook)
    end
    hooks = {}
    if dap_hook then
        restore_dap_hook(dap_hook)
        dap_hook = nil
    end
end

function M.start()
    M.stop()
    local started = vim.uv.hrtime()
    session = { run_id = tostring(started), started = started, events = {}, active = true, dropped = 0 }
    for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
        M.watch(client)
    end
    M.watch_dap()
end

function M.report()
    local seen = {}
    for _, entry in ipairs(session and session.events or {}) do
        seen[entry.event] = true
    end
    local missing = { "os_spawn_time", "initialize_request" }
    for _, event in ipairs({ "FileType", "start_or_attach", "LspAttach" }) do
        if not seen[event] then
            table.insert(missing, event)
        end
    end
    return vim.deepcopy({
        active = session and session.active or false,
        run_id = session and session.run_id or vim.NIL,
        events = session and session.events or {},
        dropped = session and session.dropped or 0,
        missing = missing,
        clock = "monotonic; start_or_attach is an invocation observation, not OS spawn",
    })
end

function M.setup()
    local group = vim.api.nvim_create_augroup("JavaLspTrace", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "java",
        callback = function(args)
            M.record("FileType", nil, args.buf)
        end,
    })
    vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client.name == "jdtls" then
                M.watch(client)
                M.watch_dap()
                M.record("LspAttach", client, args.buf)
            end
        end,
    })
    vim.api.nvim_create_user_command("JavaLspTrace", function(args)
        local action = args.fargs[1]
        if action == "start" then
            M.start()
        elseif action == "stop" then
            M.stop()
        elseif action == "report" then
            local report = vim.json.encode(M.report())
            if args.fargs[2] then
                vim.fn.writefile({ report }, args.fargs[2])
            else
                vim.notify(vim.inspect(M.report()))
            end
        else
            vim.notify("Usage: JavaLspTrace start|stop|report [path]", vim.log.levels.WARN)
        end
    end, {
        nargs = "+",
        complete = function()
            return { "start", "stop", "report" }
        end,
    })
end

return M
