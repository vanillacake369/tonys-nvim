-- Load Nix-managed provider host paths if present (emitted by tonys-nix
-- via xdg.configFile."nvim/nix-providers.lua"). Non-Nix clones simply
-- skip this dofile, falling back to nvim's PATH-based provider detection.
local nix_providers = vim.fn.stdpath("config") .. "/nix-providers.lua"
if (vim.uv or vim.loop).fs_stat(nix_providers) then
    dofile(nix_providers)
end

require("config.keymaps")
require("config.options")
require("config.lazy")
require("config.clipboard")
