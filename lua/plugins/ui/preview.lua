local M = {}

-- render-markdown 으로 markdown/mdx buffer 를
-- 읽기 좋은 inline preview 로 표시한다.
-- 이미지 preview 명령은
-- Snacks image doc attach 를 직접 제어하는 보조 layer 다.
-- vscode 일 때는 vim.g.vscode 를 통해 disable 처리를 한다
M[1] = "MeanderingProgrammer/render-markdown.nvim"
M.dependencies = { "nvim-mini/mini.icons" }
M.ft = { "markdown", "mdx" }
M.opts = {
    file_types = { "markdown", "mdx" },
    render_modes = { "n", "c", "t" },
    max_file_size = 10.0,
}
M.enabled = not vim.g.vscode
M.init = function()
    M.setup()
end

local group = vim.api.nvim_create_augroup("MarkdownPreview", { clear = true })

local function auto_image_preview_enabled()
    -- zellij/wezterm session 에서는 terminal image protocol 이 불안정하다.
    -- inline image preview 는 opt-in 으로 두고 browser preview 를 기본값으로 쓴다.
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
    -- Snacks image doc attach 는 buffer-local autocmd 를 만든다.
    -- augroup 까지 지우지 않으면 수동 비활성화/새로고침 뒤 placement 가 되살아날 수 있다.
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
    -- 현재 markdown buffer 에 Snacks inline image preview 를 붙인다.
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
    -- buffer-local image preview autocmd 와 placement 를 지워 inline preview 를 끈다.
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
    -- 현재 buffer 의 markdown image preview 상태를 토글한다.
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())
    if vim.b[bufnr].markdown_image_preview_enabled then
        M.disable(bufnr)
    else
        M.enable(bufnr)
    end
end

function M.refresh(bufnr)
    -- asset cache 와 placement 를 비운 뒤 image preview 를 다시 붙인다.
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    -- 이름이 바뀌었거나 이동된 asset 이 같은 buffer 에서 즉시 해석되도록
    -- resolver cache 와 Snacks placement 를 함께 비운다.
    require("plugins.core.paste-img").clear_caches(bufnr)
    M.disable(bufnr)
    M.enable(bufnr)
end

function M.toggle_render()
    -- render-markdown 의 현재 buffer render 상태를 토글한다.
    pcall(vim.cmd, "RenderMarkdown buf_toggle")
end

function M.setup()
    -- Markdown preview/render 관련 사용자 명령을 한 곳에서 등록한다.
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
