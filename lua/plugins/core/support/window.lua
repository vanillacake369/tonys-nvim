local M = {}

local fullscreen_tab = nil

local function is_valid_tab(tab)
    return tab ~= nil and vim.api.nvim_tabpage_is_valid(tab)
end

local function clear_if_invalid()
    if not is_valid_tab(fullscreen_tab) then
        fullscreen_tab = nil
    end
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
        return
    end

    vim.cmd("tab split")
    fullscreen_tab = vim.api.nvim_get_current_tabpage()
end

return M
