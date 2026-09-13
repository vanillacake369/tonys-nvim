-- debugger.lua 는 debugger tool 탐색, Java JDT LS bundle 선별, keymap-facing
-- debug helper, nvim-dap plugin spec 을 한 파일에 모은다.
-- 언어별 plugin 은 이 module 의 얇은 public API 만 호출하고, 실제 provider 선택과
-- 진단 정보는 여기서 일관되게 관리한다.

local M = {}

local manifest_cache = {}
local runtime_bundle_cache = {}
local last_selection

local function readable(path)
    return path and path ~= "" and vim.fn.filereadable(path) == 1
end

local function executable(path)
    return path and path ~= "" and vim.fn.executable(path) == 1
end

local function directory(path)
    return path and path ~= "" and vim.fn.isdirectory(path) == 1
end

local function resolve_path(path)
    return path and path ~= "" and vim.fn.resolve(vim.fn.expand(path)) or nil
end

local function glob_all(patterns)
    local result = {}
    local seen = {}
    for _, pattern in ipairs(patterns) do
        for _, match in ipairs(vim.fn.glob(pattern, true, true)) do
            local resolved = resolve_path(match)
            if resolved and not seen[resolved] then
                seen[resolved] = true
                table.insert(result, resolved)
            end
        end
    end
    table.sort(result)
    return result
end

local function first_file(patterns)
    for _, path in ipairs(glob_all(patterns)) do
        if readable(path) or executable(path) then
            return path
        end
    end
    return nil
end

local function source_result(path, source)
    if not path then
        return nil
    end
    return {
        path = path,
        source = source,
    }
end

-- debugger 실행 파일은 PATH, Nix profile, repo-local 후보, Nix store glob 순서로 찾는다.
-- 각 결과에는 source label 을 붙여 `:DebugInfo` 에서 어떤 provider 가 선택됐는지
-- 바로 확인할 수 있게 한다.
function M.resolve_executable(name, opts)
    opts = opts or {}

    local path = vim.fn.exepath(name)
    if executable(path) then
        return source_result(path, "path")
    end

    path = first_file(opts.profile_paths or {})
    if executable(path) then
        return source_result(path, "nix-profile")
    end

    path = first_file(opts.repo_paths or {})
    if executable(path) then
        return source_result(path, opts.repo_source or "repo")
    end

    path = first_file(opts.store_globs or {})
    if executable(path) then
        return source_result(path, "nix-store")
    end

    return nil
end

function M.resolve_codelldb()
    return M.resolve_executable("codelldb", {
        profile_paths = {
            "~/.nix-profile/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb",
        },
        store_globs = {
            "/nix/store/*-vscode-extension-vadimcn-vscode-lldb-*/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb",
        },
    })
end

function M.resolve_lldb_dap()
    return M.resolve_executable("lldb-dap")
end

function M.resolve_js_debug()
    return M.resolve_executable("js-debug", {
        profile_paths = {
            "~/.nix-profile/bin/js-debug",
        },
        store_globs = {
            "/nix/store/*-vscode-js-debug-*/bin/js-debug",
        },
    })
end

-- Java debug/test bundle 은 VSCode extension JAR 이 JDT LS runtime 과 호환될 때만
-- init_options.bundles 로 넘긴다.
-- JAR manifest 의 Require-Bundle / Import-Package range 를 읽어 ASM 같은 runtime
-- dependency version mismatch 를 startup 전에 걸러낸다.
local function read_json(path)
    if not readable(path) then
        return nil
    end

    local ok, decoded = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(path), "\n"))
    return ok and decoded or nil
end

