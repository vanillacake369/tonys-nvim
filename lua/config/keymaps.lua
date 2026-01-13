local M = {}

M.definitions = {
	lsp = {
		name = "+LSP",
		prefix = nil, -- no prefix (gd, gr, etc.)
		{
			"gd",
			function()
				Snacks.picker.lsp_definitions()
			end,
			desc = "Jump to Definition",
		},
		{
			"gr",
			function()
				Snacks.picker.lsp_references()
			end,
			desc = "Show References",
		},
		{
			"gi",
			function()
				Snacks.picker.lsp_implementations()
			end,
			desc = "Jump to Implementation",
		},
		{ "K", vim.lsp.buf.hover, desc = "Show Documentation" },
		{
			"<leader>ca",
			function()
				require("tiny-code-action").code_action()
			end,
			desc = "Show Code Actions",
			mode = { "n", "v" },
		},
		{
			"<leader>cs",
			function()
				Snacks.picker.lsp_symbols()
			end,
			desc = "Show Document Symbols",
		},
		{
			"<leader>cS",
			function()
				Snacks.picker.lsp_workspace_symbols()
			end,
			desc = "Show Workspace Symbols",
		},
		{ "<leader>crn", vim.lsp.buf.rename, desc = "Rename Symbol" },
	},

	code = {
		name = "+Code",
		prefix = "<leader>c",
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			desc = "Format Code",
			mode = { "n", "v" },
		},
	},

	diagnostics = {
		name = "+Diagnostics",
		prefix = "<leader>d",
		{ "<leader>dd", "<cmd>Trouble diagnostics toggle<cr>", desc = "Show All Diagnostics" },
		{ "<leader>db", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Show Buffer Diagnostics" },
		{ "<leader>ds", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Show Symbols" },
		{ "<leader>dl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "Show LSP References" },
		{ "<leader>dL", "<cmd>Trouble loclist toggle<cr>", desc = "Show Location List" },
		{ "<leader>dq", "<cmd>Trouble qflist toggle<cr>", desc = "Show Quickfix List" },
	},

	buffer = {
		name = "+Buffer",
		prefix = "<leader>b",
		{
			"<leader>bdc",
			function()
				Snacks.bufdelete()
			end,
			desc = "Delete Current Buffer",
		},
		{
			"<leader>bda",
			function()
				Snacks.bufdelete.all()
			end,
			desc = "Delete All Buffers",
		},
		{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin Buffer" },
		{ "<leader>bdP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
		{ "<leader>bdr", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to Right" },
		{ "<leader>bdl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to Left" },
		{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous Buffer" },
		{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
		{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous Buffer" },
		{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
		{ "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move Buffer Left" },
		{ "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move Buffer Right" },
	},

	find = {
		name = "+Find",
		prefix = "<leader>f",
		{
			"<leader><space>",
			function()
				Snacks.picker.smart()
			end,
			desc = "Smart Find Files",
		},
		{
			"<leader>:",
			function()
				Snacks.picker.command_history()
			end,
			desc = "Command History",
		},
		{
			"<leader>e",
			function()
				Snacks.explorer()
			end,
			desc = "Explorer (Project Root)",
		},
		{
			"<leader>E",
			function()
				local buf_path = vim.fn.expand("%:p:h")
				Snacks.explorer({ cwd = buf_path })
			end,
			desc = "Explorer (Buffer Dir)",
		},
		{
			"<leader>ff",
			function()
				Snacks.picker.files()
			end,
			desc = "Find Files",
		},
		{
			"<leader>fb",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Find Buffers",
		},
		{
			"<leader>fg",
			function()
				Snacks.picker.grep()
			end,
			desc = "Grep in Files",
		},
		{
			"<leader>fr",
			function()
				Snacks.picker.recent()
			end,
			desc = "Find Recent Files",
		},
		{
			"<leader>fc",
			function()
				Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "Find Config Files",
		},
	},

	window = {
		name = "+Window",
		prefix = "<leader>w",
		{ "<leader>w-", "<C-w>s", desc = "Split Below" },
		{ "<leader>w|", "<C-w>v", desc = "Split Right" },
		{ "<leader>wq", "<C-w>q", desc = "Close Window" },
		{ "<leader>wh", "<C-w>h", desc = "Go to Left Window" },
		{ "<leader>wj", "<C-w>j", desc = "Go to Down Window" },
		{ "<leader>wk", "<C-w>k", desc = "Go to Up Window" },
		{ "<leader>wl", "<C-w>l", desc = "Go to Right Window" },
		{ "<leader>w=", "<C-w>=", desc = "Equal Size Windows" },
	},

	align = {
		name = "+Align",
		prefix = "<leader>a",
		{ "<leader>a", "<Plug>(EasyAlign)", desc = "Align Text", mode = { "n", "x" } },
	},

	terminal = {
		{
			"<C-_>",
			function()
				Snacks.terminal()
			end,
			desc = "Toggle Terminal",
			mode = { "n", "t" },
		},
	},

	comment = {
		{ "gc", desc = "Comment toggle linewise", mode = { "n", "v" } },
		{ "gb", desc = "Comment toggle blockwise", mode = { "n", "v" } },
	},

	which_key = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},

	move = {
		name = "+Move Lines",
		{
			"J",
			":m '>+1<CR>gv=gv",
			desc = "Move Selection Down",
			mode = "v",
		},
		{
			"K",
			":m '<-2<CR>gv=gv",
			desc = "Move Selection Up",
			mode = "v",
		},
	},
}

-- Convert to Lazy.nvim keys format
function M.get_keys(group_name)
	local keys = {}
	local group = M.definitions[group_name]
	if not group then
		return keys
	end

	for _, item in ipairs(group) do
		-- Skip metadata fields
		if type(item) == "table" and item[1] then
			table.insert(keys, {
				item[1],
				item[2],
				desc = item.desc,
				mode = item.mode or "n",
			})
		end
	end
	return keys
end

-- Apply keymaps directly using vim.keymap.set (for LSP, etc.)
function M.apply_keymaps(group_name, opts)
	local group = M.definitions[group_name]
	if not group then
		return
	end

	for _, item in ipairs(group) do
		-- Skip metadata fields
		if type(item) == "table" and item[1] then
			local key_opts = vim.tbl_extend("force", opts or {}, {
				desc = item.desc,
			})
			local mode = item.mode or "n"
			vim.keymap.set(mode, item[1], item[2], key_opts)
		end
	end
end

-- Generate Which-key spec automatically
function M.get_which_key_spec()
	local spec = {}
	for _, group in pairs(M.definitions) do
		if group.prefix and group.name then
			table.insert(spec, {
				group.prefix,
				group = group.name,
			})
		end
	end
	return spec
end

return M
