-- Blink.cmp - Performant completion plugin
-- IDE-like completion with snippets, ghost text, and signature help

return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		event = "InsertEnter",
		dependencies = {
			"rafamadriz/friendly-snippets",
			"folke/lazydev.nvim",
		},

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- Keymap: Ctrl+y to accept, Enter for newline
			keymap = {
				preset = "none",
				["<C-y>"] = { "accept", "fallback" },
				["<CR>"] = { "fallback" },
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				["<C-Space>"] = { "accept", "show", "fallback" },
				["<C-e>"] = { "hide", "fallback" },
				["<C-d>"] = { "scroll_documentation_down", "fallback" },
				["<C-u>"] = { "scroll_documentation_up", "fallback" },
				["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
			},

			appearance = {
				nerd_font_variant = "mono",
			},

			-- Completion settings
			completion = {
				-- Auto-show documentation
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
					window = {
						border = "rounded",
					},
				},
				-- Ghost text preview (IDE-like inline preview)
				ghost_text = {
					enabled = true,
					show_with_selection = true,
					show_without_selection = false,
					show_with_menu = true,
					show_without_menu = true,
				},
				-- Completion menu
				menu = {
					border = "rounded",
					draw = {
						columns = {
							{ "kind_icon" },
							{ "label", "label_description", gap = 1 },
							{ "source_name" },
						},
					},
				},
				-- Accept behavior
				accept = {
					auto_brackets = { enabled = true },
				},
			},

			-- Signature help (shows function parameters)
			signature = {
				enabled = true,
				trigger = {
					enabled = true,
					show_on_trigger_character = true,
					show_on_insert_on_trigger_character = true,
				},
				window = {
					border = "rounded",
					treesitter_highlighting = true,
					show_documentation = true,
				},
			},

			-- Snippet navigation (IDE-like variable jumping)
			snippets = {
				preset = "default",
			},

			-- Sources
			sources = {
				default = { "lazydev", "lsp", "path", "snippets", "buffer" },
				providers = {
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						score_offset = 100,
					},
				},
			},

			-- Fuzzy matching
			fuzzy = {
				implementation = "prefer_rust_with_warning",
			},
		},
		opts_extend = { "sources.default" },
	},
}
