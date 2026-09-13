return {
    -- Spectre 로 프로젝트 전역 검색/치환을 preview 하며 처리하기 위해 추가.
    -- Trouble/icons 의 UI 조각을 붙여 결과 탐색을 편하게 한다.
    "nvim-pack/nvim-spectre",
    dependencies = { "folke/trouble.nvim", "nvim-mini/mini.icons" },
    keys = function()
        return require("config.keymaps").bind("search_replace")
    end,
    opts = {},
}
