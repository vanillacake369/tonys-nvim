local SNACKS_PRIORITY = 1000
local IMAGE_PREVIEW_MAX_WIDTH = 80
local IMAGE_PREVIEW_MAX_HEIGHT = 30
local NOTIFIER_TIMEOUT_MS = 3000
local PICKER_LAYOUT_WIDTH_RATIO = 0.95
local PICKER_LAYOUT_HEIGHT_RATIO = 0.85
local PICKER_TREE_WIDTH_RATIO = 0.35
local PICKER_PREVIEW_WIDTH_RATIO = 0.65

local function explorer_copy_with_default_name(picker, item)
    if not item then
        return
    end

    local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
    if #paths > 0 then
        local dir = picker:dir()
        Snacks.picker.util.copy(paths, dir)
        picker.list:set_selected()

        local tree = require("snacks.explorer.tree")
        tree:refresh(dir)
        tree:open(dir)
        require("snacks.explorer.actions").update(picker, { target = dir })
        return
    end

    local root = vim.fs.normalize(vim.fn.getcwd(0))
    local from = vim.fs.normalize(item.file)
    if from:find(root, 1, true) ~= 1 then
        root = vim.fs.dirname(from)
    end
    local default = from:sub(#root + 2)

    Snacks.input({
        prompt = "Copy to",
        default = default,
        completion = "file",
    }, function(value)
        if not value or value:find("^%s*$") then
            return
        end

        local to = vim.fs.normalize(root .. "/" .. value)
        local uv = vim.uv or vim.loop
        if uv.fs_stat(to) then
            Snacks.notify.warn("File already exists:\n- `" .. to .. "`")
            return
        end

        Snacks.picker.util.copy_path(item.file, to)
        require("snacks.explorer.tree"):refresh(vim.fs.dirname(to))
        require("snacks.explorer.actions").update(picker, { target = to })
    end)
end

return {
    -- Snacks 를 picker, explorer, terminal, notifier, image preview 의 공통 UI 레이어로 쓴다.
    -- telescope 스타일 layout 과 UI toggle 을 한 플러그인 spec 에 모아둔다.
    "folke/snacks.nvim",
    priority = SNACKS_PRIORITY,
    lazy = false,
    opts = {
        bigfile = { enabled = true },
        dashboard = { enabled = true },
        explorer = { enabled = true },
        image = {
            enabled = true,
            resolve = function(file, src)
                return require("plugins.core.paste-img").resolve_for_snacks(file, src)
            end,
            doc = {
                enabled = false,
                inline = true,
                float = true,
                max_width = IMAGE_PREVIEW_MAX_WIDTH,
                max_height = IMAGE_PREVIEW_MAX_HEIGHT,
            },
        },
        indent = { enabled = true },
        input = { enabled = true },
        notifier = { enabled = true, timeout = NOTIFIER_TIMEOUT_MS },
        terminal = { enabled = true },
        picker = {
            enabled = true,
            ui_select = true,
            -- Git preview는 Snacks의 자체 fancy renderer 대신 delta를 PTY에서
            -- 실행한다. `--side-by-side`는 좁은 picker preview에서 가독성이
            -- 나빠지므로 Lazygit renderer에만 둔다.
            previewers = {
                diff = {
                    style = "terminal",
                    cmd = { "delta", "--dark", "--paging=never", "--syntax-theme", "base16-256" },
                },
                git = {
                    args = {
                        "-c",
                        "core.pager=delta --dark --paging=never --syntax-theme base16-256",
                    },
                },
            },
            layouts = {
                telescope = {
                    layout = {
                        box = "horizontal",
                        width = PICKER_LAYOUT_WIDTH_RATIO,
                        height = PICKER_LAYOUT_HEIGHT_RATIO,
                        {
                            box = "vertical",
                            border = "rounded",
                            title = " 📂 Project Tree ",
                            { win = "input", height = 1, border = "bottom" },
                            { win = "list", border = "none" },
                            width = PICKER_TREE_WIDTH_RATIO,
                        },
                        {
                            win = "preview",
                            title = " 👁️ Preview ",
                            border = "rounded",
                            width = PICKER_PREVIEW_WIDTH_RATIO,
                        },
                    },
                },
            },
            -- picker 전체에 적용할 기본 레이아웃
            layout = { preset = "telescope", focus = "list" },
            sources = {
                explorer = {
                    hidden = true,
                    ignored = true,
                    actions = {
                        explorer_copy = explorer_copy_with_default_name,
                    },
                },
                recent = {
                    cwd_only = false,
                    layout = { reverse = false },
                },
                buffers = {
                    cwd_only = false,
                    layout = { reverse = false },
                },
            },
        },
        quickfile = { enabled = true },
        scope = { enabled = true },
        scroll = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = not vim.g.vscode },
    },

    keys = function()
        return require("config.keymaps").bind({ "find", "terminal" })
    end,
    init = function()
        -- VeryLazy 이후 Snacks 전역 helper 와 UI toggle keymap 을 등록한다.
        vim.api.nvim_create_autocmd("User", {
            pattern = "VeryLazy",
            callback = function()
                -- 디버깅용 전역 함수 설정
                _G.dd = function(...)
                    Snacks.debug.inspect(...)
                end
                _G.bt = function()
                    Snacks.debug.backtrace()
                end

                vim.print = _G.dd

                -- UI 토글
                Snacks.toggle.option("spell", { name = "[UI] Spelling" }):map("<leader>us")
                Snacks.toggle.option("wrap", { name = "[UI] Wrap" }):map("<leader>uw")
                Snacks.toggle.option("relativenumber", { name = "[UI] Relative Number" }):map("<leader>uL")
                Snacks.toggle.diagnostics({ name = "[UI] Diagnostics" }):map("<leader>ud")
                Snacks.toggle.line_number({ name = "[UI] Line Number" }):map("<leader>ul")
                Snacks.toggle
                    .option(
                        "conceallevel",
                        { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "[UI] Conceallevel" }
                    )
                    :map("<leader>uc")
                Snacks.toggle.treesitter({ name = "[UI] Treesitter" }):map("<leader>uT")
                Snacks.toggle
                    .option("background", { off = "light", on = "dark", name = "[UI] Dark Background" })
                    :map("<leader>ub")
                Snacks.toggle.inlay_hints({ name = "[UI] Inlay Hints" }):map("<leader>uh")
                Snacks.toggle.indent({ name = "[UI] Indent" }):map("<leader>ug")
                Snacks.toggle.dim({ name = "[UI] Dim" }):map("<leader>uD")
            end,
        })
    end,
}
