local M = {}

M.name = "tonys-window-navigation"
M.dir = vim.fn.stdpath("config")
M.lazy = false
M.init = function()
    M.setup()
end

local fullscreen_tab = nil
local autocmds_registered = false

local function is_valid_tab(tab)
    return tab ~= nil and vim.api.nvim_tabpage_is_valid(tab)
end

local function clear_if_invalid()
    if not is_valid_tab(fullscreen_tab) then
        fullscreen_tab = nil
    end
end

local function refresh_statusline()
    pcall(function()
        require("lualine").refresh()
    end)
end

function M.is_fullscreen()
    clear_if_invalid()
    return fullscreen_tab == vim.api.nvim_get_current_tabpage()
end

local function is_snacks_window(win)
    if not vim.api.nvim_win_is_valid(win) then
        return false
    end

    local bufnr = vim.api.nvim_win_get_buf(win)
    local filetype = vim.bo[bufnr].filetype
    return filetype:match("^snacks_picker_") ~= nil or filetype == "snacks_layout_box"
end

local function is_editor_window(win)
    if not vim.api.nvim_win_is_valid(win) or is_snacks_window(win) then
        return false
    end

    if vim.api.nvim_win_get_config(win).relative ~= "" then
        return false
    end

    local bufnr = vim.api.nvim_win_get_buf(win)
    local buftype = vim.bo[bufnr].buftype
    return buftype == "" or buftype == "terminal"
end

local function focus_editor_window()
    local previous = vim.fn.win_getid(vim.fn.winnr("#"))
    if is_editor_window(previous) then
        vim.api.nvim_set_current_win(previous)
        return true
    end

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if is_editor_window(win) then
            vim.api.nvim_set_current_win(win)
            return true
        end
    end

    return false
end

local function focus_picker(picker)
    if not picker or picker.closed then
        return false
    end

    local ok = pcall(function()
        picker:focus("list", { show = true })
    end)
    return ok
end

local function get_snacks()
    local ok, snacks = pcall(require, "snacks")
    if ok then
        return snacks
    end
    return nil
end

local function get_snacks_picker(source)
    local snacks = get_snacks()
    if not (snacks and snacks.picker and snacks.picker.get) then
        return nil
    end

    local ok, pickers = pcall(snacks.picker.get, { source = source })
    if not ok or vim.tbl_isempty(pickers) then
        return nil
    end

    return pickers[#pickers]
end

local function has_editor_window()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if is_editor_window(win) then
            return true
        end
    end

    return false
end

local function close_explorer_if_orphaned()
    -- NOTE: editor window 가 남아 있지 않으면 orphan explorer 를 닫는다.
    -- 그렇지 않으면 해당 tab 안에 유효한 navigation target 이 없다.
    local picker = get_snacks_picker("explorer")
    if not picker or has_editor_window() then
        return
    end

    pcall(function()
        picker:close()
    end)
end

local function reveal_or_open_explorer()
    -- NOTE: 현재 buffer reveal 이 가능하면 기존 explorer 를 재사용한다.
    -- reveal 이 실패하면 새 picker 로 fallback 한다.
    local snacks = get_snacks()
    if not (snacks and snacks.explorer) then
        return nil
    end

    local ok, picker = pcall(snacks.explorer.reveal, { buf = 0 })
    if ok then
        return picker
    end

    ok, picker = pcall(snacks.explorer)
    return ok and picker or nil
end

function M.toggle_fullscreen()
    clear_if_invalid()

    if fullscreen_tab then
        local current_tab = vim.api.nvim_get_current_tabpage()
        local fullscreen_tabnr = vim.api.nvim_tabpage_get_number(fullscreen_tab)

        if current_tab == fullscreen_tab then
            vim.cmd("tabclose")
        else
            vim.cmd(fullscreen_tabnr .. "tabclose")
        end

        fullscreen_tab = nil
        refresh_statusline()
        return
    end

    vim.cmd("tab split")
    fullscreen_tab = vim.api.nvim_get_current_tabpage()
    refresh_statusline()
end

function M.toggle_focus()
    -- NOTE: focus 는 picker -> previous editor -> new explorer 순서로 toggle 한다.
    -- wincmd drift 를 피하려고 Snacks window 는 editor window 와 분리한다.
    if is_snacks_window(vim.api.nvim_get_current_win()) then
        if not focus_editor_window() then
            vim.cmd("wincmd p")
        end
        return
    end

    if focus_picker(get_snacks_picker("explorer")) then
        return
    end

    local picker = reveal_or_open_explorer()
    if not picker then
        vim.cmd("wincmd w")
        return
    end

    focus_picker(picker)
end

function M.setup()
    if autocmds_registered then
        return
    end
    autocmds_registered = true

    vim.api.nvim_create_autocmd("WinClosed", {
        group = vim.api.nvim_create_augroup("tonys_window_focus", { clear = true }),
        callback = function()
            vim.schedule(close_explorer_if_orphaned)
        end,
    })
end

return M
