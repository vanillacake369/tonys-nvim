return {
    -- Java mapper interface 와 XML mapper 사이 이동은 mybatis.nvim 이 담당한다.
    -- Mapper 밖의 gd 는 공통 LSP 설정의 Snacks picker 로 그대로 돌아간다.
    "qumn/mybatis.nvim",
    ft = { "java", "xml" },
    opts = {
        root_markers = {
            "settings.gradle",
            "settings.gradle.kts",
            "build.gradle",
            "build.gradle.kts",
            "pom.xml",
            ".git",
        },
        search = {
            exclude_dirnames = {
                ".git",
                ".gradle",
                ".idea",
                "bin",
                "build",
                "node_modules",
                "out",
                "target",
            },
        },
        mapper = {
            filename_patterns = { "Mapper%.java$", "Mapper%.xml$", "Dao%.java$", "Dao%.xml$" },
        },
    },
    config = function(_, opts)
        -- 일부 기존 프로젝트는 Java class 와 XML filename 의 대소문자가 다르다.
        -- namespace 검증은 유지하면서 exact filename 검색 실패만 보완한다.
        require("utils.mybatis_fs").enable_case_insensitive_lookup()

        require("mybatis").setup(opts)

        -- 이미 파싱된 Java AST에서 커서가 메서드 이름 위에 있는지 검사한다.
        -- Tree-sitter를 사용할 수 없을 때는 기존의 가벼운 줄 검색으로 폴백한다.
        local function is_mapper_method_fallback(line, cursor_col)
            local offset = 1
            while true do
                local start_col, end_col = line:find("[%a_$][%w_$]*%s*%(", offset)
                if not start_col then
                    return false
                end
                local identifier_end = assert(line:find("%s*%(", start_col)) - 1
                while identifier_end >= start_col and line:sub(identifier_end, identifier_end):match("%s") do
                    identifier_end = identifier_end - 1
                end
                if cursor_col >= start_col - 1 and cursor_col < identifier_end then
                    return true
                end
                offset = end_col + 1
            end
        end

        local function is_mapper_method(bufnr)
            local cursor = vim.api.nvim_win_get_cursor(0)
            local row, col = cursor[1] - 1, cursor[2]
            local ok, node = pcall(vim.treesitter.get_node, {
                bufnr = bufnr,
                pos = { row, col },
            })

            if not ok or not node then
                return is_mapper_method_fallback(vim.api.nvim_get_current_line(), col)
            end

            while node do
                local kind = node:type()
                if kind == "method_declaration" or kind == "method_invocation" then
                    local name = node:field("name")[1]
                    if name then
                        local start_row, start_col, end_row, end_col = name:range()
                        local within_start = row > start_row or (row == start_row and col >= start_col)
                        local within_end = row < end_row or (row == end_row and col < end_col)
                        return within_start and within_end
                    end
                end
                node = node:parent()
            end
            return false
        end

        local function handle_definition(bufnr)
            local ft = vim.bo[bufnr].filetype

            if ft == "java" then
                if not is_mapper_method(bufnr) then
                    return false
                end
            elseif ft ~= "xml" then
                return false
            end

            local mybatis = require("mybatis")

            if not mybatis.is_mapper_file(bufnr) then
                return false
            end

            mybatis.jump_or_fallback()
            return true
        end

        -- Handler 등록은 함수 정의 뒤에서 수행한다.
        -- 공통 LSP는 MyBatis를 몰라도 되고, 다른 언어는 기본 Definition을 사용한다.
        local lsp = require("plugins.core.lsp")
        lsp.register_definition_handler("java", handle_definition)
        lsp.register_definition_handler("xml", handle_definition)

        -- XML mapper에는 LSP 클라이언트가 attach되지 않을 수 있다.
        -- 기존 동작을 보존하기 위해 mapper buffer에서 gd만 공통 진입점에 연결한다.
        local function bind_mapper_definition(args)
            if not require("mybatis").is_mapper_file(args.buf) then
                return
            end

            vim.keymap.set("n", "gd", lsp.smart_definition, {
                buffer = args.buf,
                desc = "MyBatis jump or LSP definition",
            })
        end

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("MybatisDefinition", { clear = true }),
            pattern = { "java", "xml" },
            callback = bind_mapper_definition,
        })

        -- ft-lazy 플러그인 로드 이전에 FileType이 이미 발생했을 수 있다.
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.bo[bufnr].filetype == "java" or vim.bo[bufnr].filetype == "xml" then
            bind_mapper_definition({ buf = bufnr })
        end
    end,
}
