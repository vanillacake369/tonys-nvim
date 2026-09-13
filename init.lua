-- tonys-nix 가 xdg.configFile."nvim/nix-providers.lua" 로 생성한 provider
-- host 경로가 있으면 먼저 로드한다.
-- Nix 가 아닌 clone 은 이 파일을 건너뛰고 Neovim 의 PATH 기반 provider 탐지를 쓴다.
local nix_providers = vim.fn.stdpath("config") .. "/nix-providers.lua"
if (vim.uv or vim.loop).fs_stat(nix_providers) then
    dofile(nix_providers)
end

require("config.keymaps")
require("config.options")
require("config.lazy")
require("config.clipboard")
