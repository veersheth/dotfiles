return {
	"kylechui/nvim-surround",
	version = "*", -- Use the latest stable version
	config = function()
		require("nvim-surround").setup({
			keymaps = {
				normal = "<leader>sw", -- Surround word in normal mode
				visual = "<leader>sw", -- Surround selection in visual mode
				delete = "<leader>sd", -- Delete surrounding
				change = "<leader>sc", -- Change surrounding
			},
		})
	end,
}


