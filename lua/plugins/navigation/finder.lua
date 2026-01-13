return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		bigfile = { enabled = true },
		dashboard = { enabled = true },
		explorer = { enabled = true },
		indent = { enabled = true },
		input = { enabled = true },
		notifier = { enabled = true, timeout = 3000 },
		terminal = { enabled = true },
		picker = {
			enabled = true,
			-- ui_select = true,
			layouts = {
				telescope = {
					layout = {
						box = "horizontal",
						width = 0.95,
						height = 0.85,
						{
							box = "vertical",
							border = "rounded",
							title = " 📂 Project Tree ",
							{ win = "input", height = 1, border = "bottom" },
							{ win = "list", border = "none" },
							width = 0.35,
						},
						{
							win = "preview",
							title = " 👁️ Preview ",
							border = "rounded",
							width = 0.65,
						},
					},
				},
			},
			-- picker 전체에 적용할 기본 레이아웃
			layout = { preset = "telescope", focus = "list" },
			sources = {
				explorer = {
					hidden = true,
					ignored = true,
				},
				recent = {
					cwd_only = false,
					layout = { reverse = false },
				},
				buffers = {
					cwd_only = false,
					layout = { reverse = false },
				},
			},
		},
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
	},

	keys = function()
		local keymaps = require("config.keymaps")
		local find_keys = keymaps.get_keys("find")
		local terminal_keys = keymaps.get_keys("terminal")
		return vim.list_extend(find_keys, terminal_keys)
	end,
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				-- 디버깅용 전역 함수 설정
				_G.dd = function(...)
					Snacks.debug.inspect(...)
				end
				_G.bt = function()
					Snacks.debug.backtrace()
				end

				if vim.fn.has("nvim-0.11") == 1 then
					vim._print = function(_, ...)
						dd(...)
					end
				else
					vim.print = _G.dd
				end

				-- UI Toggles
				Snacks.toggle.option("spell", { name = "[UI] Spelling" }):map("<leader>us")
				Snacks.toggle.option("wrap", { name = "[UI] Wrap" }):map("<leader>uw")
				Snacks.toggle.option("relativenumber", { name = "[UI] Relative Number" }):map("<leader>uL")
				Snacks.toggle.diagnostics({ name = "[UI] Diagnostics" }):map("<leader>ud")
				Snacks.toggle.line_number({ name = "[UI] Line Number" }):map("<leader>ul")
				Snacks.toggle
					.option(
						"conceallevel",
						{ off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "[UI] Conceallevel" }
					)
					:map("<leader>uc")
				Snacks.toggle.treesitter({ name = "[UI] Treesitter" }):map("<leader>uT")
				Snacks.toggle
					.option("background", { off = "light", on = "dark", name = "[UI] Dark Background" })
					:map("<leader>ub")
				Snacks.toggle.inlay_hints({ name = "[UI] Inlay Hints" }):map("<leader>uh")
				Snacks.toggle.indent({ name = "[UI] Indent" }):map("<leader>ug")
				Snacks.toggle.dim({ name = "[UI] Dim" }):map("<leader>uD")
			end,
		})
	end,
}
