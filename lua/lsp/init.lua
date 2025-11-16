-- LSP 공통 설정
local M = {}

-- nvim-cmp 자동완성 설정
local function setup_cmp()
  local cmp = require('cmp')
  local luasnip = require('luasnip')

  cmp.setup({
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' }),
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
      { name = 'buffer' },
      { name = 'path' },
    }),
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
  })
end

-- LSP 키바인딩 (LSP가 버퍼에 연결될 때 적용)
local function setup_keybindings(client, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }

  -- 네비게이션
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)

  -- 문서
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)

  -- 코드 액션
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)

  -- 진단
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  -- vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

  -- 워크스페이스 폴더
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts)

  -- 포맷
  if client.server_capabilities.documentFormattingProvider then
    vim.keymap.set('n', '<leader>f', function()
      vim.lsp.buf.format({ async = true })
    end, opts)
  end
end

-- LSP 핸들러 커스터마이징
local function setup_handlers()
  -- 진단 설정 (Neovim 0.11+ 새로운 API)
  vim.diagnostic.config({
    virtual_text = {
      prefix = '●',
      spacing = 4,
    },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = '',
        [vim.diagnostic.severity.WARN] = '',
        [vim.diagnostic.severity.HINT] = '',
        [vim.diagnostic.severity.INFO] = '',
      },
    },
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = {
      focusable = false,
      style = 'minimal',
      border = 'rounded',
      source = 'always',
      header = '',
      prefix = '',
    },
  })

  -- LSP 핸들러 커스터마이징
  vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = 'rounded',
  })

  vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = 'rounded',
  })
end

-- LSP attach autocmd 설정
local function setup_lsp_attach()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      setup_keybindings(client, ev.buf)

      -- <c-x><c-o>로 트리거되는 자동완성 활성화
      vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    end,
  })
end

-- cmp_nvim_lsp와 함께 공통 capabilities 가져오기
function M.get_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  return require('cmp_nvim_lsp').default_capabilities(capabilities)
end

-- 모든 서버 설정 로드
local function load_servers()
  local servers = {
    'lua_ls',
    'gopls',
    'jdtls',
    'nixd',
    'yamlls',
    'tsserver',
  }

  for _, server in ipairs(servers) do
    local ok, config = pcall(require, 'lsp.servers.' .. server)
    if ok then
      config.setup(M.get_capabilities())
    else
      vim.notify('Failed to load LSP server config: ' .. server, vim.log.levels.WARN)
    end
  end
end

-- LSP 설정 초기화
function M.setup()
  setup_handlers()
  setup_lsp_attach()
  setup_cmp()
  load_servers()
end

-- require 시 자동 초기화
M.setup()

return M
