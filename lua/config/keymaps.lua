-- Leader keys (must be set before any keymap or plugin)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Plugin-native keymaps (configured in their respective plugin files):
-- Insert mode completion: lua/plugins/core/auto-complete.lua
-- Copilot suggestions:    lua/plugins/core/copilot.lua
-- UI toggles <leader>u*:  lua/plugins/navigation/finder.lua

local M = {}

local function get_buf_path()
    return vim.fn.expand("%:p:h")
end

M.definitions = {
    -- LSP Navigation (no prefix, applied on LspAttach)
    lsp = {
        name = "+LSP Go-to",
        prefix = nil,
        {
            "gd",
            function()
                Snacks.picker.lsp_definitions()
            end,
            desc = "Go to Definition",
        },
        {
            "gD",
            function()
                Snacks.picker.lsp_declarations()
            end,
            desc = "Go to Declaration",
        },
        {
            "K",
            function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                local offset_encoding = clients[1] and clients[1].offset_encoding or "utf-16"
                local params = vim.lsp.util.make_position_params(0, offset_encoding)

                vim.lsp.buf_request(0, "textDocument/hover", params, function(_, result)
                    if not (result and result.contents) then
                        Snacks.picker.lsp_definitions()
                        return
                    end

                    local contents = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
                    if vim.tbl_isempty(contents) then
                        return
                    end
                    local final_text = table.concat(contents, "\n")

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
    },

    -- Neovim 0.11+ 표준 gr* 키맵을 Snacks picker로 오버라이드
    lsp_actions = {
        name = "+LSP Actions",
        prefix = "gr",
        {
            "grr",
            function()
                Snacks.picker.lsp_references()
            end,
            desc = "References",
        },
        {
            "gri",
            function()
                Snacks.picker.lsp_implementations()
            end,
            desc = "Implementations",
        },
        {
            "gra",
            function()
                require("tiny-code-action").code_action()
            end,
            desc = "Code Actions",
            mode = { "n", "v" },
        },
        {
            "grn",
            vim.lsp.buf.rename,
            desc = "Rename Symbol",
        },
        {
            "gO",
            function()
                Snacks.picker.lsp_symbols()
            end,
            desc = "Document Symbols",
        },
    },

    -- Code operations (applied on LspAttach)
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

    -- Git (분리된 독립 그룹)
    git = {
        name = "+Git",
        prefix = "<leader>g",
        {
            "<leader>gg",
            function()
                Snacks.terminal("lazygit", { cwd = vim.fn.getcwd() })
            end,
            desc = "Lazygit",
        },
        {
            "<leader>gb",
            function()
                require("gitsigns").blame_line({ full = true })
            end,
            desc = "Blame Line",
        },
        {
            "<leader>gp",
            function()
                require("gitsigns").preview_hunk()
            end,
            desc = "Preview Hunk",
        },
    },

    -- Debug (승격: <leader>cd* → <leader>d*)
    debug = {
        name = "+Debug",
        prefix = "<leader>d",
        {
            "<leader>dc",
            function()
                require("dap").continue()
            end,
            desc = "Start/Continue",
        },
        {
            "<leader>dt",
            function()
                require("dap").toggle_breakpoint()
            end,
            desc = "Toggle Breakpoint",
        },
        {
            "<leader>dT",
            function()
                require("dap").terminate()
            end,
            desc = "Terminate",
        },
        {
            "<leader>di",
            function()
                require("dap").step_into()
            end,
            desc = "Step Into",
        },
        {
            "<leader>do",
            function()
                require("dap").step_over()
            end,
            desc = "Step Over",
        },
        {
            "<leader>du",
            function()
                require("dapui").toggle()
            end,
            desc = "Toggle DAP UI",
        },
    },

    -- Search & Replace (Spectre)
    search_replace = {
        name = "+Search & Replace",
        prefix = "<leader>s",
        {
            "<leader>sr",
            '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
            desc = "Replace current word",
        },
        {
            "<leader>sr",
            '<esc><cmd>lua require("spectre").open_visual()<CR>',
            desc = "Replace selection",
            mode = "v",
        },
        {
            "<leader>sF",
            '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
            desc = "Replace in current file",
        },
    },

    -- UI Toggles (actual toggles in finder.lua via Snacks.toggle)
    ui = {
        name = "+UI Toggles",
        prefix = "<leader>u",
    },

    -- Diagnostics (이동: <leader>d* → <leader>x*, 중복 4개 제거)
    diagnostics = {
        name = "+Diagnostics",
        prefix = "<leader>x",
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "All Diagnostics" },
        { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
    },

    -- Buffer (단축: bdc→bd, bda→bD)
    buffer = {
        name = "+Buffer",
        prefix = "<leader>b",
        {
            "<leader>bd",
            function()
                Snacks.bufdelete()
            end,
            desc = "Delete Current Buffer",
        },
        {
            "<leader>bD",
            function()
                Snacks.bufdelete.all()
            end,
            desc = "Delete All Buffers",
        },
        { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin Buffer" },
        { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Close Buffers to Right" },
        { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Close Buffers to Left" },
        { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous Buffer" },
        { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
        { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous Buffer" },
        { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
        { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move Buffer Left" },
        { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move Buffer Right" },
    },

    -- Find (Snacks picker)
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
                Snacks.picker.projects()
            end,
            desc = "Find Project",
        },
        {
            "<leader>fs",
            function()
                Snacks.picker.lsp_workspace_symbols()
            end,
            desc = "Find Workspace Symbols",
        },
    },

    -- Align
    align = {
        name = "+Align",
        prefix = "<leader>a",
        { "<leader>a", "<Plug>(EasyAlign)", desc = "Align Text", mode = { "n", "x" } },
    },

    -- Terminal
    terminal = {
        {
            "<C-/>",
            function()
                Snacks.terminal()
            end,
            desc = "Toggle Terminal",
            mode = { "n", "t" },
        },
    },

    -- Comment (plugin-managed hints)
    comment = {
        { "gc", desc = "Comment toggle linewise", mode = { "n", "v" } },
        { "gb", desc = "Comment toggle blockwise", mode = { "n", "v" } },
    },

    -- Which-key
    which_key = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer Local Keymaps (which-key)",
        },
    },

    -- Visual mode helpers
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

    editor = {
        { "<", "<gv", desc = "Indent Left (keep selection)", mode = "v" },
        { ">", ">gv", desc = "Indent Right (keep selection)", mode = "v" },
    },

    -- Runner (Overseer)
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

-- Apply plugin-independent keymaps directly at load time
M.apply_keymaps("move")
M.apply_keymaps("editor")

return M
