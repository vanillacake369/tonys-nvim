-- YAML Language Server Configuration
local M = {}

function M.setup(capabilities)
  require('lspconfig').yamlls.setup({
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
  })
end

return M
