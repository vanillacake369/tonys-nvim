-- Neotest: per-test runner with gutter signs, inline diagnostics, summary panel.
-- Adapters: neotest-java (Gradle/Maven), neotest-golang, neotest-python (pytest),
-- and rustaceanvim.neotest (loaded automatically when rust files are open).
--
-- JUnit Platform Console Standalone JAR (required by neotest-java) is provisioned
-- by tonys-nix via home.file symlink — no per-machine setup needed on Nix hosts.

return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            -- COUPLED with the Path:append monkey-patch below + the JUnit JAR
            -- pin in tonys-nix/modules/language/language.hm.nix. When updating
            -- neotest-java, recheck BOTH: (1) does the patch still apply
            -- (see detection signal in the patch comment), (2) does the
            -- JUnit JAR pinned version still match neotest-java's
            -- default_config.SUPPORTED_VERSIONS[1].
            "rcasia/neotest-java",
            "fredrikaverpil/neotest-golang",
            "nvim-neotest/neotest-python",
            -- rustaceanvim must load before neotest's config so its adapter is
            -- available to register. Without this, opening a .java file first
            -- means neotest.setup runs without the rust adapter and rust tests
            -- are never discoverable until full restart.
            "mrcjkb/rustaceanvim",
        },
        ft = { "java", "go", "python", "rust" },
        keys = function()
            return require("config.keymaps").get_keys("test")
        end,
        config = function()
            -- Upstream bug in neotest-java v0.37.3 (also present on main as of
            -- 2026-05-31): `Path:append` does `self.raw_path .. self.separator
            -- .. other` assuming `other` is a string, but `build_tool.lua:32`
            -- calls it with another Path (Gradle's `get_build_dirname` returns
            -- `Path("bin")`). Crashes when running tests in Spring projects via
            -- `get_spring_property_filepaths`. Coerce table args via tostring
            -- (Path has a __tostring metamethod).
            --
            -- [VERSION DRIFT] Pinned to behavior of neotest-java HEAD@2026-05-31.
            -- Detection signal: after `:Lazy update neotest-java`, run
            --   git -C ~/.local/share/nvim/lazy/neotest-java log --oneline \
            --       -- lua/neotest-java/model/path.lua \
            --       lua/neotest-java/build_tool/build_tool.lua
            -- If upstream changed either file, temporarily disable this patch
            -- (comment out the `do ... end` block) and run a Spring-project
            -- test; if it still passes, the patch can be deleted. Upstream
            -- issue to file: github.com/rcasia/neotest-java (Path:append
            -- table arg from build_tool:32, no __concat metamethod).
            do
                local ok, Path = pcall(require, "neotest-java.model.path")
                if ok and Path and Path.append then
                    local orig_append = Path.append
                    Path.append = function(self, other)
                        if type(other) == "table" then
                            other = tostring(other)
                        end
                        return orig_append(self, other)
                    end
                end
            end

            local adapters = {}
            local function add(name, factory)
                local ok, mod = pcall(require, name)
                if ok then
                    table.insert(adapters, factory and factory(mod) or mod)
                end
            end
            -- `disable_update_notifications = true` suppresses the in-editor
            -- "JUnit jar update available" popup that neotest-java would show
            -- every session once a 6.1.x lands in its SUPPORTED_VERSIONS list
            -- (the Nix-pinned 6.0.3 would suddenly look "outdated"). We track
            -- version bumps via the comment in language.hm.nix instead.
            add("neotest-java", function(mod)
                return mod({ disable_update_notifications = true })
            end)
            add("neotest-golang", function(mod)
                return mod({})
            end)
            add("neotest-python", function(mod)
                return mod({ runner = "pytest" })
            end)
            -- rustaceanvim's neotest module IS the adapter table (no factory call).
            add("rustaceanvim.neotest")

            require("neotest").setup({
                adapters = adapters,
                quickfix = { open = false },
                output = { open_on_run = false },
                output_panel = { open = "botright 15split" },
                summary = { open = "botright 50vsplit" },
                icons = {
                    passed = "✓",
                    failed = "✗",
                    running = "",
                    skipped = "",
                    unknown = "?",
                },
                discovery = { enabled = true },
                diagnostic = { enabled = true },
                status = { enabled = true, signs = true, virtual_text = false },
            })
        end,
    },
}
