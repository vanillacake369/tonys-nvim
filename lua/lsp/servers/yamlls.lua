-- YAML 언어 서버 설정
local M = {}

function M.setup(capabilities)
  vim.lsp.config.yamlls = {
    cmd = { 'yaml-language-server', '--stdio' },
    filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab' },
    root_dir = function(fname)
      return vim.fs.root(fname, { '.git' })
    end,
    capabilities = capabilities,
    settings = {
      yaml = {
        schemas = {
          kubernetes = '/*.yaml',
          ['http://json.schemastore.org/github-workflow'] = '.github/workflows/*',
          ['http://json.schemastore.org/github-action'] = '.github/action.{yml,yaml}',
          ['http://json.schemastore.org/ansible-stable-2.9'] = 'roles/tasks/*.{yml,yaml}',
          ['http://json.schemastore.org/prettierrc'] = '.prettierrc.{yml,yaml}',
          ['http://json.schemastore.org/kustomization'] = 'kustomization.{yml,yaml}',
          ['http://json.schemastore.org/ansible-playbook'] = '*play*.{yml,yaml}',
          ['http://json.schemastore.org/chart'] = 'Chart.{yml,yaml}',
          ['https://json.schemastore.org/dependabot-v2'] = '.github/dependabot.{yml,yaml}',
          ['https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json'] = '*gitlab-ci*.{yml,yaml}',
          ['https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json'] = '*api*.{yml,yaml}',
          ['https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json'] = '*docker-compose*.{yml,yaml}',
        },
        format = {
          enable = true,
        },
        validate = true,
        completion = true,
        hover = true,
      },
    },
  }
  vim.lsp.enable('yamlls')
end

return M
