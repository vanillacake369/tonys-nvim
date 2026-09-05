local M = {}

M[1] = "HakonHarnes/img-clip.nvim"
M.event = "VeryLazy"
M.opts = {}
M.keys = function()
    return require("config.keymaps").bind("paste")
end
M.init = function()
    M.setup()
end

local uv = vim.uv or vim.loop

local CONFIG_FILES = {
    "md-rule.toml",
}

local IMAGE_EXTENSIONS = {
    png = true,
    jpg = true,
    jpeg = true,
    gif = true,
    webp = true,
    svg = true,
    bmp = true,
    tiff = true,
    heic = true,
    avif = true,
}

M.cache = {
    resolved_paths = {},
    stats = {
        resolve_hits = 0,
        resolve_misses = 0,
    },
}

local function path_join(...)
    return table
        .concat(
            vim.tbl_filter(function(part)
                return part and part ~= ""
            end, { ... }),
            "/"
        )
        :gsub("//+", "/")
end

local function normalize_path(path)
    return vim.fs.normalize(path)
end

local function file_exists(path)
    return path and uv.fs_stat(path) ~= nil
end

local function is_dir(path)
    local stat = path and uv.fs_stat(path)
    return stat and stat.type == "directory"
end

local function dirname(path)
    return vim.fs.dirname(path)
end

local function basename(path)
    return vim.fn.fnamemodify(path, ":t")
end

local function stem(path)
    return vim.fn.fnamemodify(path, ":t:r")
end

local function read_json(path)
    if vim.fn.filereadable(path) ~= 1 then
        return nil
    end

    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
    if ok and type(decoded) == "table" then
        return decoded
    end

    vim.notify("Markdown asset config JSON parse failed: " .. path, vim.log.levels.WARN)
    return nil
end

local function to_camel_case(key)
    return key:gsub("_([a-z])", function(char)
        return char:upper()
    end)
end

local function parse_toml_value(value)
    value = vim.trim(value)
    if value:sub(1, 1) == "[" and value:sub(-1) == "]" then
        local items = {}
        local body = vim.trim(value:sub(2, -2))
        if body == "" then
            return items
        end
        for item in body:gmatch("[^,]+") do
            item = vim.trim(item):gsub('^"', ""):gsub('"$', "")
            table.insert(items, item)
        end
        return items
    end
    return value:gsub('^"', ""):gsub('"$', "")
end

local function read_toml(path)
    if vim.fn.filereadable(path) ~= 1 then
        return nil
    end

    local data = {}
    local section = nil
    for _, raw_line in ipairs(vim.fn.readfile(path)) do
        local line = vim.trim(raw_line:gsub("#.*$", ""))
        if line ~= "" then
            local section_name = line:match("^%[([A-Za-z0-9_-]+)%]$")
            if section_name then
                section = section_name
                data[section] = data[section] or {}
            else
                local key, value = line:match("^([A-Za-z0-9_-]+)%s*=%s*(.+)$")
                if key and value and section then
                    data[section][to_camel_case(key)] = parse_toml_value(value)
                end
            end
        end
    end

    if not (data.content and data.assets and data.identity) then
        vim.notify("Markdown rule TOML parse failed: " .. path, vim.log.levels.WARN)
        return nil
    end

    return {
        kind = "astro-blog",
        contentRoot = data.content.publicRoot,
        privateContentRoot = data.content.privateRoot,
        publicRoot = "public",
        assetRoot = data.assets.publicRoot,
        privateAssetRoot = data.assets.privateRoot,
        publicUrlPrefix = data.assets.publicUrlPrefix,
        legacyPublicUrlPrefix = data.assets.legacyUrlPrefixes and data.assets.legacyUrlPrefixes[1] or nil,
        identity = data.identity.strategy,
        grammar = data.identity.grammar,
    }
end

local function read_config(path)
    if path:match("%.toml$") then
        return read_toml(path)
    end
    return read_json(path)
end

local function find_repo_config(start)
    -- NOTE: repo-local config 가 있으면 blog fallback 보다 항상 우선한다.
    -- 일반 Markdown repo 에 tonys-blog URL 규칙이 섞이지 않게 막는다.
    local dir = normalize_path(start)
    while dir and dir ~= "" do
        for _, name in ipairs(CONFIG_FILES) do
            local candidate = path_join(dir, name)
            local config = read_config(candidate)
            if config then
                config.root = dir
                config.config_path = candidate
                return config
            end
        end

        local parent = dirname(dir)
        if not parent or parent == dir then
            break
        end
        dir = parent
    end
    return nil
