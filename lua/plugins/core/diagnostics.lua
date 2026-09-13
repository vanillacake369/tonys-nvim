return {
    -- Trouble 로 diagnostics, quickfix, LSP reference 목록을 한 화면에서 보기 위해 추가.
    -- 명령/키 입력 시에만 로드해서 평소 시작 비용은 줄인다.
    {
        "folke/trouble.nvim",
        opts = {},
        cmd = "Trouble",
        keys = function()
            return require("config.keymaps").bind("diagnostics")
        end,
    },
}
