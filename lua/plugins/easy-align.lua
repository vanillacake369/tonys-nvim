return {
    {
        "junegunn/vim-easy-align",
        event = "VeryLazy",
        keys = {
            -- 비주얼 모드에서 <Enter>를 누르고 정렬 기준 문자(예: =) 입력
            { "ga", "<Plug>(EasyAlign)", mode = { "n", "x" }, desc = "Easy Align" },
            -- n 모드(노멀)에서는 ga + 동작거점(ip 등) + 기준문자 순서로 사용
            { "ga", "<Plug>(EasyAlign)", mode = "n", desc = "Easy Align" },
        },
        config = function()
        end
    },
}
