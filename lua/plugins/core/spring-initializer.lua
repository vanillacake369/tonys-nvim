return {
    -- Neovim 안에서 Spring Initializr 프로젝트 생성을 시작하기 위해 추가.
    -- telescope/nui 기반 선택 UI 를 keymap 으로 바로 호출한다.
    "jkeresman01/spring-initializr.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-telescope/telescope.nvim",
    },
    keys = function()
        return require("config.keymaps").bind("springInitializr")
    end,
    opts = {},
}
