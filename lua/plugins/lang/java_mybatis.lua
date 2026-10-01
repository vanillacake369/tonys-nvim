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

        local mybatis = require("mybatis")
        mybatis.setup(opts)

        local function bind_mapper_definition(args)
            if not mybatis.is_mapper_file(args.buf) then
                return
            end

            vim.keymap.set("n", "gd", function()
                require("plugins.core.lsp").smart_definition()
            end, { buffer = args.buf, desc = "MyBatis jump or definition" })
        end

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("MybatisDefinition", { clear = true }),
            pattern = { "java", "xml" },
            callback = bind_mapper_definition,
        })

        bind_mapper_definition({ buf = vim.api.nvim_get_current_buf() })
    end,
}