end

local function read_package_name(root)
    local package_json = path_join(root, "package.json")
    local data = read_json(package_json)
    return data and data.name or nil
end

local function find_tonys_blog_root(start)
    -- NOTE: legacy fallback 은 tonys-blog 에만 적용한다.
    -- 구조와 package name 으로 다른 Astro repo 오탐을 막는다.
    local dir = normalize_path(start)
    while dir and dir ~= "" do
        local has_astro = file_exists(path_join(dir, "astro.config.mjs"))
        local has_posts = is_dir(path_join(dir, "src/content/posts/public"))
        local has_public_images = is_dir(path_join(dir, "public/images"))
        if has_astro and has_posts and has_public_images and read_package_name(dir) == "tonys-blog" then
            return dir
        end

        local parent = dirname(dir)
        if not parent or parent == dir then
            break
        end
        dir = parent
    end
    return nil
end

local function sanitize_segment(value, fallback)
    value = vim.trim(value or "")
    value = value:gsub("[%z\r\n\t/\\]", "-")
    value = value:gsub("%s+", "-")
    value = value:gsub("%-+", "-")
    value = value:gsub("^%-+", ""):gsub("%-+$", "")
    if value == "" or value == "." or value == ".." then
        return fallback
    end
    return value
end

local function split_extension(name)
    local base, ext = name:match("^(.*)%.([A-Za-z0-9]+)$")
    if base and ext then
        return base, ext:lower()
    end
    return name, nil
end

local function sanitize_filename(name)
    -- NOTE: clipboard filename 은 Markdown link 와 filesystem 양쪽에 들어간다.
    -- 숨김 파일, 무확장자, 비이미지 확장자는 png 로 정규화.
    local fallback = os.date("%Y-%m-%d-%H-%M-%S")
    local cleaned = sanitize_segment(name, fallback)
    cleaned = cleaned:gsub("^%.+", "")
    if cleaned == "" then
        cleaned = fallback
    end

    local base, ext = split_extension(cleaned)
    if not ext or not IMAGE_EXTENSIONS[ext] then
        ext = "png"
    end

    base = sanitize_segment(base, fallback)
    return base .. "." .. ext
end

local function unique_filename(dir, desired)
    local base, ext = split_extension(desired)
    local candidate = desired
    local index = 2
    while file_exists(path_join(dir, candidate)) do
        candidate = string.format("%s-%d.%s", base, index, ext or "png")
        index = index + 1
    end
    return candidate
end

