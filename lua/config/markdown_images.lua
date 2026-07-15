local M = {}

local uv = vim.uv or vim.loop

local group = vim.api.nvim_create_augroup("MarkdownImagePipeline", { clear = true })

M.state = {
    buffers = {},
    windows = {},
    cache = {
        capabilities = {},
    },
    fallback = "none",
}

local function now_ms()
    return uv.hrtime() / 1000000
end

local function is_markdown_buffer(bufnr)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end
    local ft = vim.bo[bufnr].filetype
    return ft == "markdown" or ft == "mdx"
end

local function ensure_buffer_state(bufnr)
    M.state.buffers[bufnr] = M.state.buffers[bufnr]
        or {
            enabled = false,
            attached = false,
            fallback = M.state.fallback,
            generation = 0,
            last_event = nil,
            last_attach_ms = nil,
            notified_unsupported = false,
        }
    return M.state.buffers[bufnr]
end

local function window_viewport(winid)
    if not vim.api.nvim_win_is_valid(winid) then
        return nil
    end

    local ok, viewport = pcall(vim.api.nvim_win_call, winid, function()
        return {
            top = vim.fn.line("w0"),
            bottom = vim.fn.line("w$"),
            width = vim.api.nvim_win_get_width(winid),
            height = vim.api.nvim_win_get_height(winid),
        }
    end)

    return ok and viewport or nil
end

local function update_windows(bufnr)
    for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
        M.state.windows[winid] = {
            bufnr = bufnr,
            viewport = window_viewport(winid),
            visible = {},
        }
    end
end

local function cleanup_buffer(bufnr)
    local bstate = M.state.buffers[bufnr]
    if bstate and bstate.scan_timer and not bstate.scan_timer:is_closing() then
        bstate.scan_timer:stop()
        bstate.scan_timer:close()
    end
    M.state.buffers[bufnr] = nil

    for winid, wstate in pairs(M.state.windows) do
        if wstate.bufnr == bufnr then
            M.state.windows[winid] = nil
        end
    end
end

local function cleanup_window(winid)
    M.state.windows[tonumber(winid)] = nil
end

local function capability_label(env)
    if not env then
        return "unknown"
    end
    return string.format(
        "%s supported=%s placeholders=%s remote=%s",
        env.name ~= "" and env.name or "unknown",
        tostring(env.supported == true),
        tostring(env.placeholders == true),
        tostring(env.remote == true)
    )
end

local function detect_capability(cb)
    local cached = M.state.cache.capabilities.terminal
    if cached then
        cb(cached)
        return
    end

    local ok, terminal = pcall(require, "snacks.image.terminal")
    if not ok then
        local result = {
            supported = false,
            placeholders = false,
            label = "snacks.image.terminal unavailable",
        }
        M.state.cache.capabilities.terminal = result
        cb(result)
        return
    end

    terminal.detect(function()
        local env = terminal.env()
        local result = {
            supported = env.supported == true or Snacks.image.config.force == true,
            placeholders = env.placeholders == true,
            remote = env.remote == true,
            env = env,
            label = capability_label(env),
        }
        M.state.cache.capabilities.terminal = result
        cb(result)
    end)
end

local function remove_snacks_doc_autocmds(bufnr)
    pcall(vim.api.nvim_del_augroup_by_name, "snacks.image.inline." .. bufnr)
    pcall(vim.api.nvim_del_augroup_by_name, "snacks.image.doc." .. bufnr)
end

local function clean_placements(bufnr)
    local ok, placement = pcall(require, "snacks.image.placement")
    if ok then
        pcall(placement.clean, bufnr)
    end
end

