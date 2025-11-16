-- Java Language Server (jdtls) Configuration
local M = {}

function M.setup(capabilities)
  require('lspconfig').jdtls.setup({
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
            -- Add your Java runtimes here if needed
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
  })
end

return M
