-- return {}

-- return { "ellisonleao/gruvbox.nvim", priority = 1000,
-- 	config = function()
-- 		vim.cmd.colorscheme "gruvbox"
-- 	end
-- }

-- return {
--   "folke/tokyonight.nvim",
--   lazy = false,
--   priority = 1000,
--   config = function()
--     vim.cmd.colorscheme("tokyonight-night")
--   end,
-- }

return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			color_overrides = {
				all = {
					text = "#ffffff",
				},
				mocha = {
					base = "#181818",
					mantle = "#000000",
					crust = "#181818",
				},
        latte = {},
				frappe = {},
				macchiato = {},
			},
		})

		vim.cmd.colorscheme("catppuccin")
	end,
}
