return {
    "vague2k/vague.nvim",
    config = function()
        require("vague").setup({ transparent = true })
        vim.cmd("colorscheme vague")
        vim.cmd("hi Normal guibg=#111111")  
    end
}


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

-- return {
-- 	"catppuccin/nvim",
-- 	name = "catppuccin",
-- 	priority = 1000,
-- 	config = function()
-- 		require("catppuccin").setup({
-- 			flavour = "mocha",
-- 			color_overrides = {
-- 				all = {
-- 					text = "#ffffff",
-- 				},
-- 				mocha = {
-- 					base = "#080808",
-- 					mantle = "#0f0f0f",
-- 					crust = "#080808",
-- 				},
--         latte = {},
-- 				frappe = {},
-- 				macchiato = {},
-- 			},
-- 		})
--
-- 		vim.cmd.colorscheme("catppuccin")
-- 	end,
-- }
