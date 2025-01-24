-- is the status bar at the bottom of the screen
return {
	"nvim-lualine/lualine.nvim",
	config = function()
		require("lualine").setup()
	end,
}
