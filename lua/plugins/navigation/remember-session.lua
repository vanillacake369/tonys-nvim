return {
    "rmagatti/auto-session",
    lazy = false,
    dependencies = {},
    config = function()
        -- WARN:
        -- unloaded buffer 를 강제로 bufload 하면 swap 경고와 LSP 재스캔이 다시 발생할 수 있다.
        -- 세션 복원 후 attach 대상은 이미 로드된 일반 파일 buffer 로만 제한한다.
        local function is_loaded_file_buffer(buf)
            if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
                return false
            end

            local name = vim.api.nvim_buf_get_name(buf)
            return name ~= ""
                and vim.api.nvim_get_option_value("buftype", { buf = buf }) == ""
                and vim.fn.filereadable(name) == 1
        end

        -- auto-session 이 복원한 buffer 는 BufRead/FileType 흐름을 놓칠 수 있어
        -- LSP lazy-load, ftplugin, treesitter attach 이벤트만 다시 트리거한다.
        local function attach_restored_buffer(buf)
            if not is_loaded_file_buffer(buf) then
                return
            end

            pcall(vim.api.nvim_exec_autocmds, "BufReadPost", {
                buffer = buf,
                modeline = false,
            })

            if vim.api.nvim_get_option_value("filetype", { buf = buf }) ~= "" then
                pcall(vim.api.nvim_exec_autocmds, "FileType", {
                    buffer = buf,
                    modeline = false,
                })
            end

            pcall(vim.treesitter.start, buf)
        end

        -- restore 직후 한 tick 늦춰 실행해야 lazy.nvim 과 session window 복원이
        -- 안정화된다. lazy 가능하다면 BufReadPre 를 놓친 session buffer 에도
        -- lspconfig 설정을 먼저 로드한다.
        local function attach_restored_buffers()
            vim.schedule(function()
                local lazy_ok, lazy = pcall(require, "lazy")
                if lazy_ok then
                    pcall(lazy.load, { plugins = { "nvim-lspconfig" } })
                end

                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    attach_restored_buffer(buf)
                end
            end)
        end

        require("auto-session").setup({
            suppressed_dirs = {
                "~/",
                "~/Projects",
                "~/Downloads",
                "/",
                -- vim.fn.stdpath("config"),
            },
            post_restore_cmds = {
                attach_restored_buffers,
            },
        })
    end,
}
