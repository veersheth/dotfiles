return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("telescope").setup({
			defaults = {
				preview = { treesitter = false },
				color_devicons = true,
				sorting_strategy = "ascending",
				path_displays = { "smart" },
				layout_config = {
					height = 600,
					width = 600,
					prompt_position = "top",
					preview_cutoff = 40,
				},
			},
		})

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "find files" })
		vim.keymap.set("n", "<leader>s", builtin.live_grep, { desc = "find strings" })
	end,
}
