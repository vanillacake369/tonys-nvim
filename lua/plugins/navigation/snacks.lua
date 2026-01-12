return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
        bigfile   = { enabled = true },
        dashboard = { enabled = true },
        explorer  = { enabled = true },
        indent    = { enabled = true },
        input     = { enabled = true },
        notifier  = {
            enabled = true,
            timeout = 3000,
        },
        terminal  = { enabled = true },
        picker = { 
            hidden          = true,
            ignored         = true,
            sources         = {
                explorer    = {
                    hidden  = true,
                    ignored = true,
                }
            }
        },
        quickfile    = { enabled = true },
        scope        = { enabled = true },
        scroll       = { enabled = true },
        statuscolumn = { enabled = true },
        words        = { enabled = true },
    },
    keys = {
        -- 주요 Picker 및 탐색기
        { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
        { "<leader>:",       function() Snacks.picker.command_history() end, desc = "Command History" },
        { "<leader>e",       function() Snacks.explorer() end, desc = "File Explorer" },
        -- Find group
        { "<leader>fb", function() Snacks.picker.buffers() end, desc = "[Find] Buffers" },
        { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "[Find] Config File" },
        { "<leader>ff", function() Snacks.picker.files() end, desc = "[Find] Files" },
        { "<leader>fg", function() Snacks.picker.grep() end, desc = "[Find] Grep" },
        { "<leader>fr", function() Snacks.picker.recent() end, desc = "[Find] Recent" },
        -- Terminal
        { "<C-_>", function() Snacks.terminal() end, desc = "Terminal (Root Dir)", mode = { "n", "t" } },
    },
    init = function()
        vim.api.nvim_create_autocmd("User", {
            pattern = "VeryLazy",
            callback = function()
                -- 디버깅용 전역 함수 설정 (지연 로딩)
                _G.dd = function(...)
                    Snacks.debug.inspect(...)
                end
                _G.bt = function()
                    Snacks.debug.backtrace()
                end

                -- `:=` 명령어를 위해 print 함수를 snacks으로 대체
                if vim.fn.has("nvim-0.11") == 1 then
                    vim._print = function(_, ...)
                        dd(...)
                    end
                else
                    vim.print = _G.dd
                end

                -- UI Toggle group
                Snacks.toggle.option("spell", { name = "[UI] Spelling" }):map("<leader>us")
                Snacks.toggle.option("wrap", { name = "[UI] Wrap" }):map("<leader>uw")
                Snacks.toggle.option("relativenumber", { name = "[UI] Relative Number" }):map("<leader>uL")
                Snacks.toggle.diagnostics({ name = "[UI] Diagnostics" }):map("<leader>ud")
                Snacks.toggle.line_number({ name = "[UI] Line Number" }):map("<leader>ul")
                Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "[UI] Conceallevel" }):map("<leader>uc")
                Snacks.toggle.treesitter({ name = "[UI] Treesitter" }):map("<leader>uT")
                Snacks.toggle.option("background", { off = "light", on = "dark", name = "[UI] Dark Background" }):map("<leader>ub")
                Snacks.toggle.inlay_hints({ name = "[UI] Inlay Hints" }):map("<leader>uh")
                Snacks.toggle.indent({ name = "[UI] Indent" }):map("<leader>ug")
                Snacks.toggle.dim({ name = "[UI] Dim" }):map("<leader>uD")
            end,
        })
    end,
}
