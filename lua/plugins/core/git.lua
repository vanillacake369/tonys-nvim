-- Git workflow 와 plugin spec 은 여기서 소유하고 keymap registry 는 호출만 한다.
local M = {}

function M.review_working_tree()
    require("diffview").open({})
end

local function run(argv, cwd, timeout, callback)
    local ok, err = pcall(vim.system, argv, { cwd = cwd, text = true, timeout = timeout }, vim.schedule_wrap(callback))
    if not ok then
        vim.notify("Git 리뷰 명령을 실행할 수 없습니다: " .. tostring(err), vim.log.levels.ERROR)
    end
end

-- GitHub 조회는 비동기로 실행하고 호출 시점의 cwd 를 Diffview 까지 유지한다.
-- base OID 를 사용하면 fork 의 origin/upstream 이름에 의존하지 않는다.
-- object 가 없으면 fetch 를 안내하고 사용자의 remote ref 를 자동 변경하지 않는다.
function M.review_current_pr()
    if vim.fn.executable("gh") ~= 1 then
        vim.notify("현재 PR을 조회하려면 GitHub CLI(gh)가 필요합니다.", vim.log.levels.ERROR)
        return
    end

    local cwd = vim.fn.getcwd()
    run({ "gh", "pr", "view", "--json", "baseRefName,baseRefOid" }, cwd, 10000, function(result)
        if result.code ~= 0 then
            local detail = result.code == 124 and "조회 시간이 초과되었습니다."
                or vim.trim(result.stderr or "")
            vim.notify("현재 브랜치의 PR base를 확인할 수 없습니다. " .. detail, vim.log.levels.ERROR)
            return
        end

        local ok, pr = pcall(vim.json.decode, result.stdout or "")
        if
            not ok
            or type(pr) ~= "table"
            or type(pr.baseRefName) ~= "string"
            or pr.baseRefName == ""
            or type(pr.baseRefOid) ~= "string"
            or not pr.baseRefOid:match("^[0-9a-fA-F]+$")
            or (#pr.baseRefOid ~= 40 and #pr.baseRefOid ~= 64)
        then
            vim.notify("PR base 커밋 정보가 올바르지 않습니다.", vim.log.levels.ERROR)
            return
        end

        run({ "git", "cat-file", "-e", pr.baseRefOid .. "^{commit}" }, cwd, 1000, function(base_result)
            if base_result.code ~= 0 then
                vim.notify(
                    "PR base 커밋을 로컬에서 확인할 수 없습니다. base 저장소의 "
                        .. pr.baseRefName
                        .. " 브랜치를 git fetch 한 뒤 다시 시도하세요.",
                    vim.log.levels.ERROR
                )
                return
            end

            require("diffview").open({ "-C" .. cwd, pr.baseRefOid .. "...HEAD", "--imply-local" })
        end)
    end)
end

function M.reset_buffer()
    local file = vim.fn.expand("%:t")
    local choice = vim.fn.confirm(
        string.format("Discard all unstaged changes in %s?", file ~= "" and file or "current buffer"),
        "&Yes\n&No",
        2
    )

    if choice == 1 then
        require("gitsigns").reset_buffer()
    end
end

local function is_review_key(item)
    return item[1] == "<leader>gD" or item[1] == "<leader>gP"
end

-- Git hunk 상태를 signcolumn 에 표시하고 hunk 단위 조작을 하기 위해 추가.
-- 버퍼를 열 때 붙여서 변경 라인을 바로 확인할 수 있게 한다.
M[1] = {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = function()
        return require("config.keymaps").bind({
            group = "git",
            filter = function(item)
                return not is_review_key(item)
            end,
        })
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
}
-- 여러 파일의 변경을 한 탭에서 검토하고 merge/rebase 충돌을 해소한다.
-- 현재 buffer hunk 조작은 위 Gitsigns spec이 계속 소유한다.
M[2] = {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = function()
        return require("config.keymaps").bind({
            group = "git",
            filter = is_review_key,
        })
    end,
    opts = {
        hooks = {
            view_post_layout = function(view)
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(view.tabpage)) do
                    if vim.wo[win].diff then
                        vim.wo[win].scrollbind = true
                    end
                end
            end,
        },
        -- Diffview는 popup이 아닌 tabpage라 기본 q 종료 key가 없다.
        -- help/option panel의 기존 q는 panel만 닫으므로 그대로 둔다.
        keymaps = {
            view = {
                { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
            },
            file_panel = {
                { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
            },
            file_history_panel = {
                { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
            },
        },
    },
}

return M
