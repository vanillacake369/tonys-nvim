-- Nix 언어 서버 (nixd) 설정
local M = {}

function M.setup(capabilities)
  vim.lsp.config.nixd = {
    cmd = { 'nixd' },
    filetypes = { 'nix' },
    root_dir = function(fname)
      return vim.fs.root(fname, { 'flake.nix', 'flake.lock', '.git' })
    end,
    capabilities = capabilities,
    settings = {
      nixd = {
        formatting = {
          command = { 'alejandra' },
        },
      },
    },
  }
  vim.lsp.enable('nixd')
end

return M
