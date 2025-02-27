return {
	{
		"nvim-telescope/telescope-ui-select.nvim",
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("telescope").setup({
				defaults = {
					theme = "center",
					sorting_strategy = "ascending",
					layout_config = {
						horizontal = {
							prompt_position = "top",
							preview_width = 0.3,
						},
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Find Files" })
			vim.keymap.set("n", "<leader>fd", builtin.find_files, { desc = "Find Files" })
			vim.keymap.set("n", "<leader>fs", builtin.find_files, { desc = "Find Document Symbols" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Find Grep" })
			vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Find Old Files" })

			require("telescope").load_extension("ui-select")
		end,
	},
}
