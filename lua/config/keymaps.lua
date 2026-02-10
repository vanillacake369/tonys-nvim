local M = {}

local function get_buf_path()
    return vim.fn.expand("%:p:h")
end

M.definitions = {
    lsp = {
        name = "+LSP",
        prefix = nil, -- no prefix (gd, gr, etc.)
        {
            "gD",
            function()
                Snacks.picker.lsp_declarations()
            end,
            desc = "Jump to Declarations",
        },
        {
            "gd",
            function()
                Snacks.picker.lsp_definitions()
            end,
            desc = "Jump to Definition",
        },
        {
            "gr",
            function()
                Snacks.picker.lsp_references()
            end,
            desc = "Show References",
        },
        {
            "gi",
            function()
                Snacks.picker.lsp_implementations()
            end,
            desc = "Jump to Implementation",
        },
        {
            "K",
            function()
                -- 현재 버퍼에 연결된 LSP 클라이언트에서 인코딩 정보 가져오기 (경고 해결)
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                local offset_encoding = clients[1] and clients[1].offset_encoding or "utf-16"
                local params = vim.lsp.util.make_position_params(0, offset_encoding)

                -- LSP Hover 요청 전송
                vim.lsp.buf_request(0, "textDocument/hover", params, function(_, result)
                    -- 결과가 없으면 정의(Definition) 피커를 대신 띄움
                    if not (result and result.contents) then
                        Snacks.picker.lsp_definitions()
                        return
                    end

                    -- LSP 결과물을 마크다운 배열로 변환 후 문자열로 결합
                    local contents = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
                    if vim.tbl_isempty(contents) then
                        return
                    end
                    local final_text = table.concat(contents, "\n")

                    -- Snacks.win을 이용한 커스텀 Hover 창 띄우기
                    Snacks.win({
                        text = final_text,
                        width = 0.7,
                        height = 0.5,
                        border = "rounded",
                        backdrop = 60,
                        ft = "markdown",
                        enter = true,
                        keys = {
                            ["q"] = "close",
                            ["<Esc>"] = "close",
                            ["<cr>"] = function(self)
                                self:close()
                                Snacks.picker.lsp_definitions()
                            end,
                        },
                    })
                end)
            end,
            desc = "Show Documentation",
        },
        desc = "LSP Definitions/Hover (Snacks)",
        {
            "<leader>ca",
            function()
                require("tiny-code-action").code_action()
            end,
            desc = "Show Code Actions",
            mode = { "n", "v" },
        },
        {
            "<leader>cs",
            function()
                Snacks.picker.lsp_symbols()
            end,
            desc = "Show Document Symbols",
        },
        {
            "<leader>cS",
            function()
                Snacks.picker.lsp_workspace_symbols()
            end,
            desc = "Show Workspace Symbols",
        },
        { "<leader>cn", vim.lsp.buf.rename, desc = "Rename Symbol" },
    },

    code = {
        name = "+Code",
        prefix = "<leader>c",
        {
            "<leader>cf",
            function()
                require("conform").format({ async = true, lsp_format = "fallback" })
            end,
            desc = "Format Code",
            mode = { "n", "v" },
        },
    },

    search_replace = {
        name = "+Search & Replace",
        prefix = "<leader>cr",
        {
            "<leader>cr",
            '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
            desc = "Search current word",
        },
        {
            "<leader>cr",
            '<esc><cmd>lua require("spectre").open_visual()<CR>',
            desc = "Search current word",
            mode = "v",
        },
        {
            "<leader>crf",
            '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
            desc = "Search on current file",
        },
    },

    diagnostics = {
        name = "+Diagnostics",
        prefix = "<leader>d",
        { "<leader>dd", "<cmd>Trouble diagnostics toggle<cr>", desc = "Show All Diagnostics" },
        { "<leader>db", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Show Buffer Diagnostics" },
        { "<leader>ds", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Show Symbols" },
        { "<leader>dl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "Show LSP References" },
        { "<leader>dL", "<cmd>Trouble loclist toggle<cr>", desc = "Show Location List" },
        { "<leader>dq", "<cmd>Trouble qflist toggle<cr>", desc = "Show Quickfix List" },
    },

    buffer = {
        name = "+Buffer",
        prefix = "<leader>b",
        {
            "<leader>bdc",
            function()
                Snacks.bufdelete()
            end,
            desc = "Delete Current Buffer",
        },
        {
            "<leader>bda",
            function()
                Snacks.bufdelete.all()
            end,
            desc = "Delete All Buffers",
        },
        { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin Buffer" },
        { "<leader>bdP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
        { "<leader>bdr", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to Right" },
        { "<leader>bdl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to Left" },
        { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous Buffer" },
        { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
        { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous Buffer" },
        { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
        { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move Buffer Left" },
        { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move Buffer Right" },
    },

    find = {
        name = "+Find",
        prefix = "<leader>f",
        {
            "<leader><space>",
            function()
                Snacks.picker.smart()
            end,
            desc = "Smart Find Files",
        },
        {
            "<leader>:",
            function()
                Snacks.picker.command_history()
            end,
            desc = "Command History",
        },
        {
            "<leader>e",
            function()
                Snacks.explorer()
            end,
            desc = "Explorer (Project Root)",
        },
        {
            "<leader>E",
            function()
                Snacks.explorer({ cwd = get_buf_path() })
            end,
            desc = "Explorer (Buffer Dir)",
        },
        {
            "<leader>ff",
            function()
                Snacks.picker.files({ cwd = get_buf_path() })
            end,
            desc = "Find Files",
        },
        {
            "<leader>fb",
            function()
                Snacks.picker.buffers()
            end,
            desc = "Find Buffers",
        },
        {
            "<leader>fg",
            function()
                -- Snacks.picker.grep({ cwd = get_buf_path() })
                Snacks.picker.grep()
            end,
            desc = "Grep in Files",
        },
        {
            "<leader>fr",
            function()
                Snacks.picker.recent()
            end,
            desc = "Find Recent Files",
        },
        {
            "<leader>fc",
            function()
                Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
            end,
            desc = "Find Config Files",
        },
        {
            "<leader>fp",
            function()
                -- Snacks.picker.projects({ cwd = get_buf_path() })
                Snacks.picker.projects()
            end,
            desc = "Find Project",
        },
    },

    window = {
        name = "+Window",
        prefix = "<leader>w",
        { "<leader>w-", "<C-w>s", desc = "Split Below" },
        { "<leader>w|", "<C-w>v", desc = "Split Right" },
        { "<leader>wc", "<C-w>q", desc = "Close Window" },
        { "<leader>wh", "<C-w>h", desc = "Go to Left Window" },
        { "<leader>wj", "<C-w>j", desc = "Go to Down Window" },
        { "<leader>wk", "<C-w>k", desc = "Go to Up Window" },
        { "<leader>wl", "<C-w>l", desc = "Go to Right Window" },
        { "<leader>wH", "<C-w>H", desc = "Move Window to Left" },
        { "<leader>wJ", "<C-w>J", desc = "Move Window to Down" },
        { "<leader>wK", "<C-w>K", desc = "Move Window to Up" },
        { "<leader>wL", "<C-w>L", desc = "Move Window to Right" },
        { "<leader>w=", "<C-w>=", desc = "Equal Size Windows" },
    },

    align = {
        name = "+Align",
        prefix = "<leader>a",
        { "<leader>a", "<Plug>(EasyAlign)", desc = "Align Text", mode = { "n", "x" } },
    },

    terminal = {
        {
            "<C-_>",
            function()
                Snacks.terminal()
            end,
            desc = "Toggle Terminal",
            mode = { "n", "t" },
        },
    },

    comment = {
        { "gc", desc = "Comment toggle linewise", mode = { "n", "v" } },
        { "gb", desc = "Comment toggle blockwise", mode = { "n", "v" } },
    },

    which_key = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer Local Keymaps (which-key)",
        },
    },

    move = {
        name = "+Move Lines",
        {
            "J",
            ":m '>+1<CR>gv=gv",
            desc = "Move Selection Down",
            mode = "v",
        },
        {
            "K",
            ":m '<-2<CR>gv=gv",
            desc = "Move Selection Up",
            mode = "v",
        },
    },

    runner = {
        name = "+Runner",
        prefix = "<leader>r",
        {
            "<leader>rr",
            "<cmd>OverseerRun<cr>",
            desc = "Run Task",
        },
        {
            "<leader>rt",
            "<cmd>OverseerToggle<cr>",
            desc = "Toggle Task List",
        },
        {
            "<leader>rb",
            "<cmd>OverseerBuild<cr>",
            desc = "Build Task",
        },
        {
            "<leader>ra",
            "<cmd>OverseerTaskAction<cr>",
            desc = "Task Actions",
        },
        {
            "<leader>rq",
            "<cmd>OverseerQuickAction<cr>",
            desc = "Quick Action",
        },
        {
            "<leader>rl",
            "<cmd>OverseerRestartLast<cr>",
            desc = "Restart Last Task",
        },
    },
}

-- Convert to Lazy.nvim keys format
function M.get_keys(group_name)
    local keys = {}
    local group = M.definitions[group_name]
    if not group then
        return keys
    end

    for _, item in ipairs(group) do
        -- Skip metadata fields
        if type(item) == "table" and item[1] then
            table.insert(keys, {
                item[1],
                item[2],
                desc = item.desc,
                mode = item.mode or "n",
            })
        end
    end
    return keys
end

-- Apply keymaps directly using vim.keymap.set (for LSP, etc.)
function M.apply_keymaps(group_name, opts)
    local group = M.definitions[group_name]
    if not group then
        return
    end

    for _, item in ipairs(group) do
        -- Skip metadata fields
        if type(item) == "table" and item[1] then
            local key_opts = vim.tbl_extend("force", opts or {}, {
                desc = item.desc,
            })
            local mode = item.mode or "n"
            vim.keymap.set(mode, item[1], item[2], key_opts)
        end
    end
end

-- Generate Which-key spec automatically
function M.get_which_key_spec()
    local spec = {}
    for _, group in pairs(M.definitions) do
        if group.prefix and group.name then
            table.insert(spec, {
                group.prefix,
                group = group.name,
            })
        end
    end
    return spec
end

return M
