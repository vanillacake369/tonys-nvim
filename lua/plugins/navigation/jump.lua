return {
    -- Flash 로 화면 안의 단어/위치를 빠르게 jump 하기 위해 추가.
    -- navigation keymap 그룹의 jump 동작을 lazy-load trigger 로 사용한다.
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = function()
        return require("config.keymaps").bind("jump")
    end,
}