local function jar_manifest(path)
    if manifest_cache[path] ~= nil then
        return manifest_cache[path]
    end

    local lines = vim.fn.systemlist({ "unzip", "-p", path, "META-INF/MANIFEST.MF" })
    if vim.v.shell_error ~= 0 or vim.tbl_isempty(lines) then
        manifest_cache[path] = false
        return false
    end

    local unfolded = {}
    for _, line in ipairs(lines) do
        line = line:gsub("\r$", "")
        if line:sub(1, 1) == " " and #unfolded > 0 then
            unfolded[#unfolded] = unfolded[#unfolded] .. line:sub(2)
        else
            table.insert(unfolded, line)
        end
    end

    local manifest = {}
    for _, line in ipairs(unfolded) do
        local key, value = line:match("^([^:]+):%s*(.*)$")
        if key then
            manifest[key] = value
        end
    end

    manifest_cache[path] = manifest
    return manifest
end

local function bundle_symbolic_name(manifest)
    local name = manifest and manifest["Bundle-SymbolicName"]
    return name and name:match("^([^;]+)")
end

local function bundle_version(manifest)
    return manifest and manifest["Bundle-Version"]
end

local function split_manifest_list(value)
    local items = {}
    local start = 1
    local quoted = false

    for i = 1, #value do
        local char = value:sub(i, i)
        if char == '"' then
            quoted = not quoted
        elseif char == "," and not quoted then
            table.insert(items, vim.trim(value:sub(start, i - 1)))
            start = i + 1
        end
    end

    table.insert(items, vim.trim(value:sub(start)))
    return items
end

local function version_parts(version)
    local major, minor, patch = tostring(version):match("^(%d+)%.(%d+)%.(%d+)")
    return { tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0 }
end

local function compare_versions(left, right)
    local a = version_parts(left)
    local b = version_parts(right)
    for i = 1, 3 do
        if a[i] ~= b[i] then
            return a[i] < b[i] and -1 or 1
        end
    end
    return 0
end

local function version_in_range(version, range)
    if not range or range == "" then
        return true
    end

    local open, lower, upper, close = range:match("^([%[%(%]])%s*([^,%]]+)%s*,%s*([^,%]]+)%s*([%)%]])$")
    if not open then
        return compare_versions(version, range) >= 0
    end

    local lower_cmp = compare_versions(version, lower)
    local upper_cmp = compare_versions(version, upper)
    return (open == "[" and lower_cmp >= 0 or lower_cmp > 0) and (close == "]" and upper_cmp <= 0 or upper_cmp < 0)
end

local function manifest_attributes(manifest, key)
    local value = manifest and manifest[key]
    if not value then
        return {}
    end

    local result = {}
    for _, item in ipairs(split_manifest_list(value)) do
        local name = item:match("^([^;]+)")
        if name then
            table.insert(result, {
                name = name,
                range = item:match('bundle%-version%s*=%s*"([^"]+)"')
                    or item:match('version%s*=%s*"([^"]+)"')
                    or item:match("bundle%-version%s*=%s*([^;]+)")
                    or item:match("version%s*=%s*([^;]+)"),
            })
        end
    end
    return result
end

local function jdtls_plugins_dir()
    local jdtls = vim.fn.exepath("jdtls")
    if jdtls == "" then
        return nil
    end

    local prefix = vim.fn.fnamemodify(vim.fn.resolve(jdtls), ":h:h")
    for _, dir in ipairs({
        prefix .. "/plugins",
        prefix .. "/share/java/jdtls/plugins",
        prefix .. "/share/jdtls/plugins",
    }) do
        if directory(dir) then
            return dir
        end
    end

    return nil
end

local function runtime_bundle_version(name)
    if runtime_bundle_cache[name] ~= nil then
        return runtime_bundle_cache[name] or nil
    end

    local plugins_dir = jdtls_plugins_dir()
    if not plugins_dir then
        runtime_bundle_cache[name] = false
        return nil
    end

    for _, jar in ipairs(vim.fn.glob(plugins_dir .. "/" .. name .. "_*.jar", true, true)) do
        local version = bundle_version(jar_manifest(jar))
        if version then
            runtime_bundle_cache[name] = version
            return version
        end
    end

    runtime_bundle_cache[name] = false
    return nil
end

local function compatible_jdtls_bundle(path)
    local manifest = jar_manifest(path)
    if not bundle_symbolic_name(manifest) then
        return false
    end

    for _, requirement in ipairs(manifest_attributes(manifest, "Require-Bundle")) do
        local provided_version = runtime_bundle_version(requirement.name)
        if provided_version and requirement.range and not version_in_range(provided_version, requirement.range) then
            return false,
                string.format(
                    "%s requires %s %s, but JDT LS provides %s",
                    vim.fn.fnamemodify(path, ":t"),
                    requirement.name,
                    requirement.range,
                    provided_version
                )
        end
    end

    for _, imported in ipairs(manifest_attributes(manifest, "Import-Package")) do
        local bundle_name = imported.name:match("^(org%.objectweb%.asm)")
        if bundle_name then
            local provided_version = runtime_bundle_version(bundle_name)
            if provided_version and imported.range and not version_in_range(provided_version, imported.range) then
                return false,
                    string.format(
                        "%s imports %s %s, but JDT LS provides %s",
                        vim.fn.fnamemodify(path, ":t"),
                        imported.name,
                        imported.range,
                        provided_version
                    )
            end
        end
    end

    return true
end

local function extension_version(path)
    return path:match("vscode%-java%-debug%-([%d%.]+)")
        or path:match("vscode%-java%-test%-([%d%.]+)")
        or path:match("java%-debug[/%-]([%d%.]+)")
        or path:match("java%-test[/%-]([%d%.]+)")
        or "0.0.0"
end

local function extension_dirs(id, package_glob)
    local candidates = {
        {
            source = "nix-profile",
            path = resolve_path("~/.nix-profile/share/vscode/extensions/" .. id),
        },
    }

    for _, path in
        ipairs(glob_all({
            "/nix/store/*-" .. package_glob .. "-*/share/vscode/extensions/" .. id,
        }))
    do
        table.insert(candidates, {
            source = "nix-store",
            path = path,
        })
    end

    local result = {}
    local seen = {}
    for _, candidate in ipairs(candidates) do
        if directory(candidate.path) and not seen[candidate.path] then
            seen[candidate.path] = true
            table.insert(result, candidate)
        end
    end
    return result
end

local function java_extension_jars(extension)
    local package = read_json(extension.path .. "/package.json")
    local java_extensions = package and package.contributes and package.contributes.javaExtensions
    if type(java_extensions) ~= "table" or vim.tbl_isempty(java_extensions) then
        return {}
    end

    local jars = {}
    for _, relative in ipairs(java_extensions) do
        local path = resolve_path(extension.path .. "/" .. relative)
        if readable(path) then
            table.insert(jars, path)
        end
    end

    return jars, package
end

local function add_bundle_once(result, seen, path)
    local manifest = jar_manifest(path)
    local name = bundle_symbolic_name(manifest)
    local version = bundle_version(manifest)
    if not name then
        return false
    end

    local key = name .. "@" .. (version or "")
    if seen[key] then
        return false
    end

    seen[key] = true
    table.insert(result, path)
    return true
end

local function compatible_jars(jars)
    local result = {}
    local skipped = {}
    local seen = {}

    for _, jar in ipairs(jars) do
        local ok, reason = compatible_jdtls_bundle(jar)
        if ok then
            add_bundle_once(result, seen, jar)
        elseif reason then
            table.insert(skipped, reason)
        end
    end

    return result, skipped
end

local function select_java_extension(opts)
    local best
    local rejected = {}

    for _, extension in ipairs(extension_dirs(opts.id, opts.package_glob)) do
        local jars, package = java_extension_jars(extension)
        local compatible, skipped = compatible_jars(jars)
        local has_required = false
        for _, jar in ipairs(compatible) do
            if bundle_symbolic_name(jar_manifest(jar)) == opts.required_bundle then
                has_required = true
                break
            end
        end

        local candidate = {
            paths = has_required and compatible or {},
            source = extension.source,
            extension_dir = extension.path,
            package_version = package and package.version or extension_version(extension.path),
            skipped = skipped,
            compatible = has_required and vim.tbl_isempty(skipped),
        }

        if candidate.compatible then
            if not best or compare_versions(best.package_version, candidate.package_version) < 0 then
                best = candidate
            end
        else
            vim.list_extend(rejected, candidate.skipped)
            table.insert(rejected, opts.label .. " skipped: " .. extension.path)
        end
    end

    return best, rejected
end

-- vscode-java-debug 와 vscode-java-test extension 을 각각 평가한 뒤,
-- 필수 bundle 이 포함되고 JDT LS runtime 과 충돌하지 않는 최신 후보만 선택한다.
-- 선택 실패 이유는 경고로 즉시 띄우지 않고 `DebugInfo` 의 messages 에 모아 둔다.
function M.java_bundle_selection()
    local selection = {
        bundles = {},
        java_debug = false,
        java_test = false,
        messages = {},
    }

    local debug, debug_rejected = select_java_extension({
        label = "vscode-java-debug",
        id = "vscjava.vscode-java-debug",
        package_glob = "vscode-extension-vscjava-vscode-java-debug",
        required_bundle = "com.microsoft.java.debug.plugin",
    })
    if debug then
        selection.java_debug = debug
        table.insert(selection.bundles, debug.paths[1])
    else
        vim.list_extend(selection.messages, debug_rejected)
    end

    local test, test_rejected = select_java_extension({
        label = "vscode-java-test",
        id = "vscjava.vscode-java-test",
        package_glob = "vscode-extension-vscjava-vscode-java-test",
        required_bundle = "com.microsoft.java.test.plugin",
    })
    if test then
        selection.java_test = test
        vim.list_extend(selection.bundles, test.paths)
    else
        vim.list_extend(selection.messages, test_rejected)
    end

    local deduped = {}
    local seen = {}
    for _, message in ipairs(selection.messages) do
        if not seen[message] then
            seen[message] = true
            table.insert(deduped, message)
        end
    end
    selection.messages = deduped

    last_selection = selection
    return selection
end

function M.java_bundles()
    local selection = M.java_bundle_selection()
    return selection.bundles
end

function M.has_java_test()
    return last_selection and last_selection.java_test ~= false or M.java_bundle_selection().java_test ~= false
end

-- `:DebugInfo` 는 Rust/C/C++, Java, JS/TS debugger provider 선택 상태를 보여준다.
-- Java bundle skip reason 도 함께 출력해서 Nix store extension mismatch 를 추적하기 쉽게 한다.
local function format_result(label, result)
    if not result then
        return string.format("%-10s: unavailable", label)
    end
    return string.format(
        "%-10s: %-11s %s",
        label,
        result.source or "unknown",
        result.path or table.concat(result.paths or {}, ", ")
    )
end

local function first_path(result)
    if not result or not result.paths or vim.tbl_isempty(result.paths) then
        return nil
    end
    return result.paths[1]
end

function M.info_lines()
    local selection = M.java_bundle_selection()
    local lines = {
        format_result("codelldb", M.resolve_codelldb()),
        format_result("lldb-dap", M.resolve_lldb_dap()),
        format_result("js-debug", M.resolve_js_debug()),
        format_result("java-debug", selection.java_debug and {
            source = selection.java_debug.source,
            path = first_path(selection.java_debug),
        } or nil),
        format_result("java-test", selection.java_test and {
            source = selection.java_test.source,
            path = first_path(selection.java_test),
        } or nil),
    }

    if not vim.tbl_isempty(selection.messages) then
        table.insert(lines, "")
        table.insert(lines, "Skipped Java bundles:")
        for _, message in ipairs(selection.messages) do
            table.insert(lines, "  - " .. message)
        end
    end

    return lines
end

function M.debug_info()
    vim.notify(table.concat(M.info_lines(), "\n"), vim.log.levels.INFO)
end

M._test = {
    split_manifest_list = split_manifest_list,
    version_in_range = version_in_range,
    compare_versions = compare_versions,
    extension_version = extension_version,
    java_extension_jars = java_extension_jars,
}

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.WARN)
end

