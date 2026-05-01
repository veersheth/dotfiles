vim.pack.add({ "https://github.com/stevearc/oil.nvim" })
vim.pack.add({ "https://github.com/nvim-tree/nvim-web-devicons" })

vim.keymap.set({ "n" }, "<leader>/", "<cmd>Oil<CR>", { desc = "open oil" })
vim.keymap.set({ "n" }, "<leader>e", "<cmd>Oil --float<CR>", { desc = "open oil" })

require "oil" .setup({
  view_options = {
    show_hidden = true
  },
	lsp_file_methods = {
		enabled = true,
		timeout_ms = 1000,
		autosave_changes = true,
	},
	columns = {
		"icon",
	},
	float = {
		max_width = 0.3,
		max_height = 0.6,
		border = "rounded",
	},
  skip_confirm_for_simple_edits = true,
  delete_to_trash = true,
  keymaps = { ["<Esc>"] = "actions.close" },
})


