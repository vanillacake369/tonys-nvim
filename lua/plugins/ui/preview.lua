local M = {}

M[1] = "MeanderingProgrammer/render-markdown.nvim"
M.dependencies = { "nvim-mini/mini.icons" }
M.ft = { "markdown", "mdx" }
M.opts = {
    file_types = { "markdown", "mdx" },
    render_modes = { "n", "c", "t" },
    max_file_size = 10.0,
}
M.init = function()
    M.setup()
end

local group = vim.api.nvim_create_augroup("MarkdownPreview", { clear = true })

local function auto_image_preview_enabled()
    -- NOTE: zellij/wezterm 조합에서는 terminal image protocol 이 안정적이지 않다.
    -- inline image preview 는 explicit opt-in 으로 두고 기본 preview 는 browser 가 담당한다.
    return vim.g.markdown_image_auto_preview == true
end

local function is_markdown_buffer(bufnr)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end

    local ft = vim.bo[bufnr].filetype
    return ft == "markdown" or ft == "mdx"
end

local function remove_snacks_doc_autocmds(bufnr)
    -- NOTE: Snacks image doc attach 는 buffer-local autocmd 를 만든다.
    -- 수동 disable/refresh 시 placement 만 지우면 다시 살아날 수 있어 augroup 도 정리한다.
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

    local ok, doc = pcall(require, "snacks.image.doc")
    if not ok then
        vim.notify("Snacks.image.doc를 불러올 수 없습니다.", vim.log.levels.WARN)
        return
    end

    doc.attach(bufnr)
    vim.b[bufnr].markdown_image_preview_enabled = true
end

function M.disable(bufnr)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    remove_snacks_doc_autocmds(bufnr)
    clean_placements(bufnr)
    vim.b[bufnr].snacks_image_attached = false
    vim.b[bufnr].markdown_image_preview_enabled = false
end

function M.toggle(bufnr)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())
    if vim.b[bufnr].markdown_image_preview_enabled then
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

    -- NOTE: image path resolver cache 와 Snacks placement 를 같이 비워야
    -- rename/move 된 asset 이 같은 buffer 에서 즉시 다시 해석된다.
    require("plugins.core.paste-img").clear_caches(bufnr)
    M.disable(bufnr)
    M.enable(bufnr)
end

function M.toggle_render()
    pcall(vim.cmd, "RenderMarkdown buf_toggle")
end

function M.setup()
    for _, command in ipairs({
        {
            "MarkdownImageEnable",
            function()
                M.enable(0)
            end,
        },
        {
            "MarkdownImageDisable",
            function()
                M.disable(0)
            end,
        },
        {
            "MarkdownImageToggle",
            function()
                M.toggle(0)
            end,
        },
        {
            "MarkdownImageRefresh",
            function()
                M.refresh(0)
            end,
        },
        { "MarkdownRenderToggle", M.toggle_render },
    }) do
        vim.api.nvim_create_user_command(command[1], command[2], {})
    end

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "markdown", "mdx" },
        callback = function(args)
            if auto_image_preview_enabled() then
                M.enable(args.buf)
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = group,
        callback = function(args)
            clean_placements(args.buf)
        end,
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                clean_placements(bufnr)
            end
        end,
    })
end

return M
