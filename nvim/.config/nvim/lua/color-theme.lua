
vim.pack.add({ 'https://github.com/vague-theme/vague.nvim' })
require('vague').setup({
  transparent = true,
  colors = {
    line = '#2f2f2f',
  },
})
vim.cmd.colorscheme('vague')


-- vim.pack.add({
--   "https://github.com/ellisonleao/gruvbox.nvim"
-- })
-- require("gruvbox").setup()
-- vim.cmd.colorscheme("gruvbox")


vim.api.nvim_set_hl(0, "Visual", {
    bg = "#ffffff",
    fg = "#000000",
})
