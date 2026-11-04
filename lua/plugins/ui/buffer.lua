local M = {}

-- 로드·표시 상태와 수정 여부를 먼저 확인해 보호할 버퍼의 파일 조회를 생략한다.
-- 삭제 후보만 경로와 파일 존재를 검증하며 일반 파일 외 버퍼는 보존한다.
local function can_delete_hidden_file(buf, visible_bufs)
    local options = vim.bo[buf]
    local is_candidate = vim.api.nvim_buf_is_loaded(buf)
        and not visible_bufs[buf]
        and options.buflisted
        and options.buftype == ""
        and not options.modified
    if not is_candidate then
        return false
    end

    local name = vim.api.nvim_buf_get_name(buf)
    local is_file_path = name ~= "" and not name:match("^%w[%w+.-]*://")
    return is_file_path and vim.fn.filereadable(name) == 1
end

-- 현재 layout 과 편집 내용을 보호하며 숨은 일반 파일 버퍼만 정리한다.
-- 표시된 버퍼 집합은 한 번 수집하고 삭제 정책은 같은 모듈에서 검증한다.
function M.delete_hidden_files()
    local visible_bufs = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        visible_bufs[vim.api.nvim_win_get_buf(win)] = true
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if can_delete_hidden_file(buf, visible_bufs) then
            Snacks.bufdelete({ buf = buf })
        end
    end
end

-- bufferline 은 버퍼 목록과 진단을 표시하고 Snacks.bufdelete 로 layout 을 유지한다.
-- helper 와 단일 plugin spec 을 같은 모듈에서 공개한다.
M[1] = "akinsho/bufferline.nvim"
M.event = "VeryLazy"
M.keys = function()
    return require("config.keymaps").bind("buffer")
end
M.opts = function(_, opts)
    opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        close_command = function(n)
            Snacks.bufdelete(n)
        end,
        diagnostics = "nvim_lsp",
        offsets = {
            { filetype = "snacks_layout_box" },
        },
        always_show_bufferline = false,
    })
end

return M