-- 언어별 설정에서 재사용하는 debugger adapter resolver 다.
-- Rust/C/C++ 은 codelldb server adapter 를 우선 쓰고 lldb-dap executable adapter 로
-- fallback 하며, JS/TS 는 vscode-js-debug server 실행 파일만 노출한다.
function M.codelldb_path()
    local codelldb = M.resolve_codelldb()
    return codelldb and codelldb.path or nil
end

function M.lldb_adapter()
    local codelldb = M.resolve_codelldb()
    if codelldb then
        return {
            type = "server",
            host = "127.0.0.1",
            port = "${port}",
            executable = {
                command = codelldb.path,
                args = { "--port", "${port}" },
            },
        }
    end

    local lldb_dap = M.resolve_lldb_dap()
    if lldb_dap then
        return {
            type = "executable",
            command = lldb_dap.path,
            name = "lldb",
        }
    end

    return false
end

function M.lldb_adapter_type(adapter)
    if not adapter then
        adapter = M.lldb_adapter()
    end
    if adapter == false then
        return nil
    end
    return adapter.type == "server" and "codelldb" or "lldb"
end

function M.js_debug_adapter()
    local js_debug = M.resolve_js_debug()
    return js_debug and js_debug.path or nil
end

-- launch configuration 에서 바로 호출하는 작은 input/root helper 다.
-- DAP 실행 cwd 는 현재 buffer 에서 marker 를 위로 찾고, 없으면 현재 작업 디렉터리로 둔다.
function M.input_args()
    local args = vim.fn.input("Args: ")
    return args ~= "" and vim.split(args, " +") or {}