local function strip_prefix(value, prefix)
    if value:sub(1, #prefix) == prefix then
        return value:sub(#prefix + 1)
    end
    return nil
end

local function split_path(path)
    local parts = {}
    for part in normalize_path(path):gmatch("[^/]+") do
        table.insert(parts, part)
    end
    return parts
end

local function relative_path(from_dir, to_path)
    local from_parts = split_path(from_dir)
    local to_parts = split_path(to_path)
    local index = 1
    while from_parts[index] and to_parts[index] and from_parts[index] == to_parts[index] do
        index = index + 1
    end

    local rel = {}
    for _ = index, #from_parts do
        table.insert(rel, "..")
    end
    for i = index, #to_parts do
        table.insert(rel, to_parts[i])
    end

    if #rel == 0 then
        return "."
    end
    return table.concat(rel, "/")
end

local function path_relative_to_root(root, path)
    local rel = strip_prefix(normalize_path(path), normalize_path(root) .. "/")
    return rel
end

local function is_git_ignored(root, path)
    local rel = path_relative_to_root(root, path)
    if not rel then
        return false
    end

    local result = vim.system({ "git", "-C", root, "check-ignore", "-q", "--", rel }):wait()
    return result and result.code == 0
end

local function buffer_path(bufnr)
    bufnr = bufnr or 0
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
        return nil
    end
    return normalize_path(path)
end

local function is_markdown_buffer(bufnr)
    local ft = vim.bo[bufnr or 0].filetype
    return ft == "markdown" or ft == "mdx"
end

local function file_identity(path)
    return sanitize_segment(stem(path), "untitled")
end

local function path_identity(root, path)
    local rel = strip_prefix(normalize_path(path), normalize_path(root) .. "/")
    if not rel then
        return file_identity(path)
    end

    rel = rel:gsub("%.mdx?$", "")
    local parts = {}
    for part in rel:gmatch("[^/]+") do
        table.insert(parts, sanitize_segment(part, "untitled"))
    end
    return table.concat(parts, "/")
end

local function default_plain_context(path)
    local identity = file_identity(path)
    return {
        kind = "plain-markdown",
        file = path,
        root = dirname(path),
        identity = identity,
        asset_dir = path_join(dirname(path), "assets", identity),
        public_url_prefix = nil,
        plain_link_prefix = "./assets/" .. identity,
    }
end

local function context_from_config(path, config)
    -- NOTE: configured repo 라도 contentRoot 밖 파일에는 repo URL 정책을
    -- 적용하지 않는다. 잘못된 public path 생성을 막는다.
    local root = normalize_path(config.root)
    local private_root = config.privateContentRoot and normalize_path(path_join(root, config.privateContentRoot)) or nil
    local identity = private_root and path_identity(private_root, path) or file_identity(path)

    if is_git_ignored(root, path) then
        local asset_root = config.privateAssetRoot or "private-images/posts"
        local asset_dir = normalize_path(path_join(root, asset_root, identity))
        return {
            kind = "private-markdown",
            file = path,
            root = root,
            config = config,
            identity = identity,
            asset_dir = asset_dir,
            plain_link_prefix = relative_path(dirname(path), asset_dir),
            private = true,
        }
    end

    local content_root = config.contentRoot and normalize_path(path_join(root, config.contentRoot)) or nil
    local kind = config.kind or "configured"

    if content_root then
        local rel = strip_prefix(path, content_root .. "/")
        if not rel then
            return default_plain_context(path)
        end
    end

    identity = content_root and path_identity(content_root, path) or file_identity(path)
    local asset_root = config.assetRoot or "assets"
    local asset_dir = normalize_path(path_join(root, asset_root, identity))
    local url_prefix = config.publicUrlPrefix

    return {
        kind = kind,
        file = path,
        root = root,
        config = config,
        identity = identity,
        asset_dir = asset_dir,
        public_root = config.publicRoot and normalize_path(path_join(root, config.publicRoot)) or nil,
        public_url_prefix = url_prefix,
        legacy_public_url_prefix = config.legacyPublicUrlPrefix,
        markdown_link_prefix = url_prefix and (url_prefix:gsub("/$", "") .. "/" .. identity) or nil,
    }
end

local function context_from_tonys_blog(path, root)
    local posts_root = normalize_path(path_join(root, "src/content/posts/public"))
    if not strip_prefix(path, posts_root .. "/") then
        return default_plain_context(path)
    end

    local identity = path_identity(posts_root, path)
    return {
        kind = "tonys-blog-fallback",
        file = path,
        root = root,
        identity = identity,
        asset_dir = path_join(root, "public/images/posts", identity),
        public_root = path_join(root, "public"),
        public_url_prefix = "/images/posts",
        legacy_public_url_prefix = "/images",
        markdown_link_prefix = "/images/posts/" .. identity,
    }
end

function M.get_context(bufnr)
    local path = buffer_path(bufnr)
    if not path then
        return nil
    end

    return M.get_context_for_path(path)
end

function M.get_context_for_path(path)
    path = normalize_path(path)

    -- NOTE: 우선순위는 explicit config -> tonys-blog fallback -> plain Markdown.
    -- 새 repo 는 md-rule.toml 로 정책을 명시하는 쪽이 안전하다.
    local config = find_repo_config(dirname(path))
    if config then
        return context_from_config(path, config)
    end

    local tonys_root = find_tonys_blog_root(dirname(path))
    if tonys_root then
        return context_from_tonys_blog(path, tonys_root)
    end

    return default_plain_context(path)
end

local function markdown_link_for(ctx, image_path)
    image_path = normalize_path(image_path)

    -- NOTE: 저장 위치가 asset_dir 안이면 repo 정책 URL 을 사용한다.
    -- 밖에 저장된 파일은 Neovim 의 상대경로 계산으로 fallback 한다.
    if ctx.markdown_link_prefix and strip_prefix(image_path, normalize_path(ctx.asset_dir) .. "/") then
        return ctx.markdown_link_prefix .. "/" .. basename(image_path)
    end

    if ctx.plain_link_prefix and strip_prefix(image_path, normalize_path(ctx.asset_dir) .. "/") then
        return ctx.plain_link_prefix .. "/" .. basename(image_path)
    end

    local rel = vim.fn.fnamemodify(image_path, ":~:.")
    if ctx.file then
        rel = vim.fn.fnamemodify(image_path, ":p:~:.")
    end
    return rel
end

M.markdown_link_for = markdown_link_for

local function paste_image_file(ctx, filename, alt)
    local ok, pasted = pcall(function()
        return require("img-clip").paste_image({
            dir_path = ctx.asset_dir,
            file_name = filename,
            extension = select(2, split_extension(filename)) or "png",
            prompt_for_file_name = false,
            use_absolute_path = true,
            relative_to_current_file = false,
            relative_template_path = false,
            template = function(template_ctx)
                local saved_path = template_ctx.file_path or template_ctx.path or path_join(ctx.asset_dir, filename)
                return string.format("![%s](%s)", alt, markdown_link_for(ctx, saved_path))
            end,
        })
    end)

    if not ok then
        vim.notify("img-clip failed: " .. tostring(pasted), vim.log.levels.ERROR)
        return
    end

    if not pasted then
        vim.notify("clipboard에 붙여넣을 이미지가 없습니다.", vim.log.levels.WARN)
    end
end

function M.paste_image()
    if not is_markdown_buffer(0) then
        vim.notify("Markdown buffer에서만 이미지 paste workflow를 사용합니다.", vim.log.levels.WARN)
        return
    end

    local ctx = M.get_context(0)
    if not ctx then
        vim.notify(
            "현재 buffer path를 확인할 수 없습니다. 파일을 먼저 저장하세요.",
            vim.log.levels.ERROR
        )
        return
    end

    vim.fn.mkdir(ctx.asset_dir, "p")

    Snacks.input({
        prompt = "Image file name",
        default = os.date("%Y-%m-%d-%H-%M-%S") .. ".png",
    }, function(file_value)
        if file_value == nil then
            return
        end

        local filename = unique_filename(ctx.asset_dir, sanitize_filename(file_value))
        Snacks.input({
            prompt = "Alt text",
            default = stem(filename):gsub("%-", " "),
        }, function(alt_value)
            if alt_value ~= nil then
                paste_image_file(ctx, filename, (alt_value or ""):gsub("[%[%]\r\n]", " "))
            end
        end)
    end)
end

local function url_decode(value)
    value = value:gsub("+", " ")
    return (value:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

local function is_external_target(target)
    return target:match("^%a[%w+.-]*://") or target:match("^mailto:")
end

local function trim_link_target(target)
    target = vim.trim(target or "")
    local angle_target = target:match("^<(.+)>$")
    if angle_target then
        return url_decode(angle_target)
    end

    target = target:match("^(.-)%s+[\"'].*[\"']%s*$") or target
    return url_decode(target)
end

function M.resolve_target_for_path(target, path)
    -- NOTE: Markdown target 을 에디터에서 열 수 있는 local file 로 해석.
    -- absolute path, public URL prefix, 현재 파일 상대경로만 허용한다.
    target = trim_link_target(target)
    if target == "" then
        return nil, "empty target"
    end

    if is_external_target(target) then
        return { kind = "external", target = target }
    end

    if not path then
        return nil, "기준 file path를 확인할 수 없습니다."
    end
    path = normalize_path(path)

    local ctx = M.get_context_for_path(path)
    if target:sub(1, 1) == "/" then
        if file_exists(target) then
            return { kind = "file", path = normalize_path(target), target = target }
        end

        if ctx and ctx.public_root then
            -- WARN: map site-root URLs like `/images/...` only when publicRoot
            -- is explicit. Reject arbitrary root URLs instead of guessing.
            local prefixes = vim.tbl_filter(function(v)
                return v and v ~= ""
            end, { ctx.public_url_prefix, ctx.legacy_public_url_prefix })
            for _, prefix in ipairs(prefixes) do
                prefix = prefix:gsub("/$", "")
                if target == prefix or target:sub(1, #prefix + 1) == prefix .. "/" then
                    local public_rel = target:sub(2)
                    return {
                        kind = "file",
                        path = normalize_path(path_join(ctx.public_root, public_rel)),
                        target = target,
                    }
                end
            end
        end

        return nil, "site-root URL은 현재 repo 정책에서 local file로 해석되지 않습니다: " .. target
    end

    local resolved = normalize_path(path_join(dirname(path), target))
    return { kind = "file", path = resolved, target = target }
end

function M.resolve_target(target, bufnr)
    local path = buffer_path(bufnr)
    if not path then
        return nil, "현재 buffer path를 확인할 수 없습니다."
    end
    return M.resolve_target_for_path(target, path)
end

local function link_under_cursor()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local patterns = {
        "()!%[[^%]]-%]%(([^%)]+)%)()",
        "()%[[^%]]-%]%(([^%)]+)%)()",
    }

    for _, pattern in ipairs(patterns) do
        for start_pos, target, end_pos in line:gmatch(pattern) do
            if col >= start_pos and col <= end_pos then
                return target
            end
        end
    end

    return vim.fn.expand("<cfile>")
end

local function open_file(path)
    if not file_exists(path) then
        vim.notify("파일을 찾을 수 없습니다: " .. path, vim.log.levels.ERROR)
        return
    end
    vim.cmd.edit(vim.fn.fnameescape(path))
    local _, ext = split_extension(path)
    if ext and IMAGE_EXTENSIONS[ext] then
        vim.bo.filetype = "image"
    end
end

function M.open_link_under_cursor()
    local target = link_under_cursor()
    local resolved, err = M.resolve_target(target, 0)
    if not resolved then
        vim.notify(err or ("링크를 해석할 수 없습니다: " .. tostring(target)), vim.log.levels.ERROR)
        return
    end

    if resolved.kind == "external" then
        if vim.ui.open then
            vim.ui.open(resolved.target)
        else
            vim.notify("외부 URL: " .. resolved.target, vim.log.levels.INFO)
        end
        return
    end

    open_file(resolved.path)
end

function M.resolve_for_snacks(file, src)
    if file and file ~= "" then
        -- PERF: Snacks image resolver 는 render/scroll 중 반복 호출된다.
        -- 실패도 false 로 캐시해 깨진 링크를 반복 stat 하지 않는다.
        local key = normalize_path(file) .. "\n" .. tostring(src)
        local cached = M.cache.resolved_paths[key]
        if cached ~= nil then
            M.cache.stats.resolve_hits = M.cache.stats.resolve_hits + 1
            return cached ~= false and cached or nil
        end

        M.cache.stats.resolve_misses = M.cache.stats.resolve_misses + 1
        local resolved = M.resolve_target_for_path(src, file)
        if resolved and resolved.kind == "file" then
            M.cache.resolved_paths[key] = resolved.path
            return resolved.path
        end
        M.cache.resolved_paths[key] = false
    end

    local resolved = M.resolve_target(src, 0)
    if resolved and resolved.kind == "file" then
        return resolved.path
    end
    return nil
end

function M.clear_caches(bufnr)
    if not bufnr then
        M.cache.resolved_paths = {}
        M.cache.stats.resolve_hits = 0
        M.cache.stats.resolve_misses = 0
        return
    end

    local path = buffer_path(bufnr)
    if not path then
        return
    end

    local prefix = normalize_path(path) .. "\n"
    for key in pairs(M.cache.resolved_paths) do
        if key:sub(1, #prefix) == prefix then
            M.cache.resolved_paths[key] = nil
        end
    end
end

function M.cache_stats()
    local entries = 0
    for _ in pairs(M.cache.resolved_paths) do
        entries = entries + 1
    end
    return {
        resolve_hits = M.cache.stats.resolve_hits,
        resolve_misses = M.cache.stats.resolve_misses,
        resolve_entries = entries,
    }
end

local function collect_headings(bufnr)
    -- NOTE: preview/outline 용 heading 만 수집한다.
    -- frontmatter 와 fenced code 안의 # 문자는 문서 구조에서 제외한다.
    bufnr = bufnr or 0
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local headings = {}
    local in_frontmatter = false
    local in_fence = false

    for index, line in ipairs(lines) do
        if index == 1 and line:match("^%-%-%-%s*$") then
            in_frontmatter = true
        elseif in_frontmatter and line:match("^%-%-%-%s*$") then
            in_frontmatter = false
        elseif not in_frontmatter then
            if line:match("^```") or line:match("^~~~") then
                in_fence = not in_fence
            elseif not in_fence then
                local hashes, title = line:match("^(#+)%s+(.+)%s*$")
                if hashes and title and #hashes <= 6 then
                    title = title:gsub("%s+#+%s*$", "")
                    table.insert(headings, {
                        line = index,
                        level = #hashes,
                        title = title,
                        text = string.rep("  ", #hashes - 1) .. title,
                    })
                end
            end
        end
    end

    return headings
end

local function get_snacks()
    local ok, snacks = pcall(require, "snacks")
    if ok then
        return snacks
    end
    return nil
end

function M.open_heading_outline()
    local headings = collect_headings(0)
    if #headings == 0 then
        vim.notify("현재 문서에 Markdown heading이 없습니다.", vim.log.levels.INFO)
        return
    end

    local snacks = get_snacks()
    if snacks and snacks.picker then
        local items = {}
        for _, heading in ipairs(headings) do
            table.insert(items, {
                text = string.format("%4d  %s", heading.line, heading.text),
                line = heading.line,
                idx = heading.line,
                sort = heading.line,
                heading = heading,
            })
        end

        snacks.picker({
            title = "Markdown Headings",
            items = items,
            format = "text",
            -- NOTE: 빈 query 는 preview 와 같은 문서 순서를 유지한다.
            -- fuzzy match 결과가 있을 때만 표시 범위를 좁힌다.
            matcher = { sort = false },
            sort = { fields = { "sort" } },
            confirm = function(picker, item)
                picker:close()
                if item then
                    vim.api.nvim_win_set_cursor(0, { item.line, 0 })
                    vim.cmd("normal! zz")
                end
            end,
        })
        return
    end

    vim.ui.select(headings, {
        prompt = "Markdown heading",
        format_item = function(item)
            return string.format("%4d  %s", item.line, item.text)
        end,
    }, function(item)
        if item then
            vim.api.nvim_win_set_cursor(0, { item.line, 0 })
            vim.cmd("normal! zz")
        end
    end)
end

local function encode_url_path(path)
    return (
        path:gsub("([^A-Za-z0-9%-%._~/])", function(char)
            return string.format("%%%02X", string.byte(char))
        end)
    )
end

function M.open_astro_preview()
    local ctx = M.get_context(0)
    if not ctx or not ctx.root or not ctx.file or not ctx.kind:match("astro") and not ctx.kind:match("tonys%-blog") then
        vim.notify("Astro blog context가 아닙니다.", vim.log.levels.WARN)
        return
    end

    local content_root = path_join(ctx.root, ctx.config and ctx.config.contentRoot or "src/content/posts/public")
    local rel = strip_prefix(ctx.file, normalize_path(content_root) .. "/")
    if not rel then
        vim.notify("현재 파일이 posts content root 아래에 없습니다.", vim.log.levels.WARN)
        return
    end

    rel = rel:gsub("%.mdx?$", "")
    local url = "http://localhost:4321/posts/" .. encode_url_path(rel)
    if vim.ui.open then
        vim.ui.open(url)
    else
        vim.notify("Astro preview URL: " .. url, vim.log.levels.INFO)
    end
end

function M.setup()
    for _, command in ipairs({
        { "MarkdownPasteImage", M.paste_image },
        { "MarkdownOpenAsset", M.open_link_under_cursor },
        { "MarkdownHeadingOutline", M.open_heading_outline },
        { "MarkdownAstroPreview", M.open_astro_preview },
        {
            "MarkdownAssetClearCache",
            function()
                M.clear_caches(0)
            end,
        },
    }) do
        vim.api.nvim_create_user_command(command[1], command[2], {})
    end

    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "mdx" },
        group = vim.api.nvim_create_augroup("MarkdownAssetWorkflow", { clear = true }),
        callback = function(args)
            local opts = { buffer = args.buf, silent = true }
            for _, keymap in ipairs({
                { "gf", M.open_link_under_cursor, "Open Markdown asset under cursor" },
                { "<leader>mo", M.open_heading_outline, "Markdown heading outline" },
                { "<leader>mr", "<cmd>MarkdownRenderToggle<cr>", "Markdown inline render toggle" },
                { "<leader>mP", M.open_astro_preview, "Open Astro browser preview" },
            }) do
                vim.keymap.set("n", keymap[1], keymap[2], vim.tbl_extend("force", opts, { desc = keymap[3] }))
            end
        end,
    })
end

return M
