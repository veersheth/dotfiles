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
		vim.keymap.set("n", "<leader>e", ":Neotree float<CR>", { desc = "Toggle floating neotree" })

		buffers = { follow_current_file = { enabled = true } }

		require("neo-tree").setup({
			window = {
				width = 28,
			},
		})
	end,
}