end

function M.find_upward(names, start_path)
    local found = vim.fs.find(names, { path = start_path, upward = true, limit = 1 })[1]
    return found and vim.fs.dirname(found) or nil
end

function M.project_root(markers)
    local file = vim.api.nvim_buf_get_name(0)
    local dir = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()
    return M.find_upward(markers, dir) or vim.uv.cwd()
end

local function rust_lsp(command, opts)
    if vim.bo.filetype ~= "rust" then
        notify(command .. " is only available in Rust buffers")
        return
    end

    opts = opts or {}
    local ok, err
    if opts.bang then
        ok, err = pcall(vim.cmd.RustLsp, { command, bang = true })
    else
        ok, err = pcall(vim.cmd.RustLsp, command)
    end
    if not ok then
        notify(tostring(err), vim.log.levels.ERROR)
    end
end

local function dap_continue()
    local ok, err = pcall(function()
        require("dap").continue()
    end)
    if not ok then
        notify(tostring(err), vim.log.levels.ERROR)
    end
end

local function selected_text()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local start_row, start_col = start_pos[2], start_pos[3]
    local end_row, end_col = end_pos[2], end_pos[3]

    if start_row == 0 or end_row == 0 then
        return ""
    end

    if start_row > end_row or (start_row == end_row and start_col > end_col) then
        start_row, end_row = end_row, start_row
        start_col, end_col = end_col, start_col
    end

    local mode = vim.fn.visualmode()
    if mode == "V" then
        return vim.trim(table.concat(vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false), "\n"))
    end

    local ok, text = pcall(vim.api.nvim_buf_get_text, 0, start_row - 1, start_col - 1, end_row - 1, end_col, {})
    return ok and vim.trim(table.concat(text, "\n")) or ""
