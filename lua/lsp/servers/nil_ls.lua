-- Nix Language Server (nil) Configuration
local M = {}

function M.setup(capabilities)
  require('lspconfig').nil_ls.setup({
    capabilities = capabilities,
    settings = {
      ['nil'] = {
        formatting = {
          command = { 'nixpkgs-fmt' },
        },
        nix = {
          flake = {
            autoArchive = true,
            autoEvalInputs = true,
          },
        },
      },
    },
  })
end

return M
