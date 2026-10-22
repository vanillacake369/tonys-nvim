return {
    -- Git hunk 상태를 signcolumn 에 표시하고 hunk 단위 조작을 하기 위해 추가.
    -- 버퍼를 열 때 붙여서 변경 라인을 바로 확인할 수 있게 한다.
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        keys = function()
            return require("config.keymaps").bind({
                group = "git",
                filter = function(item)
                    return item[1] ~= "<leader>gD"
                end,
            })
        end,
        opts = {
            signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
            },
        },
    },
    -- 여러 파일의 변경을 한 탭에서 검토하고 merge/rebase 충돌을 해소한다.
    -- 현재 buffer hunk 조작은 위 Gitsigns spec이 계속 소유한다.
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        keys = function()
            return require("config.keymaps").bind({
                group = "git",
                filter = function(item)
                    return item[1] == "<leader>gD"
                end,
            })
        end,
        opts = {
            -- Diffview는 popup이 아닌 tabpage라 기본 q 종료 key가 없다.
            -- help/option panel의 기존 q는 panel만 닫으므로 그대로 둔다.
            keymaps = {
                view = {
                    { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
                },
                file_panel = {
                    { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
                },
                file_history_panel = {
                    { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
                },
            },
        },
    },
}