function M.enable(bufnr)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())
    if not is_markdown_buffer(bufnr) then
        return
    end

    local bstate = ensure_buffer_state(bufnr)
    bstate.enabled = true
    bstate.generation = bstate.generation + 1
    local generation = bstate.generation
    local started = now_ms()

    detect_capability(function(capability)
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end
            local current = ensure_buffer_state(bufnr)
            if current.generation ~= generation or not current.enabled then
                return
            end

            current.capability = capability
            current.last_event = "enable"
            update_windows(bufnr)

            if not capability.supported then
                current.attached = false
                current.last_attach_ms = now_ms() - started
                if not current.notified_unsupported and M.state.fallback ~= "none" then
                    current.notified_unsupported = true
                    vim.notify(
                        "현재 terminal은 Snacks image protocol을 지원하지 않습니다. Markdown 이미지는 fallback으로 둡니다.",
                        vim.log.levels.INFO
                    )
                end
                return
            end

            local ok, doc = pcall(require, "snacks.image.doc")
            if not ok then
                vim.notify("Snacks.image.doc를 불러올 수 없습니다.", vim.log.levels.WARN)
                return
            end

            doc.attach(bufnr)
            current.attached = true
            current.last_attach_ms = now_ms() - started
        end)
    end)
end

function M.disable(bufnr)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    local bstate = ensure_buffer_state(bufnr)
    bstate.enabled = false
    bstate.attached = false
    bstate.generation = bstate.generation + 1
    bstate.last_event = "disable"

    remove_snacks_doc_autocmds(bufnr)
    clean_placements(bufnr)
    vim.b[bufnr].snacks_image_attached = false
end

function M.toggle(bufnr)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())
    local bstate = ensure_buffer_state(bufnr)
    if bstate.enabled then
        M.disable(bufnr)
    else
        M.enable(bufnr)
    end
end

function M.refresh(bufnr)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    require("config.markdown_assets").clear_caches(bufnr)
    M.disable(bufnr)
    M.enable(bufnr)
end

function M.toggle_render()
    pcall(vim.cmd, "RenderMarkdown buf_toggle")
    M.toggle(0)
end

function M.debug(bufnr)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())
    local bstate = M.state.buffers[bufnr] or {}
    update_windows(bufnr)

    local assets = require("config.markdown_assets")
    local cache_stats = assets.cache_stats()
    local lines = {
        "Markdown Image Debug",
        "buffer: " .. tostring(bufnr),
        "enabled: " .. tostring(bstate.enabled == true),
        "snacks attached: " .. tostring(bstate.attached == true),
        "fallback mode: " .. tostring(M.state.fallback),
        "terminal capability: " .. tostring(
            (bstate.capability and bstate.capability.label)
                or (M.state.cache.capabilities.terminal and M.state.cache.capabilities.terminal.label)
                or "unknown"
        ),
        "last event: " .. tostring(bstate.last_event),
        "last attach duration(ms): " .. string.format("%.3f", bstate.last_attach_ms or 0),
        "resolve cache hits: " .. tostring(cache_stats.resolve_hits),
        "resolve cache misses: " .. tostring(cache_stats.resolve_misses),
        "resolve cache entries: " .. tostring(cache_stats.resolve_entries),
        "windows:",
    }

    for winid, wstate in pairs(M.state.windows) do
        if wstate.bufnr == bufnr then
            local vp = wstate.viewport or {}
            lines[#lines + 1] = string.format(
                "  %d top=%s bottom=%s width=%s height=%s",
                winid,
                tostring(vp.top),
                tostring(vp.bottom),
                tostring(vp.width),
                tostring(vp.height)
            )
        end
    end

    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

function M.setup()
    vim.api.nvim_create_user_command("MarkdownImageEnable", function()
        M.enable(0)
    end, {})
    vim.api.nvim_create_user_command("MarkdownImageDisable", function()
        M.disable(0)
    end, {})
    vim.api.nvim_create_user_command("MarkdownImageToggle", function()
        M.toggle(0)
    end, {})
    vim.api.nvim_create_user_command("MarkdownImageRefresh", function()
        M.refresh(0)
    end, {})
    vim.api.nvim_create_user_command("MarkdownImageDebug", function()
        M.debug(0)
    end, {})
    vim.api.nvim_create_user_command("MarkdownRenderToggle", M.toggle_render, {})

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "markdown", "mdx" },
        callback = function(args)
            M.enable(args.buf)
        end,
    })

    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = group,
        callback = function(args)
            cleanup_buffer(args.buf)
        end,
    })

    vim.api.nvim_create_autocmd("WinClosed", {
        group = group,
        callback = function(args)
            cleanup_window(args.match)
        end,
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
            for bufnr in pairs(M.state.buffers) do
                clean_placements(bufnr)
                cleanup_buffer(bufnr)
            end
        end,
    })
end

return M
