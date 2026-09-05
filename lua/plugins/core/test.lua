-- NOTE: Neotest owns per-test gutter signs, diagnostics, summary, and DAP runs.
-- Java, Go, Python, and Rust adapters are registered together so test keymaps
-- do not depend on which language buffer loaded first.
--
-- COMPAT: neotest-java uses the JUnit Platform Console Standalone JAR provided
-- by tonys-nix via home.file symlink on Nix hosts.

return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            -- COMPAT: neotest-java upgrades must be checked with the Path:append
            -- patch below and the JUnit JAR pin in tonys-nix.
            "rcasia/neotest-java",
            "fredrikaverpil/neotest-golang",
            "nvim-neotest/neotest-python",
            -- NOTE: rustaceanvim must load before neotest setup so the Rust
            -- adapter is available even when a non-Rust buffer opens first.
            "mrcjkb/rustaceanvim",
        },
        ft = { "java", "go", "python", "rust" },
        keys = function()
            return require("config.keymaps").bind("test")
        end,
        config = function()
            -- HACK: neotest-java v0.37.3 Path:append assumes `other` is a
            -- string, but Gradle build dir resolution can pass another Path.
            -- Coerce table args through tostring to keep Spring test discovery
            -- from crashing.
            --
            -- COMPAT: pinned to neotest-java HEAD behavior on 2026-05-31. After
            -- `:Lazy update neotest-java`, run:
            --   git -C ~/.local/share/nvim/lazy/neotest-java log --oneline \
            --       -- lua/neotest-java/model/path.lua \
            --       lua/neotest-java/build_tool/build_tool.lua
            -- If either file changed, disable this patch and run a Spring test.
            -- Delete the patch when upstream handles Path table concatenation.
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
            -- COMPAT: suppress neotest-java JUnit update popups because the JAR
            -- version is pinned by Nix and reviewed in tonys-nix instead.
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
                output_panel = { open = "botright 18split" },
                summary = {
                    open = "botright 50vsplit",
                    follow = true,
                    expand_errors = true,
                    count = true,
                },
                consumers = {
                    open_output_panel = function(client)
                        client.listeners.run = function()
                            vim.schedule(function()
                                require("neotest").output_panel.open()
                            end)
                        end
                        return {}
                    end,
                },
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
