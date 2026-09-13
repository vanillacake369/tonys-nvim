return {
    -- Harpoon 으로 자주 오가는 파일 목록을 프로젝트별 quick mark 로 관리한다.
    -- UI 를 닫을 때 동기화해 session 간 mark 손실을 줄인다.
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = function()
            return require("config.keymaps").bind("marks")
        end,
        opts = {
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
            },
        },
        config = function(_, opts)
            require("harpoon"):setup(opts)
        end,
    },
}