end

local function debug_expression(source)
    if source == "visual" then
        return selected_text()
    end
    return vim.fn.expand("<cword>")
end

local function with_expression(source, callback)
    local expression = vim.trim(debug_expression(source) or "")
    if expression == "" then
        notify("No expression under cursor or selection")
        return
    end

    local ok, err = pcall(callback, expression)
    if not ok then
        notify(tostring(err), vim.log.levels.ERROR)
    end
end

local function attach_configs()
    local configs = require("dap").configurations[vim.bo.filetype] or {}
    local matches = {}
    for _, config in ipairs(configs) do
        if config.request == "attach" then
            table.insert(matches, config)
        end
    end
    return matches
end

-- keymap 에서 호출하는 debug entrypoint 다.
-- Rust 는 rustaceanvim 의 RustLsp 명령을 우선 사용하고, Java/Kotlin test debug 는
-- Gradle/JDT LS test workflow 를 소유한 core/test.lua 로 넘긴다.
function M.debug_run()
    if vim.bo.filetype == "rust" then
        rust_lsp("debug")
        return
    end

    dap_continue()
end

function M.debug_test()
    if vim.bo.filetype == "java" or vim.bo.filetype == "kotlin" then
        require("plugins.core.test")
        _G.__test_alternate.debug_test()
        return
    end

    local ok, err = pcall(function()
        require("neotest").run.run({ strategy = "dap" })
    end)
    if not ok then
        notify(tostring(err), vim.log.levels.ERROR)
    end
end

function M.debug_attach()
    local configs = attach_configs()
    if #configs == 0 then
        notify("No DAP attach configuration for " .. vim.bo.filetype)
        return
    end

    if #configs == 1 then
        require("dap").run(configs[1])
        return
    end

    vim.ui.select(configs, {
        prompt = "Attach configuration:",
        format_item = function(config)
            return config.name
        end,
    }, function(config)
        if config then
            require("dap").run(config)
        end
    end)
end

-- cursor 단어 또는 visual selection 을 DAP UI eval/watch 로 보낸다.
-- visual range 는 linewise/charwise selection 모두 처리하고, 빈 표현식은 notify 로 끝낸다.
function M.debug_eval(source)
    with_expression(source, function(expression)
        require("dapui").eval(expression)
    end)
end

function M.debug_watch(source)
    with_expression(source, function(expression)
        require("dapui").elements.watches.add(expression)
    end)
end

function M.debug_stop()
    local dap = require("dap")
    local session = dap.session()
    if session and session.config and session.config.request == "attach" then
        dap.disconnect({ terminateDebuggee = false })
        return
    end

    dap.terminate()
end

pcall(vim.api.nvim_del_user_command, "DebugInfo")
vim.api.nvim_create_user_command("DebugInfo", M.debug_info, {
    desc = "Show selected debugger tool providers",
})

