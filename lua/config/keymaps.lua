-- leader key 는 모든 keymap/plugin 보다 먼저 설정해야 한다.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- C-d, C-u, C-f, C-b 스크롤 후 커서를 화면 중앙에 둔다.
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll Half Page Down and Center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll Half Page Up and Center" })
vim.keymap.set("n", "<C-f>", "<C-f>zz", { desc = "Scroll Full Page Down and Center" })
vim.keymap.set("n", "<C-b>", "<C-b>zz", { desc = "Scroll Full Page Up and Center" })

-- completion, Copilot suggestion, UI toggle 처럼 plugin-native keymap 은
-- 해당 plugin spec 안에 둔다.

local M = {}

local function get_buf_path()
    return vim.fn.expand("%:p:h")
end

M.definitions = {
    -- LSP 이동 keymap 은 prefix 없이 LspAttach 시점에 붙인다.
    lsp = {
        name = "+LSP Go-to",
        prefix = nil,
        {
            "gd",
            function()
                require("plugins.core.lsp").smart_definition()
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
                require("plugins.core.lsp").show_documentation()
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
                require("plugins.core.lsp").smart_definition()
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

    -- 코드 작업 keymap 은 LspAttach 시점에 붙인다.
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
                -- visual 종료 후 갱신된 '< / '> 마크를 range 로 전달.
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

    -- Git keymap 은 독립 group 으로 분리한다.
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
            "<leader>gB",
            function()
                require("plugins.core.git").review_branch()
            end,
            desc = "Review Branch Diff",
        },
        {
            "<leader>gD",
            function()
                require("plugins.core.git").review_working_tree()
            end,
            desc = "Review Working Tree Diff",
        },
        {
            "<leader>gP",
            function()
                require("plugins.core.git").review_current_pr()
            end,
            desc = "Review Current PR",
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
                require("plugins.core.git").reset_buffer()
            end,
            desc = "Reset Current File",
        },
        {
            "]h",
            function()
                require("plugins.core.git").nav_hunk("next")
            end,
            desc = "Next Hunk",
        },
        {
            "[h",
            function()
                require("plugins.core.git").nav_hunk("prev")
            end,
            desc = "Prev Hunk",
        },
    },

    -- Debug keymap 은 <leader>cd* 에서 <leader>d* 로 승격한다.
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
            "<leader>dt",
            function()
                require("plugins.core.debugger").debug_stop()
            end,
            desc = "Stop/Detach",
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
            "<leader>de",
            function()
                require("plugins.core.debugger").debug_eval()
            end,
            desc = "Evaluate",
        },
        {
            "<leader>de",
            function()
                require("plugins.core.debugger").debug_eval("visual")
            end,
            desc = "Evaluate Selection",
            mode = "v",
        },
        {
            "<leader>dw",
            function()
                require("plugins.core.debugger").debug_watch()
            end,
            desc = "Add Watch",
        },
        {
            "<leader>dw",
            function()
                require("plugins.core.debugger").debug_watch("visual")
            end,
            desc = "Add Watch Selection",
            mode = "v",
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
    },

    debug_run = {
        name = "+Debug Run",
        prefix = "<leader>dr",
    },

    -- Spectre 기반 검색/치환
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

    -- 실제 UI toggle 은 finder.lua 에서 Snacks.toggle 로 등록한다.
    ui = {
        name = "+UI Toggles",
        prefix = "<leader>u",
    },

    -- Diagnostics keymap 은 <leader>d* 에서 <leader>x* 로 옮겨 debug 와 충돌을 피한다.
    diagnostics = {
        name = "+Diagnostics",
        prefix = "<leader>x",
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "All Diagnostics" },
        { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
    },

    -- Buffer keymap 은 bdc→bd, bda→bD 로 줄인다.
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
        { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Close Buffers to Right" },
        { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Close Buffers to Left" },
        {
            "<leader>bo",
            function()
                require("plugins.ui.buffer").delete_hidden_files()
            end,
            desc = "Delete Hidden File Buffers",
        },
        { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous Buffer" },
        { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    },

    -- Snacks picker 기반 검색
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
        {
            "<leader>fk",
            function()
                Snacks.picker.keymaps()
            end,
            desc = "Find Keymaps",
        },
        {
            "<leader>fC",
            function()
                Snacks.picker.commands()
            end,
            desc = "Find Commands",
        },
    },

    -- Spring Initializr 프로젝트 생성
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

    -- TodoTrouble 은 .gitignore 를 존중하고 생성 디렉터리를 건너뛴다.
    -- **/* 대상 plain vimgrep 는 Gradle/JS project 에서 멈칫거렸다.
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
            desc = "Todo Current Directory",
        },
    },

    -- Neotest 기반 test 실행
    test = {
        name = "+Test",
        prefix = "<leader>t",
        {
            "<leader>tt",
            function()
                _G.__test_alternate.run_nearest()
            end,
            desc = "Run Nearest Test",
        },
        {
            "<leader>tT",
            function()
                _G.__test_alternate.run_nearest_verbose()
            end,
            desc = "Run Nearest Test (Verbose)",
        },
        {
            "<leader>tf",
            function()
                _G.__test_alternate.run_file()
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
            "<leader>tO",
            function()
                require("neotest").output_panel.toggle()
            end,
            desc = "Toggle Output Panel",
        },
        {
            "<leader>tp",
            function()
                _G.__test_alternate.pick_jvm_tests()
            end,
            desc = "Pick Tests",
        },
        {
            "<leader>tw",
            function()
                _G.__test_alternate.watch_file()
            end,
            desc = "Toggle Watch (File)",
        },
        {
            "<leader>tq",
            function()
                _G.__test_alternate.stop()
            end,
            desc = "Stop",
        },
        {
            "<leader>ta",
            function()
                _G.__test_alternate.jump_alternate()
            end,
            desc = "Test Alternate (Jump or Create)",
        },
    },

    -- 정렬
    align = {
        name = "+Align",
        prefix = "<leader>a",
        { "<leader>a", "<Plug>(EasyAlign)", desc = "Align Text", mode = { "n", "x" } },
    },

    -- 파일 bookmark
    marks = {
        name = "+Marks",
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

    -- Terminal 열기
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

    -- 화면/파일 이동
    jump = {
        name = "+Jump",
        prefix = "<leader>j",
        {
            "<leader>jj",
            function()
                require("flash").jump()
            end,
            desc = "Flash Jump",
            mode = { "n", "x", "o" },
        },
    },

    -- 주석 toggle hint
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

    -- Window 관리
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

    -- Visual mode 보조 기능
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

    -- Overseer 기반 runner
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

    -- rest.nvim HTTP 요청
    rest = {
        name = "+HTTP Requests",
        { "<localleader>rr", "<cmd>Rest run<cr>", desc = "[HTTP CLIENT] Run Request Under Cursor" },
        { "<localleader>rl", "<cmd>Rest last<cr>", desc = "[HTTP CLIENT] Run Last Request" },
        { "<localleader>ro", "<cmd>Rest open<cr>", desc = "[HTTP CLIENT] Open Response" },
        { "<localleader>re", "<cmd>Rest env select<cr>", desc = "[HTTP CLIENT] Select Environment File" },
    },

    -- img-clip 기반 붙여넣기
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

-- registry group 을 Lazy.nvim keys 형식으로 변환한다.
local function get_keys(group_name, filter)
    local keys = {}
    local group = M.definitions[group_name]
    if not group then
        return keys
    end

    -- plugin spec 이 group 일부 key 만 lazy-load 하도록 필터 지원.
    for _, item in ipairs(group) do
        -- metadata field 는 건너뛴다.
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

-- plugin spec 과 직접 keymap attach 에서 함께 쓰는 public adapter 다.
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

-- Which-key spec 을 자동 생성한다.
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

-- plugin 과 무관한 keymap 은 load 시점에 바로 적용한다.
M.bind({ "window", "move", "editor" }, {})

return M
