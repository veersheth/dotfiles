return {
	"kylechui/nvim-surround",
	version = "*", -- Use the latest stable version
	config = function()
		require("nvim-surround").setup({
			keymaps = {
				normal = "sw", -- Surround word in normal mode
				visual = "sw", -- Surround selection in visual mode
				delete = "sd", -- Delete surrounding
				change = "sc", -- Change surrounding
			},
		})
	end,
}


