local M = {}

local LOCAL_RULES_MODULE = "config.conventions_local"

local loaded_packs = {}
local setup_packs = {}
local warned = {}

-- local convention 설정은 host 마다 다르므로 실패해도 저장 흐름을 막지 않는다.
-- 같은 오류를 반복 알림하지 않도록 key 단위로 한 번만 경고한다.
local function warn_once(key, message)
    if warned[key] then
        return
    end
    warned[key] = true
    vim.schedule(function()
        vim.notify(message, vim.log.levels.WARN)
    end)
end

-- buffer path 와 cwd fallback 은
-- resolver 내부에서 항상 normalize 된 절대 경로로 다룬다.
-- local rule 의 `~` 확장은 root glob 처리에서 별도로 수행한다.
local function normalize(path)
    if not path or path == "" then
        return nil
    end
    return vim.fs.normalize(vim.fn.expand(path))
end

-- `vim.fn.expand("~/dev/vpp-*")`는 `*`까지 실제 파일 glob 으로 풀어버린다.
-- root rule 은 존재하지 않는 새 repo 도 매칭해야 하므로 home 만 직접 확장한다.
local function expand_home(path)
    if path == "~" then
        return vim.uv.os_homedir()
    end
    if path:sub(1, 2) == "~/" then
        return vim.uv.os_homedir() .. path:sub(2)
    end
    return path
end

-- 이름 없는 scratch buffer 에서도 cwd 기준 convention 을 사용할 수 있게 한다.
local function buffer_path(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr or 0)
    return normalize(name ~= "" and name or vim.uv.cwd())
end

-- host-local rule 파일은 선택 사항이다. 없으면 tracked 기본 설정만 사용한다.
local function read_local_rules()
    local ok, rules = pcall(require, LOCAL_RULES_MODULE)
    if ok and type(rules) == "table" then
        return rules
    end
    if not ok and not tostring(rules):find("module '" .. LOCAL_RULES_MODULE .. "' not found", 1, true) then
        warn_once(LOCAL_RULES_MODULE, "Failed to load local convention rules: " .. tostring(rules))
    end
    return {}
end

-- 사용자 표면은 glob-like `~/dev/vpp-*`로 두고,
-- 내부에서는 Lua pattern 으로 변환한다.
-- `*`는 path segment 안에서만 매칭되도록 `/`를 제외한다.
local function glob_pattern(pattern)
    local expanded = vim.fs.normalize(expand_home(pattern))
    if not expanded then
        return nil
    end

    local escaped = expanded:gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1")
    escaped = escaped:gsub("%*", "[^/]*")
    return "^" .. escaped
end

-- root rule 은 빠른 opt-in fallback 이다. marker 를 둘 수 없는 repo 나 아직
-- checkout 되지 않은 경로도 host convention 으로 분류할 수 있다.
local function matches_root(path, roots)
    if type(roots) ~= "table" then
        return false
    end
    for _, root in ipairs(roots) do
        local pattern = glob_pattern(root)
        if pattern and path:match(pattern) then
            return true
        end
    end
    return false
end

-- marker 는 `.gitignore` 같은 표식 파일/디렉토리다. buffer 위치에서 위로
-- 올라가며 찾고, 발견되면 해당 subtree 전체에 convention 을 적용한다.
local function matches_marker(path, markers)
    if type(markers) ~= "table" or vim.tbl_isempty(markers) then
        return false
    end

    local stat = vim.uv.fs_stat(path)
    local start = stat and stat.type == "directory" and path or vim.fs.dirname(path)
    return vim.fs.find(markers, { path = start, upward = true, limit = 1 })[1] ~= nil
end

-- local rules 는 위에서 아래로 평가한다. 더 구체적인 workspace rule 을 먼저
-- 적으면 그 rule 이 넓은 fallback rule 보다 우선한다.
function M.match(bufnr)
    local path = buffer_path(bufnr)
    if not path then
        return nil
    end

    for _, rule in ipairs(read_local_rules()) do
        if type(rule) == "table" and (rule.roots or rule.markers) then
            if matches_root(path, rule.roots) or matches_marker(path, rule.markers) then
                return rule
            end
        end
    end
    return nil
end

-- convention pack 은 local-only 모듈일 수 있으므로 동적으로 로드한다.
-- 실패한 모듈도 캐시해서 같은 require 실패를 반복하지 않는다.
local function load_pack(rule)
    if not rule or not rule.module then
        return nil
    end

    if loaded_packs[rule.module] ~= nil then
        return loaded_packs[rule.module]
    end

    local ok, pack = pcall(require, rule.module)
    if not ok then
        warn_once(rule.module, "Failed to load convention pack `" .. rule.module .. "`: " .. tostring(pack))
        loaded_packs[rule.module] = false
        return nil
    end

    loaded_packs[rule.module] = pack
    return pack
end

-- pack setup 은 formatter/linter definition 등록처럼 전역 상태를 만진다.
-- resolver 가 여러 번 호출되어도 pack module 별로 한 번만 실행한다.
local function setup_pack(rule, pack)
    if not pack or type(pack.setup) ~= "function" or setup_packs[rule.module] then
        return pack ~= false
    end

    local ok, err = pcall(pack.setup)
    if not ok then
        warn_once(rule.module .. ":setup", "Failed to setup convention pack `" .. rule.module .. "`: " .. tostring(err))
        return false
    end

    setup_packs[rule.module] = true
    return true
end

-- formatter/linter lookup 은 같은 경로를 공유한다.
-- 매칭된 pack 이 filetype 을 제공하지 않거나 실패하면
-- caller 가 넘긴 tracked fallback 을 그대로 쓴다.
local function resolve(bufnr, filetype, fallback, field)
    local rule = M.match(bufnr)
    local pack = load_pack(rule)
    if pack and setup_pack(rule, pack) then
        local by_ft = pack[field]
        local names = type(by_ft) == "table" and by_ft[filetype] or nil
        if names then
            return names
        end
    end
    return fallback
end

-- conform.nvim 의 filetype formatter 함수에서 호출한다.
function M.formatters(bufnr, filetype, fallback)
    return resolve(bufnr, filetype, fallback, "formatters_by_ft")
end

-- nvim-lint autocmd 에서 현재 buffer 에 실행할 linter list 를 고를 때 호출한다.
function M.linters(bufnr, filetype, fallback)
    return resolve(bufnr, filetype, fallback, "linters_by_ft")
end

return M
