local M = {}

local root_markers = {
    ".git",
    "package.json",
    "astro.config.mjs",
    "astro.config.ts",
    "vite.config.js",
    "vite.config.ts",
    "mkdocs.yml",
    "docsify.json",
}

local function supported_file(path)
    local ok, utils = pcall(require, "livepreview.utils")
    return ok and utils.supported_filetype(path)
end

local function preview_file(path)
    if path and path ~= "" then
        path = vim.fs.normalize(path)
        if not vim.startswith(path, "/") then
            path = vim.fs.normalize(vim.fs.joinpath(vim.uv.cwd(), path))
        end
        return path
    end

    path = vim.api.nvim_buf_get_name(0)
    if supported_file(path) then
        return vim.fs.normalize(path)
    end

    local ok, utils = pcall(require, "livepreview.utils")
    if ok then
        local found = utils.find_supported_buf()
        return found and vim.fs.normalize(found) or nil
    end
end

local function preview_root(file)
    local dir = vim.fs.dirname(file)
    return vim.fs.root(dir, root_markers) or dir
end

local function with_cwd(dir, callback)
    local previous = vim.uv.cwd()
    vim.fn.chdir(dir)
    local ok, result = pcall(callback)
    if previous then
        vim.fn.chdir(previous)
    end
    if not ok then
        error(result)
    end
    return result
end

local function port_used_by_other_process(port)
    local result = vim.system({ "lsof", "-nP", "-iTCP:" .. port, "-sTCP:LISTEN", "-F", "p" }, { text = true }):wait()
    if result.code ~= 0 then
        return false
    end

    for pid in (result.stdout or ""):gmatch("p(%d+)") do
        if tonumber(pid) ~= vim.uv.os_getpid() then
            return true
        end
    end
    return false
end

local function preview_port(port)
    for candidate = port, port + 20 do
        if not port_used_by_other_process(candidate) then
            return candidate
        end
    end
    return port
end

function M.start(path)
    local file = preview_file(path)
    if not file then
        vim.notify("live-preview.nvim only supports markdown, asciidoc, svg and html files", vim.log.levels.ERROR)
        return
    end

    local root = preview_root(file)
    local relpath = vim.fs.relpath(root, file)
    if not relpath then
        vim.notify("Preview file is outside the selected webroot: " .. root, vim.log.levels.ERROR)
        return
    end

    local config = require("livepreview.config").config
    config.dynamic_root = false
    local port = preview_port(config.port)
    if port ~= config.port then
        vim.notify(("Live preview port %d is busy; using %d."):format(config.port, port), vim.log.levels.WARN)
    end

    local started = with_cwd(root, function()
        return require("livepreview").start(file, port)
    end)
    if not started then
        return
    end

    local url = ("http://%s:%d/%s"):format(config.address, port, vim.uri_encode(relpath))
    require("livepreview.utils").open_browser(url, config.browser)
    vim.notify(("Live preview: %s"):format(url), vim.log.levels.INFO)
end

function M.close()
    require("livepreview").close()
end

function M.command(opts)
    local subcommand = opts.fargs[1]
    if subcommand == "start" then
        M.start(opts.fargs[2])
    elseif subcommand == "close" then
        M.close()
        print("Live preview stopped")
    elseif subcommand == "pick" then
        require("livepreview").pick()
    else
        require("livepreview").help()
    end
end

function M.setup(opts)
    require("livepreview.config").set(opts)
    vim.api.nvim_create_user_command("LivePreview", M.command, {
        nargs = "*",
        force = true,
        complete = function(arg_lead, cmdline)
            local subcommands = { "start", "close", "pick", "-h", "--help" }
            local subcommand = vim.split(cmdline, " ")[2]
            if subcommand == "" then
                return subcommands
            elseif subcommand == arg_lead then
                return vim.tbl_filter(function(subcmd)
                    return vim.startswith(subcmd, arg_lead)
                end, subcommands)
            elseif subcommand == "start" then
                return vim.fn.getcompletion(arg_lead, "file")
            end
        end,
    })
end

M[1] = "brianhuster/live-preview.nvim"
M.dependencies = { "folke/snacks.nvim" }
M.cmd = { "LivePreview" }
M.ft = { "markdown", "mdx", "html", "htm", "asciidoc", "adoc", "svg" }
M.keys = {
    { "<leader>mp", M.start, desc = "Browser live preview" },
    { "<leader>mq", M.close, desc = "Stop browser live preview" },
}
M.opts = {
    port = 5500,
    browser = "default",
    dynamic_root = false,
    sync_scroll = true,
    picker = "snacks",
    address = "127.0.0.1",
}
M.config = function(_, opts)
    M.setup(opts)
end

return M
