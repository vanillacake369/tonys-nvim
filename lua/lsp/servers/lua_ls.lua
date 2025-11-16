-- Lua 언어 서버 설정
local M = {}

function M.setup(capabilities)
  vim.lsp.config.lua_ls = {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_dir = function(fname)
      return vim.fs.root(fname, { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git' })
    end,
    capabilities = capabilities,
    settings = {
      Lua = {
        runtime = {
          -- 사용 중인 Lua 버전 지정
          version = 'LuaJIT',
        },
        diagnostics = {
          -- `vim` 전역 변수 인식
          globals = { 'vim' },
        },
        workspace = {
          -- Neovim 런타임 파일 인식
          library = vim.api.nvim_get_runtime_file('', true),
          checkThirdParty = false,
        },
        telemetry = {
          enable = false,
        },
        completion = {
          callSnippet = 'Replace',
        },
      },
    },
  }
  vim.lsp.enable('lua_ls')
end

return M
