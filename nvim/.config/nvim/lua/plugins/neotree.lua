return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		vim.keymap.set("n", "<leader>-", ":Neotree right<CR>", { desc = "Open filetree" })
		vim.keymap.set("n", "<leader>_", ":Neotree toggle right<CR>", { desc = "Toggle filetree" })
		vim.keymap.set("n", "-", ":Neotree float<CR>", { desc = "Toggle floating neotree" })
		require("neo-tree").setup({
			window = {
				width = 28,
			},
		})
	end,
}
