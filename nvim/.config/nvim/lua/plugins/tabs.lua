return {
	"nvim-mini/mini.tabline",
	version = false,
	config = function()
		require("mini.tabline").setup({
			show_icons = true,
			format = nil,
			tabpage_section = "left",
		})
	end,
}
