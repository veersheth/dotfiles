return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({})
		vim.keymap.set("n", "<leader>`", ":ToggleTerm direction='float'<CR>", {desc="Togggle floating terminal"})
	end,
}
