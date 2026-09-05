-- Leader keys (must be set before any keymap or plugin)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- C-d, C-u, C-f, C-b 에 따라 스크롤 시 커서 위치가 화면 중앙에 오도록 설정
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll Half Page Down and Center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll Half Page Up and Center" })
vim.keymap.set("n", "<C-f>", "<C-f>zz", { desc = "Scroll Full Page Down and Center" })
vim.keymap.set("n", "<C-b>", "<C-b>zz", { desc = "Scroll Full Page Up and Center" })

-- NOTE: plugin-native keymaps stay with their plugin specs.
-- Examples: completion, Copilot suggestions, and UI toggles.

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
                local client = vim.lsp.get_clients({
                    bufnr = 0,
                    method = "textDocument/hover",
                })[1]

                local function definitions()
                    Snacks.picker.lsp_definitions()
                end

                if not client then
                    return definitions()
                end

                client:request(
                    "textDocument/hover",
                    vim.lsp.util.make_position_params(0, client.offset_encoding or "utf-16"),
                    function(err, result)
                        if err or not (result and result.contents) then
                            return definitions()
                        end

                        local contents = vim.split(
                            table.concat(vim.lsp.util.convert_input_to_markdown_lines(result.contents), "\n"),
                            "\n",
                            {
                                plain = true,
                                trimempty = true,
                            }
                        )

                        if vim.tbl_isempty(contents) then
                            return definitions()
                        end

                        Snacks.win({
                            text = table.concat(contents, "\n"),
                            ft = "markdown",
                            -- NOTE: compact hover 에 쓸 대체 크기.
                            -- width = math.max(80,
                            --     math.min(math.floor(vim.o.columns * 0.75), 132))
                            -- height = math.max(20,
                            --     math.min(math.floor(vim.o.lines * 0.60), 40))
                            width = math.max(96, math.min(math.floor(vim.o.columns * 0.82), 160)),
                            height = math.max(24, math.min(math.floor(vim.o.lines * 0.72), 48)),
                            border = "rounded",
                            backdrop = 60,
                            enter = true,
                            wo = {
                                wrap = true,
                                linebreak = true,
                                conceallevel = 2,
                            },
                            keys = {
                                q = "close",
                                ["<Esc>"] = "close",
                                ["<CR>"] = function(win)
                                    win:close()
                                    definitions()
                                end,
                            },
                        })
                    end,
                    0
                )
            end,
            desc = "Show Documentation",
        },
    },

    -- Neovim 0.11+ 표준 gr* 키맵을 Snacks picker로 오버라이드
    lsp_actions = {
        name = "+LSP Actions",
        prefix = "gr",
        {
            "gra",
            function()
                require("plugins.core.lsp").smart_code_action()
            end,
            desc = "Code Actions",
            mode = { "n", "v" },
        },
        {
            "grd",
            function()
                Snacks.picker.lsp_definitions()
            end,
            desc = "Definitions",
        },
        {
            "grt",
            function()
                Snacks.picker.lsp_type_definitions()
            end,
            desc = "Type Definitions",
        },
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
            "grn",
            vim.lsp.buf.rename,
            desc = "Rename Symbol",
        },
        {
            "grx",
            vim.lsp.codelens.run,
            desc = "Run Code Lens",
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
                require("conform").format({ async = true, lsp_format = "never" })
            end,
            desc = "Format Code (buffer)",
            mode = "n",
        },
        {
            "<leader>cf",
            function()
                -- NOTE: visual 종료 후 갱신된 '< / '> 마크를 range 로 전달.
                require("conform").format({
                    async = true,
                    lsp_format = "never",
                    range = {
                        start = vim.api.nvim_buf_get_mark(0, "<"),
                        ["end"] = vim.api.nvim_buf_get_mark(0, ">"),
                    },
                })
            end,
            desc = "Format Code (range)",
            mode = "v",
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
            "<leader>gd",
            function()
                Snacks.picker.git_diff()
            end,
            desc = "Git Diff (Hunks)",
        },
        {
            "<leader>gD",
            function()
                require("gitsigns").diffthis()
            end,
            desc = "Diff Current File",
        },
        {
            "<leader>go",
            function()
                Snacks.gitbrowse()
            end,
            desc = "Open in Browser",
        },
        {
            "<leader>gf",
            function()
                Snacks.picker.git_log_file()
            end,
            desc = "Git File History",
        },
        {
            "<leader>gp",
            function()
                require("gitsigns").preview_hunk()
            end,
            desc = "Preview Hunk",
        },
        {
            "<leader>gr",
            function()
                require("gitsigns").reset_hunk()
            end,
            desc = "Reset Hunk",
        },
        {
            "<leader>gR",
            function()
                local file = vim.fn.expand("%:t")
                local choice = vim.fn.confirm(
                    string.format("Discard all unstaged changes in %s?", file ~= "" and file or "current buffer"),
                    "&Yes\n&No",
                    2
                )

                if choice == 1 then
                    require("gitsigns").reset_buffer()
                end
            end,
            desc = "Reset Current File",
        },
        {
            mode = { "n", "t" },
            "]h",
            function()
                require("gitsigns").next_hunk()
            end,
            desc = "Next Hunk",
        },
        {
            mode = { "n", "t" },
            "[h",
            function()
                require("gitsigns").prev_hunk()
            end,
            desc = "Prev Hunk",
        },
    },

    -- Debug (승격: <leader>cd* → <leader>d*)
    debug = {
        name = "+Debug",
        prefix = "<leader>d",
        {
            "<leader>dc",
            function()
                require("plugins.core.debugger").debug_run()
            end,
            desc = "Start/Continue",
        },
        {
            "<leader>db",
            function()
                require("dap").toggle_breakpoint()
            end,
            desc = "Toggle Breakpoint",
        },
        {
            "<leader>dB",
            function()
                local condition = vim.fn.input("Breakpoint condition: ")
                require("dap").set_breakpoint(condition ~= "" and condition or nil)
            end,
            desc = "Conditional Breakpoint",
        },
        {
            "<leader>dt",
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
            "<leader>dO",
            function()
                require("dap").step_out()
            end,
            desc = "Step Out",
        },
        {
            "<leader>dl",
            function()
                require("dap").run_last()
            end,
            desc = "Run Last",
        },
        {
            "<leader>dh",
            function()
                require("dap.ui.widgets").hover()
            end,
            desc = "Hover Value",
            mode = { "n", "v" },
        },
        {
            "<leader>du",
            function()
                require("dapui").toggle()
            end,
            desc = "Toggle DAP UI",
        },
        {
            "<leader>drr",
            function()
                require("plugins.core.debugger").debug_run()
            end,
            desc = "Run Target",
        },
        {
            "<leader>drt",
            function()
                require("plugins.core.debugger").debug_test()
            end,
            desc = "Run Test",
        },
        {
            "<leader>dra",
            function()
                require("plugins.core.debugger").debug_attach()
            end,
            desc = "Attach",
        },
        {
            "<leader>drp",
            function()
                require("plugins.core.debugger").debug_pick()
            end,
            desc = "Pick Target",
        },
    },

    debug_run = {
        name = "+Debug Run",
        prefix = "<leader>dr",
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
            "<leader>bb",
            function()
                if vim.fn.bufnr("#") > 0 then
                    vim.cmd("buffer #")
                end
            end,
            desc = "Alternate Buffer",
        },
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
        { "<leader>bu", "<Cmd>b #<CR>", desc = "Undo / Restore Closed Buffer" },
        {
            "<leader>bo",
            function()
                Snacks.bufdelete.other()
            end,
            desc = "Delete Other Buffers",
        },
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

    -- Spring Initializr
    springInitializr = {
        name = "+Spring Initializr",
        prefix = "<leader>S",
        {
            "<leader>Si",
            "<cmd>SpringInitializr<cr>",
            desc = "Spring Initialize",
            mode = { "n" },
        },
        {
            "<leader>Sg",
            "<cmd>SpringGenerateProject<cr>",
            desc = "Spring Generate",
            mode = { "n" },
        },
    },

    -- PERF: TodoTrouble respects .gitignore and skips generated directories.
    -- Plain vimgrep over **/* stalled on Gradle and JS projects.
    todo = {
        name = "+Todo",
        prefix = "<leader>o",
        {
            "<leader>oo",
            "<cmd>TodoTrouble<cr>",
            desc = "Todo List (Trouble)",
        },
        {
            "<leader>on",
            function()
                require("todo-comments").jump_next()
            end,
            desc = "Next Todo Comment",
        },
        {
            "<leader>op",
            function()
                require("todo-comments").jump_prev()
            end,
            desc = "Previous Todo Comment",
        },
        {
            "<leader>of",
            "<cmd>TodoTrouble cwd=%:p:h<cr>",
            desc = "Todo Current File",
        },
    },

    -- Test (Neotest)
    test = {
        name = "+Test",
        prefix = "<leader>t",
        {
            "<leader>tt",
            function()
                require("neotest").run.run()
            end,
            desc = "Run Nearest Test",
        },
        {
            "<leader>tf",
            function()
                require("neotest").run.run(vim.fn.expand("%"))
            end,
            desc = "Run File",
        },
        {
            "<leader>tl",
            function()
                require("neotest").run.run_last()
            end,
            desc = "Run Last",
        },
        {
            "<leader>ts",
            function()
                require("neotest").summary.toggle()
            end,
            desc = "Toggle Summary",
        },
        {
            "<leader>to",
            function()
                require("neotest").output.open({ enter = true, auto_close = true })
            end,
            desc = "Open Output",
        },
        {
            "<leader>tO",
            function()
                require("neotest").output_panel.toggle()
            end,
            desc = "Toggle Output Panel",
        },
        {
            "<leader>tw",
            function()
                require("neotest").watch.toggle(vim.fn.expand("%"))
            end,
            desc = "Toggle Watch (File)",
        },
        {
            "<leader>tq",
            function()
                require("neotest").run.stop()
            end,
            desc = "Stop",
        },
        {
            "<leader>ta",
            function()
                (_G.__alternate or {
                    jump = function()
                        vim.cmd("Other")
                    end,
                }).jump()
            end,
            desc = "Test Alternate (Jump or Create)",
        },
    },

    -- Align
    align = {
        name = "+Align",
        prefix = "<leader>a",
        { "<leader>a", "<Plug>(EasyAlign)", desc = "Align Text", mode = { "n", "x" } },
    },

    -- Harpoon (file bookmarks)
    harpoon = {
        name = "+Harpoon",
        prefix = "<leader>h",
        {
            "<leader>ha",
            function()
                require("harpoon"):list():add()
            end,
            desc = "Add Mark",
        },
        {
            "<leader>hh",
            function()
                local h = require("harpoon")
                h.ui:toggle_quick_menu(h:list())
            end,
            desc = "Toggle Quick Menu",
        },
        {
            "<leader>hn",
            function()
                require("harpoon"):list():next()
            end,
            desc = "Next Mark",
        },
        {
            "<leader>hp",
            function()
                require("harpoon"):list():prev()
            end,
            desc = "Prev Mark",
        },
        {
            "<leader>hr",
            function()
                require("harpoon"):list():remove()
            end,
            desc = "Remove Current Mark",
        },
        {
            "<leader>hc",
            function()
                require("harpoon"):list():clear()
            end,
            desc = "Clear All Marks",
        },
        {
            "<M-1>",
            function()
                require("harpoon"):list():select(1)
            end,
            desc = "Jump to Mark 1",
        },
        {
            "<M-2>",
            function()
                require("harpoon"):list():select(2)
            end,
            desc = "Jump to Mark 2",
        },
        {
            "<M-3>",
            function()
                require("harpoon"):list():select(3)
            end,
            desc = "Jump to Mark 3",
        },
        {
            "<M-4>",
            function()
                require("harpoon"):list():select(4)
            end,
            desc = "Jump to Mark 4",
        },
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

    -- Window management
    window = {
        name = "+Window",
        prefix = "<leader>w",
        {
            "<leader>wf",
            function()
                require("plugins.navigation.window").toggle_fullscreen()
            end,
            desc = "Toggle Fullscreen",
        },
        {
            "<leader>ww",
            function()
                require("plugins.navigation.window").toggle_focus()
            end,
            desc = "Toggle Focus",
        },
        {
            "<leader>w-",
            "<C-w>s",
            desc = "Split Below",
        },
        {
            "<leader>w|",
            "<C-w>v",
            desc = "Split Right",
        },
        {
            "<leader>wc",
            "<C-w>c",
            desc = "Close Window",
        },
        {
            "<leader>wh",
            "<C-w>h",
            desc = "Go Left",
        },
        {
            "<leader>wj",
            "<C-w>j",
            desc = "Go Down",
        },
        {
            "<leader>wk",
            "<C-w>k",
            desc = "Go Up",
        },
        {
            "<leader>wl",
            "<C-w>l",
            desc = "Go Right",
        },
        {
            "<leader>w=",
            "<C-w>=",
            desc = "Equalize Sizes",
        },
        {
            "<leader>w<",
            "<C-w><",
            desc = "Narrow Window",
        },
        {
            "<leader>w>",
            "<C-w>>",
            desc = "Widen Window",
        },
        {
            "<leader>w+",
            "<C-w>+",
            desc = "Increase Height",
        },
        {
            "<leader>w_",
            "<C-w>-",
            desc = "Decrease Height",
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

    -- Paste (img-clip.nvim)
    paste = {
        {
            "<leader>p",
            function()
                require("plugins.core.paste-img").paste_image()
            end,
            desc = "Paste Markdown Image from Clipboard",
        },
    },
}

-- Convert a registry group to Lazy.nvim keys format.
local function get_keys(group_name, filter)
    local keys = {}
    local group = M.definitions[group_name]
    if not group then
        return keys
    end

    -- NOTE: plugin spec 이 group 일부 key 만 lazy-load 하도록 필터 지원.
    for _, item in ipairs(group) do
        -- Skip metadata fields
        if type(item) == "table" and item[1] and (not filter or filter(item)) then
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

-- Public adapter for plugin specs and direct keymap attachment.
function M.bind(groups, opts)
    local keys = {}
    if type(groups) == "string" or (type(groups) == "table" and (groups.group or groups.filter)) then
        groups = { groups }
    end

    for _, spec in ipairs(groups or {}) do
        local group_name = spec
        local filter = nil

        if type(spec) == "table" then
            group_name = spec.group or spec[1]
            filter = spec.filter
        end

        if group_name then
            vim.list_extend(keys, get_keys(group_name, filter))
        end
    end

    if opts then
        for _, item in ipairs(keys) do
            local key_opts = vim.tbl_extend("force", opts, {
                desc = item.desc,
            })
            vim.keymap.set(item.mode or "n", item[1], item[2], key_opts)
        end
    end

    return keys
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
M.bind({ "window", "move", "editor" }, {})

return M
