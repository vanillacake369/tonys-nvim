local M = {}

local function excluded_dirnames(opts)
    local excluded = {}
    for _, name in ipairs((opts and opts.exclude_dirnames) or {}) do
        excluded[name] = true
    end
    return excluded
end

function M.find_case_insensitive(root, target_name, opts)
    local matches = {}
    local excluded = excluded_dirnames(opts)
    local expected = target_name:lower()

    local function walk(dir)
        local iterator = vim.fs.dir(dir)
        if not iterator then
            return
        end

        for name, entry_type in iterator do
            local path = vim.fs.joinpath(dir, name)
            if entry_type == "directory" and not excluded[name] then
                walk(path)
            elseif entry_type == "file" and name:lower() == expected then
                table.insert(matches, path)
            end
        end
    end

    walk(root)
    table.sort(matches)
    return matches
end

function M.enable_case_insensitive_lookup()
    local fs = require("mybatis.util.fs")
    if fs._case_insensitive_lookup_enabled then
        return
    end

    local find_files_by_name = fs.find_files_by_name
    fs.find_files_by_name = function(root, name, opts)
        local matches = find_files_by_name(root, name, opts)
        if #matches > 0 then
            return matches
        end
        return M.find_case_insensitive(root, name, opts)
    end
    fs._case_insensitive_lookup_enabled = true
end

return M
