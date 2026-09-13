return {
    -- Git hunk 상태를 signcolumn 에 표시하고 hunk 단위 조작을 하기 위해 추가.
    -- 버퍼를 열 때 붙여서 변경 라인을 바로 확인할 수 있게 한다.
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        keys = function()
            return require("config.keymaps").bind("git")
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
}
