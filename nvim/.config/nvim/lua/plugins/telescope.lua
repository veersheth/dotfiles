return {
	{
		"nvim-telescope/telescope-ui-select.nvim",
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")
			local themes = require("telescope.themes")

			telescope.setup({
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
						themes.get_dropdown({}),
					},
				},
			})

			-- Keymaps
			vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Find Files (C-p)" })
			vim.keymap.set("n", "<leader>fd", builtin.find_files, { desc = "Find Files" })
			vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Find Symbols (Document)" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Find by Grep" })
			vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Find Old Files" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find Help Tags" })
			vim.keymap.set("n", "<leader>ft", function()
				builtin.colorscheme({ enable_preview = true })
			end, { desc = "Find Themes (Colorschemes)" })

			telescope.load_extension("ui-select")
		end,
	},
}
