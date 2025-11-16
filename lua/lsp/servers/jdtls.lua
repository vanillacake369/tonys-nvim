-- Java 언어 서버 (jdtls) 설정
local M = {}

function M.setup(capabilities)
  vim.lsp.config.jdtls = {
    cmd = { 'jdt-language-server' },
    filetypes = { 'java' },
    root_dir = function(fname)
      return vim.fs.root(fname, { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' })
    end,
    capabilities = capabilities,
    settings = {
      java = {
        signatureHelp = { enabled = true },
        contentProvider = { preferred = 'fernflower' },
        completion = {
          favoriteStaticMembers = {
            'org.junit.Assert.*',
            'org.junit.Assume.*',
            'org.junit.jupiter.api.Assertions.*',
            'org.junit.jupiter.api.Assumptions.*',
            'org.junit.jupiter.api.DynamicContainer.*',
            'org.junit.jupiter.api.DynamicTest.*',
            'org.mockito.Mockito.*',
            'org.mockito.ArgumentMatchers.*',
            'org.mockito.Answers.*',
          },
          filteredTypes = {
            'com.sun.*',
            'io.micrometer.shaded.*',
            'java.awt.*',
            'jdk.*',
            'sun.*',
          },
        },
        sources = {
          organizeImports = {
            starThreshold = 9999,
            staticStarThreshold = 9999,
          },
        },
        codeGeneration = {
          toString = {
            template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
          },
          hashCodeEquals = {
            useJava7Objects = true,
          },
          useBlocks = true,
        },
        configuration = {
          runtimes = {
            -- 필요시 Java 런타임 추가
            -- {
            --   name = "JavaSE-11",
            --   path = "/path/to/jdk-11",
            -- },
            -- {
            --   name = "JavaSE-17",
            --   path = "/path/to/jdk-17",
            -- },
          },
        },
      },
    },
  }
  vim.lsp.enable('jdtls')
end

return M
