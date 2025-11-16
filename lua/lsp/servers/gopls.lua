-- Go 언어 서버 (gopls) 설정
local M = {}

function M.setup(capabilities)
  vim.lsp.config.gopls = {
    cmd = { 'gopls' },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
    root_dir = function(fname)
      return vim.fs.root(fname, { 'go.work', 'go.mod', '.git' })
    end,
    capabilities = capabilities,
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
          shadow = true,
        },
        staticcheck = true,
        gofumpt = true,
        usePlaceholders = true,
        completeUnimported = true,
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      },
    },
  }
  vim.lsp.enable('gopls')
end

return M