-- nvim-dap sign 과 dap-ui window resize 보정을 한 곳에 둔다.
-- dap-ui 는 기본 window fix 옵션 때문에 split resize 후 layout 이 굳을 수 있어,
-- open/toggle/autocmd 뒤에 winfixheight/winfixwidth 를 풀고 layout size 를 다시 계산한다.
local function setup_dap_signs()
    vim.fn.sign_define("DapBreakpoint", {
        text = "●",
        texthl = "DiagnosticError",
        numhl = "DiagnosticError",
    })

    vim.fn.sign_define("DapBreakpointCondition", {
        text = "◆",
        texthl = "DiagnosticWarn",
        numhl = "DiagnosticWarn",
    })

    vim.fn.sign_define("DapBreakpointRejected", {
        text = "×",
        texthl = "DiagnosticError",
        numhl = "DiagnosticError",
    })

    vim.fn.sign_define("DapLogPoint", {
        text = "◆",
        texthl = "DiagnosticInfo",
        numhl = "DiagnosticInfo",
    })

    vim.api.nvim_set_hl(0, "DapStoppedLine", {
        link = "CursorLine",
    })

    vim.fn.sign_define("DapStopped", {
        text = "→",
        texthl = "DiagnosticWarn",
        linehl = "DapStoppedLine",
        numhl = "DiagnosticWarn",
    })
end

local function is_dapui_window(win)
    if not vim.api.nvim_win_is_valid(win) then
        return false
    end

    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    local name = vim.api.nvim_buf_get_name(buf)
    return ft:match("^dapui_") or ft == "dap-repl" or name:match("/DAP ") or name:match("%[dap%-repl%-")
end

local function sync_dapui_layout_sizes()
    local ok, windows = pcall(require, "dapui.windows")
    if not ok then
        return
    end

    for _, layout in ipairs(windows.layouts or {}) do
        pcall(function()
            layout:update_sizes()
        end)
    end
end

local function unlock_dapui_windows()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if is_dapui_window(win) then
            vim.wo[win].winfixheight = false
            vim.wo[win].winfixwidth = false
        end
    end
end

local function make_dapui_resizable()
    unlock_dapui_windows()
    sync_dapui_layout_sizes()
end

local function schedule_dapui_resize_unlock()
    vim.schedule(make_dapui_resizable)
    vim.defer_fn(make_dapui_resizable, 50)
    vim.defer_fn(make_dapui_resizable, 150)
end

local function pack_results(...)
    return { n = select("#", ...), ... }
end

local function wrap_dapui_layout_opener(dapui, name)
    local original = dapui[name]
    if type(original) ~= "function" then
        return
    end

    dapui[name] = function(...)
        local result = pack_results(original(...))
        schedule_dapui_resize_unlock()
        return unpack(result, 1, result.n)
    end
end

local function setup_dapui_resize_hooks(dapui)
    if dapui.__resizable_windows_hooked then
        return
    end
    dapui.__resizable_windows_hooked = true

    wrap_dapui_layout_opener(dapui, "open")
    wrap_dapui_layout_opener(dapui, "toggle")

    local group = vim.api.nvim_create_augroup("DapUIResizableWindows", { clear = true })
    vim.api.nvim_create_autocmd({ "WinNew", "BufWinEnter", "WinEnter" }, {
        group = group,
        callback = schedule_dapui_resize_unlock,
    })
    vim.api.nvim_create_autocmd("WinResized", {
        group = group,
        callback = make_dapui_resizable,
    })
end

M[1] = {
    -- nvim-dap 을 공통 debugger entrypoint 로 두고 언어별 adapter 를 주입한다.
    -- DAP UI/virtual text 를 함께 열어 run, attach, eval, watch 흐름을 통일한다.
    "mfussenegger/nvim-dap",
    keys = function()
        return require("config.keymaps").bind("debug")
    end,
    dependencies = {
        "nvim-neotest/nvim-nio",
        "rcarriga/nvim-dap-ui",
        "theHamsta/nvim-dap-virtual-text",
    },
    opts = {
        setup = {},
    },
    config = function(_, opts)
        local dap = require("dap")

        setup_dap_signs()

        require("nvim-dap-virtual-text").setup()

        for _, setup in ipairs(opts.setup or {}) do
            setup(dap, M)
        end

        local dapui = require("dapui")
        dapui.setup()
        setup_dapui_resize_hooks(dapui)

        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
            schedule_dapui_resize_unlock()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.after.disconnect["dapui_config"] = function()
            dapui.close()
        end
    end,
}

M[2] = {
    -- dap-ui 는 nvim-dap dependency 로 실제 setup 되며 lazy spec 만 별도로 고정한다.
    -- plugin manager 가 UI 패키지를 독립 플러그인으로 인식하게 하기 위한 항목이다.
    "rcarriga/nvim-dap-ui",
    lazy = true,
}

return M
