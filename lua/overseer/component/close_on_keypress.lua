-- 프로세스 종료 후 q/Esc 키로 float 창 닫기
return {
    desc = "Close output window with q/Esc after process exits",
    constructor = function()
        return {
            on_exit = function(_, task)
                local bufnr = task:get_bufnr()
                if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                    return
                end

                vim.schedule(function()
                    if not vim.api.nvim_buf_is_valid(bufnr) then
                        return
                    end

                    -- terminal mode → normal mode 전환
                    local wins = vim.fn.win_findbuf(bufnr)
                    for _, win in ipairs(wins) do
                        if vim.api.nvim_win_is_valid(win) then
                            vim.api.nvim_win_call(win, function()
                                vim.cmd("stopinsert")
                            end)
                        end
                    end

                    -- q, Esc로 창 닫기 키맵 설정
                    for _, key in ipairs({ "q", "<Esc>" }) do
                        vim.keymap.set("n", key, function()
                            for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
                                pcall(vim.api.nvim_win_close, win, true)
                            end
                        end, { buffer = bufnr, nowait = true })
                    end
                end)
            end,
        }
    end,
}
