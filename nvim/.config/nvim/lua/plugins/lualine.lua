return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local colors = {
			base = "#202020",
			surface = "#1f1d2e",
			overlay = "#26233a",
			muted = "#6e6a86",
			subtle = "#908caa",
			text = "#e0def4",
			love = "#eb6f92",
			gold = "#f6c177",
			rose = "#ebbcba",
			pine = "#31748f",
			foam = "#9ccfd8",
			iris = "#c4a7e7",
		}

		local custom_rose_pine = {
			normal = {
				a = { fg = colors.iris, bg = colors.overlay, gui = "bold" },
				b = { fg = colors.iris, bg = colors.base },
				c = { fg = colors.subtle, bg = colors.base },
			},
			insert = {
				a = { fg = colors.foam, bg = colors.overlay, gui = "bold" },
				b = { fg = colors.foam, bg = colors.base },
			},
			visual = {
				a = { fg = colors.rose, bg = colors.overlay, gui = "bold" },
				b = { fg = colors.rose, bg = colors.base },
			},
			replace = {
				a = { fg = colors.pine, bg = colors.overlay, gui = "bold" },
				b = { fg = colors.pine, bg = colors.base },
			},
			command = {
				a = { fg = colors.love, bg = colors.overlay, gui = "bold" },
				b = { fg = colors.love, bg = colors.base },
			},
			inactive = {
				a = { fg = colors.muted, bg = colors.overlay },
				b = { fg = colors.muted, bg = colors.base },
				c = { fg = colors.muted, bg = colors.base },
			},
		}

		require("lualine").setup({
			options = {
				theme = custom_rose_pine,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				globalstatus = true,
			},
			sections = {
				lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
				lualine_z = { { "location", separator = { right = "" }, left_padding = 2 } },
			},
		})
	end,
}
