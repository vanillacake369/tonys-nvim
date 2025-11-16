-- Lua Language Server Configuration
local M = {}

function M.setup(capabilities)
  require('lspconfig').lua_ls.setup({
    capabilities = capabilities,
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using
          version = 'LuaJIT',
        },
        diagnostics = {
          -- Recognize the `vim` global
          globals = { 'vim' },
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file('', true),
          checkThirdParty = false,
        },
        telemetry = {
          enable = false,
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        completion = {
          callSnippet = 'Replace',
        },
      },
    },
  })
end

return M
