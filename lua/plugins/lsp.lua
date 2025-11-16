-- LSP 설정 및 관련 플러그인
return {
  -- LSP 설정 (Neovim 0.11+ 내장 vim.lsp.config 사용)
  {
    'hrsh7th/nvim-cmp', -- 자동완성을 위한 메인 플러그인
    event = { 'BufReadPre', 'BufNewFile', 'InsertEnter' },
    dependencies = {
      -- 자동완성 소스
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',

      -- 스니펫 엔진 (nvim-cmp 필수)
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
    },
    config = function()
      -- 공통 LSP 설정 및 키바인딩 로드
      require('lsp')
    end,
  },

  -- 스니펫 엔진
  {
    'L3MON4D3/LuaSnip',
    version = 'v2.*',
    build = 'make install_jsregexp',
  },

  -- 코드 포맷팅 플러그인
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format({ async = true, lsp_fallback = true })
        end,
        mode = '',
        desc = 'Format buffer',
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        go = { 'goimports', 'gofmt' },
        java = { 'google-java-format' },
        nix = { 'alejandra' },
        yaml = { 'prettier' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },

  -- 린팅 플러그인
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require('lint')

      -- 실제로 설치된 린터만 설정 (KISS 원칙)
      lint.linters_by_ft = {
        go = { 'golangcilint' },
        javascript = { 'eslint' },
        typescript = { 'eslint' },
        yaml = { 'yamllint' }, -- language.nix에 설치됨
      }

      -- 저장 및 텍스트 변경 시 자동 린트
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
        callback = function()
          -- 린터가 설치되어 있을 때만 실행
          local ok = pcall(require('lint').try_lint)
          if not ok then
            -- 에러 무시 (린터 미설치)
          end
        end,
      })
    end,
  },
}
